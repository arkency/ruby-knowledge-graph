require "rails_helper"

RSpec.describe OauthStore do
  include ActiveSupport::Testing::TimeHelpers

  subject(:store) { described_class.new }

  describe "#register_client / #find_client" do
    it "registers and retrieves a client" do
      client_id = store.register_client(client_name: "test", redirect_uris: [ "http://localhost/cb" ])

      client = store.find_client(client_id)
      expect(client[:client_name]).to eq("test")
      expect(client[:redirect_uris]).to eq([ "http://localhost/cb" ])
    end

    it "returns nil for unknown client" do
      expect(store.find_client("nonexistent")).to be_nil
    end
  end

  describe "#store_auth_code / #consume_auth_code" do
    it "stores and consumes an auth code (one-time use)" do
      store.store_auth_code("code123",
        client_id: "c1", redirect_uri: "http://localhost/cb",
        code_challenge: "challenge", scope: "read"
      )

      result = store.consume_auth_code("code123")
      expect(result[:client_id]).to eq("c1")
      expect(result[:code_challenge]).to eq("challenge")

      expect(store.consume_auth_code("code123")).to be_nil
    end

    it "expires codes after TTL" do
      store.store_auth_code("old_code",
        client_id: "c1", redirect_uri: "http://localhost/cb",
        code_challenge: "ch", scope: nil
      )

      travel_to 11.minutes.from_now do
        expect(store.consume_auth_code("old_code")).to be_nil
      end
    end
  end
end
