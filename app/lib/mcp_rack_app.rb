class McpRackApp
  def initialize
    server = McpServerConfig.build_server
    @transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
  end

  def call(env)
    request = Rack::Request.new(env)
    return unauthorized_response unless authenticated?(request)

    status, headers, body = @transport.handle_request(request)
    [ status, headers.dup, body ]
  end

  private

  def authenticated?(request)
    token = request.get_header("HTTP_AUTHORIZATION")&.delete_prefix("Bearer ")
    return false if token.blank?

    OauthController.verify_access_token(token).present?
  rescue
    false
  end

  def unauthorized_response
    [ 401, { "Content-Type" => "application/json" }, [ { error: "unauthorized" }.to_json ] ]
  end
end
