# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  class JwtExpiredError < StandardError; end
  class JwtDecodeError < StandardError; end
  class JwtVerificationError < StandardError; end

  included do
    # ActiveRecord errors
    rescue_from ActiveRecord::RecordNotFound do
      error!({ errors: { status: I18n.t("errors.status.not_found") } }, 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |exception|
      messages = exception.record.errors.full_messages
      error!({ errors: { status: I18n.t("errors.status.unprocessable_entity"), messages: } }, 422)
    end

    # Grape validation errors
    rescue_from Grape::Exceptions::ValidationErrors do |exception|
      error!({ errors: { status: I18n.t("errors.status.bad_request"), message: exception.message } }, 400)
    end

    # JWT-related errors
    rescue_from JwtExpiredError do
      error!({ errors: { status: I18n.t("errors.status.token_expired") } }, 401)
    end

    rescue_from JwtVerificationError do
      error!({ errors: { status: I18n.t("errors.status.token_verification_failed") } }, 401)
    end

    rescue_from JwtDecodeError do
      error!({ errors: { status: I18n.t("errors.status.token_decode_error") } }, 422)
    end

    # Catch-all for unexpected errors
    rescue_from :all do |e|
      Rollbar.error(e) if defined?(Rollbar)
      payload = { errors: { status: I18n.t("errors.status.internal_server_error") } }
      payload[:errors][:message] = e.message if Rails.env.development?
      error!(payload, 500)
    end
  end
end
