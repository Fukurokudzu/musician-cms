class ErrorsController < ApplicationController
  # Rendered via config.exceptions_app for any exception Rails maps to 404
  # (routing misses, ActiveRecord::RecordNotFound from the public lookups).
  def not_found
    render status: :not_found
  end

  # Rendered via config.exceptions_app for any exception Rails maps to 500.
  def internal_error
    render status: :internal_server_error
  end
end
