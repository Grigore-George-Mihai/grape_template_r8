require "sidekiq/web"
require "sidekiq-scheduler/web"

# Blank credentials (e.g. an unset var in .kamal/secrets) lock the dashboard instead of allowing an empty login.
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  expected_username, expected_password = ENV.values_at("SIDEKIQ_USERNAME", "SIDEKIQ_PASSWORD")
  next false if expected_username.blank? || expected_password.blank?

  ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &
    ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
end

Rails.application.routes.draw do
  mount ApiRoot => "/"
  mount GrapeSwaggerRails::Engine => "/swagger" if Rails.env.development?

  if Rails.env.development? || Rails.env.production?
    Sidekiq::Web.use ActionDispatch::Cookies
    Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: ENV.fetch("SIDEKIQ_SESSION_KEY", nil)

    mount Sidekiq::Web => "/sidekiq"
  end
end
