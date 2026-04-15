class OauthController < ActionController::Base
  skip_forgery_protection

  # GET /.well-known/oauth-authorization-server
  def metadata
    render json: {
      issuer: root_url,
      authorization_endpoint: "#{root_url}oauth/authorize",
      token_endpoint: "#{root_url}oauth/token",
      registration_endpoint: "#{root_url}oauth/register",
      response_types_supported: [ "code" ],
      grant_types_supported: [ "authorization_code" ],
      code_challenge_methods_supported: [ "S256" ],
      token_endpoint_auth_methods_supported: [ "none" ]
    }
  end

  # POST /oauth/register
  def register
    params.require(:redirect_uris)
    redirect_uris = Array(params[:redirect_uris])

    unless redirect_uris.all? { |uri| valid_redirect_uri?(uri) }
      return render json: { error: "invalid_redirect_uri" }, status: :bad_request
    end

    client_id = OauthStore.register_client(
      client_name: params[:client_name] || "unknown",
      redirect_uris: redirect_uris
    )

    render json: {
      client_id: client_id,
      client_name: params[:client_name],
      redirect_uris: redirect_uris,
      token_endpoint_auth_method: "none",
      grant_types: [ "authorization_code" ],
      response_types: [ "code" ]
    }, status: :created
  end

  # GET /oauth/authorize
  def authorize
    @error = validate_authorize_params
    @oauth_params = oauth_params_from_request
  end

  # POST /oauth/authorize
  def approve
    oauth = oauth_params_from_form

    error = validate_authorize_params_from(oauth)
    if error
      return render plain: error, status: :bad_request
    end

    unless valid_password?(params[:password])
      @error = "Invalid password"
      @oauth_params = oauth
      return render :authorize, status: :unauthorized
    end

    code = SecureRandom.hex(32)
    OauthStore.store_auth_code(code,
      client_id: oauth[:client_id],
      redirect_uri: oauth[:redirect_uri],
      code_challenge: oauth[:code_challenge],
      scope: oauth[:scope]
    )

    redirect_uri = URI.parse(oauth[:redirect_uri])
    query = URI.decode_www_form(redirect_uri.query || "")
    query << [ "code", code ]
    query << [ "state", oauth[:state] ] if oauth[:state].present?
    redirect_uri.query = URI.encode_www_form(query)

    redirect_to redirect_uri.to_s, allow_other_host: true
  end

  # POST /oauth/token
  def token
    unless params[:grant_type] == "authorization_code"
      return render json: { error: "unsupported_grant_type" }, status: :bad_request
    end

    auth_code = OauthStore.consume_auth_code(params[:code])
    unless auth_code
      return render json: { error: "invalid_grant", error_description: "Invalid or expired code" }, status: :bad_request
    end

    unless auth_code[:client_id] == params[:client_id]
      return render json: { error: "invalid_grant", error_description: "client_id mismatch" }, status: :bad_request
    end

    unless auth_code[:redirect_uri] == params[:redirect_uri]
      return render json: { error: "invalid_grant", error_description: "redirect_uri mismatch" }, status: :bad_request
    end

    unless valid_pkce?(params[:code_verifier], auth_code[:code_challenge])
      return render json: { error: "invalid_grant", error_description: "PKCE verification failed" }, status: :bad_request
    end

    expires_in = 3600
    access_token = generate_access_token(expires_at: expires_in.seconds.from_now)

    render json: {
      access_token: access_token,
      token_type: "Bearer",
      expires_in: expires_in
    }
  end

  private

  def oauth_params_from_request
    {
      client_id: params[:client_id],
      redirect_uri: params[:redirect_uri],
      state: params[:state],
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      scope: params[:scope],
      response_type: params[:response_type]
    }
  end

  def oauth_params_from_form
    {
      client_id: params[:client_id],
      redirect_uri: params[:redirect_uri],
      state: params[:state],
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      scope: params[:scope],
      response_type: params[:response_type]
    }
  end

  def validate_authorize_params
    validate_authorize_params_from(oauth_params_from_request)
  end

  def validate_authorize_params_from(oauth)
    return "Missing client_id" if oauth[:client_id].blank?
    return "Unknown client" unless OauthStore.find_client(oauth[:client_id])
    return "Missing redirect_uri" if oauth[:redirect_uri].blank?

    client = OauthStore.find_client(oauth[:client_id])
    unless client[:redirect_uris].include?(oauth[:redirect_uri])
      return "redirect_uri not registered"
    end

    return "response_type must be 'code'" unless oauth[:response_type] == "code"
    return "Missing code_challenge" if oauth[:code_challenge].blank?
    return "code_challenge_method must be S256" unless oauth[:code_challenge_method] == "S256"

    nil
  end

  def valid_redirect_uri?(uri)
    parsed = URI.parse(uri)
    parsed.scheme == "https" || parsed.host == "localhost" || parsed.host == "127.0.0.1"
  rescue URI::InvalidURIError
    false
  end

  def valid_password?(password)
    expected = ENV["ADMIN_PASSWORD"]
    expected.present? && ActiveSupport::SecurityUtils.secure_compare(password.to_s, expected)
  end

  def valid_pkce?(code_verifier, code_challenge)
    return false if code_verifier.blank? || code_challenge.blank?

    computed = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    ActiveSupport::SecurityUtils.secure_compare(computed, code_challenge)
  end

  def generate_access_token(expires_at:)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, digest: "SHA256")
    verifier.generate({ exp: expires_at.to_i }, purpose: "mcp_access_token")
  end

  def self.verify_access_token(token)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, digest: "SHA256")
    payload = verifier.verify(token, purpose: "mcp_access_token")
    return nil if payload["exp"] < Time.current.to_i
    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
