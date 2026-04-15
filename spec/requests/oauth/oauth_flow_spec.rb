require "rails_helper"

RSpec.describe "OAuth 2.1 flow", type: :request do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return("secret123")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ADMIN_PASSWORD").and_return("secret123")
    # Reset singleton store between tests
    OauthStore.instance_variable_set(:@instance, OauthStore.new)
  end

  describe "GET /.well-known/oauth-authorization-server" do
    it "returns OAuth metadata" do
      get "/.well-known/oauth-authorization-server"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["authorization_endpoint"]).to end_with("/oauth/authorize")
      expect(body["token_endpoint"]).to end_with("/oauth/token")
      expect(body["registration_endpoint"]).to end_with("/oauth/register")
      expect(body["response_types_supported"]).to eq([ "code" ])
      expect(body["code_challenge_methods_supported"]).to eq([ "S256" ])
    end
  end

  describe "POST /oauth/register" do
    it "registers a client with valid redirect_uris" do
      post "/oauth/register",
        params: { client_name: "my-app", redirect_uris: [ "http://localhost:8080/callback" ] }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["client_id"]).to be_present
      expect(body["client_name"]).to eq("my-app")
    end

    it "rejects non-HTTPS, non-localhost redirect_uris" do
      post "/oauth/register",
        params: { client_name: "evil", redirect_uris: [ "http://evil.com/callback" ] }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:bad_request)
    end

    it "accepts HTTPS redirect_uris" do
      post "/oauth/register",
        params: { client_name: "prod", redirect_uris: [ "https://app.example.com/callback" ] }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:created)
    end
  end

  describe "full OAuth flow with PKCE" do
    let(:code_verifier) { SecureRandom.urlsafe_base64(32) }
    let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }
    let(:redirect_uri) { "http://localhost:8080/callback" }

    let(:client_id) do
      post "/oauth/register",
        params: { client_name: "test", redirect_uris: [ redirect_uri ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      JSON.parse(response.body)["client_id"]
    end

    let(:authorize_params) do
      {
        client_id: client_id,
        redirect_uri: redirect_uri,
        code_challenge: code_challenge,
        code_challenge_method: "S256",
        response_type: "code",
        state: "xyzstate"
      }
    end

    describe "GET /oauth/authorize" do
      it "renders the authorization form" do
        get "/oauth/authorize", params: authorize_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("password")
        expect(response.body).to include(client_id)
      end

      it "shows error for unknown client" do
        get "/oauth/authorize", params: authorize_params.merge(client_id: "nonexistent")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Missing client_id").or include("Unknown client")
      end
    end

    describe "POST /oauth/authorize (approve)" do
      it "redirects with auth code on correct password" do
        post "/oauth/authorize", params: authorize_params.merge(password: "secret123")

        expect(response).to have_http_status(:redirect)
        location = URI.parse(response.location)
        query = URI.decode_www_form(location.query).to_h

        expect(location.host).to eq("localhost")
        expect(query["code"]).to be_present
        expect(query["state"]).to eq("xyzstate")
      end

      it "re-renders form on wrong password" do
        post "/oauth/authorize", params: authorize_params.merge(password: "wrong")

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Invalid password")
      end
    end

    describe "POST /oauth/token" do
      let(:auth_code) do
        post "/oauth/authorize", params: authorize_params.merge(password: "secret123")
        query = URI.decode_www_form(URI.parse(response.location).query).to_h
        query["code"]
      end

      it "exchanges auth code for access token" do
        code = auth_code

        post "/oauth/token", params: {
          grant_type: "authorization_code",
          code: code,
          client_id: client_id,
          redirect_uri: redirect_uri,
          code_verifier: code_verifier
        }

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["access_token"]).to be_present
        expect(body["token_type"]).to eq("Bearer")
        expect(body["expires_in"]).to eq(3600)
      end

      it "rejects reused auth code" do
        code = auth_code

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: client_id, redirect_uri: redirect_uri,
          code_verifier: code_verifier
        }
        expect(response).to have_http_status(:ok)

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: client_id, redirect_uri: redirect_uri,
          code_verifier: code_verifier
        }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
      end

      it "rejects wrong code_verifier (PKCE)" do
        code = auth_code

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: client_id, redirect_uri: redirect_uri,
          code_verifier: "wrong-verifier"
        }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error_description"]).to include("PKCE")
      end

      it "rejects mismatched client_id" do
        code = auth_code

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: "other-client", redirect_uri: redirect_uri,
          code_verifier: code_verifier
        }

        expect(response).to have_http_status(:bad_request)
      end

      it "rejects mismatched redirect_uri" do
        code = auth_code

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: client_id, redirect_uri: "http://localhost:9999/other",
          code_verifier: code_verifier
        }

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "access token on /mcp" do
      it "accepts valid OAuth token" do
        # Get token through full flow
        post "/oauth/authorize", params: authorize_params.merge(password: "secret123")
        code = URI.decode_www_form(URI.parse(response.location).query).to_h["code"]

        post "/oauth/token", params: {
          grant_type: "authorization_code", code: code,
          client_id: client_id, redirect_uri: redirect_uri,
          code_verifier: code_verifier
        }
        token = JSON.parse(response.body)["access_token"]

        post "/mcp",
          params: { jsonrpc: "2.0", method: "initialize", id: 1,
                    params: { protocolVersion: "2025-03-26", capabilities: {},
                              clientInfo: { name: "test", version: "1.0" } } }.to_json,
          headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }

        expect(response).not_to have_http_status(:unauthorized)
      end

      it "rejects plain password as Bearer token" do
        post "/mcp",
          params: { jsonrpc: "2.0", method: "initialize", id: 1,
                    params: { protocolVersion: "2025-03-26", capabilities: {},
                              clientInfo: { name: "test", version: "1.0" } } }.to_json,
          headers: { "Authorization" => "Bearer secret123", "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects expired OAuth token" do
        verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, digest: "SHA256")
        expired_token = verifier.generate({ exp: 1.hour.ago.to_i }, purpose: "mcp_access_token")

        post "/mcp",
          params: { jsonrpc: "2.0", method: "initialize", id: 1,
                    params: { protocolVersion: "2025-03-26", capabilities: {},
                              clientInfo: { name: "test", version: "1.0" } } }.to_json,
          headers: { "Authorization" => "Bearer #{expired_token}", "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects no token" do
        post "/mcp",
          params: { jsonrpc: "2.0", method: "initialize", id: 1,
                    params: { protocolVersion: "2025-03-26", capabilities: {},
                              clientInfo: { name: "test", version: "1.0" } } }.to_json,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
