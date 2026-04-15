class OauthStore
  class << self
    def instance
      @instance ||= new
    end

    delegate :register_client, :find_client,
             :store_auth_code, :consume_auth_code,
             to: :instance
  end

  def initialize
    @mutex = Mutex.new
    @clients = {}
    @auth_codes = {}
  end

  def register_client(client_name:, redirect_uris:)
    client_id = SecureRandom.hex(16)
    @mutex.synchronize do
      @clients[client_id] = { client_name: client_name, redirect_uris: redirect_uris }
    end
    client_id
  end

  def find_client(client_id)
    @mutex.synchronize { @clients[client_id] }
  end

  def store_auth_code(code, client_id:, redirect_uri:, code_challenge:, scope:)
    @mutex.synchronize do
      cleanup_expired_codes
      @auth_codes[code] = {
        client_id: client_id,
        redirect_uri: redirect_uri,
        code_challenge: code_challenge,
        scope: scope,
        expires_at: 10.minutes.from_now
      }
    end
  end

  def consume_auth_code(code)
    @mutex.synchronize do
      cleanup_expired_codes
      @auth_codes.delete(code)
    end
  end

  private

  def cleanup_expired_codes
    @auth_codes.reject! { |_, v| v[:expires_at] < Time.current }
  end
end
