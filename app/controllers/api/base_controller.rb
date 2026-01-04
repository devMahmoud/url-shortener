# frozen_string_literal: true

module Api
  # Base controller for API endpoints.
  # Provides common functionality for all API controllers.
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    rescue_from StandardError do |e|
      render json: { error: e.message }, status: :internal_server_error
    end

    private

    def render_success(data, status: :ok)
      render json: data, status: status
    end

    def render_error(message, status: :unprocessable_entity)
      render json: { error: message }, status: status
    end

    def render_errors(messages, status: :unprocessable_entity)
      render json: { errors: Array(messages) }, status: status
    end
  end
end
