require 'rack'
require 'rack/contrib'
require_relative './gsuite_restriction/oauth_client'
require_relative './gsuite_restriction/request_controller'

module Rack
  class GSuiteRestriction
    class GSuiteRestrictionError < StandardError; end
    
    #
    # @param [Object] app
    # @param [String|Regexp] path
    # @param [Hash] config
    # @param [Proc] block
    #
    def initialize(app, path, config = {}, &block)
      dumb_app = lambda {|env| [418, {}, ['not captured']]}
      @path_segment = if block_given?
                        SimpleEndpoint.new(dumb_app, path) {|req, res, match| block.call(req, res, match) }
                      else
                        SimpleEndpoint.new(dumb_app, path) {|req, res, match| need_auth(req, res, match) }
                      end
      @controller = RequestController.new(
        app,
        OAuthClient.new(app, config))
      @app = app
    end
    attr_reader :path_segment, :controller

    #
    # @param [Object] env
    # @return [Array]
    #
    def call(env)
      res = @path_segment.call(env)
      req = Rack::Request.new(env)

      res = controller.build_response(req, res)

      return res[0] != 418 ? res : @app.call(env)
    end

    #
    # @param [Request] req
    # @param [Response] res
    # @return [Rack::Response]
    #
    # :reek:UtilityFunction :reek:UnusedParameters
    def need_auth(req, res, match = nil)
      res.status = 401

      ''
    end
  end
end
