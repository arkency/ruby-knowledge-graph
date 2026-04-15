class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :basic_auth, if: -> { Rails.env.production? }

  private

  def basic_auth
    authenticate_or_request_with_http_basic do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("ADMIN_USERNAME", "admin")) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("ADMIN_PASSWORD"))
    end
  end
end
