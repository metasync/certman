# auto_register: false
# frozen_string_literal: true

require 'hanami/action'
require 'rom'

module Certbin
  class Action < Hanami::Action
    include Deps['operations.authorize_access']

    handle_exception ROM::TupleCountMismatchError => :handle_record_not_found

    before :authorize
    before :validate_params

    def handle(request, response)
      result = handle_request(request)
      if result[:error]
        on_error(result, response)
      else
        on_success(result, response)
      end
    end

    def authorization_required? = true

    protected

    def authorize(request, _response)
      return unless authorization_required?

      auth = authorize_access.call(request)
      return unless auth.failure?

      halt :unauthorized, { error: auth.failure }.to_json
    end

    def validate_params(request, _response)
      return if request.params.valid?

      # Return http status 422
      halt :unprocessable_entity,
           request.params.errors.to_json
    end

    def handle_record_not_found(_request, response, _exception)
      response.status = :not_found
      response.body = { error: 'Certificate is NOT found.' }.to_json
    end

    def handle_request(request)
      raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
    end

    # Return http status 422
    def error_status(_result) = :unprocessable_entity

    def error_body(result) = result[:error].to_json

    def on_error(result, response)
      response.status = error_status(result)
      response.body = error_body(result)
    end

    # Return http status 200
    def success_status(_result) = :ok

    def success_body(result) = result[:certificate].to_h.to_json

    def on_success(result, response)
      response.status = success_status(result)
      response.body = success_body(result)
    end
  end
end
