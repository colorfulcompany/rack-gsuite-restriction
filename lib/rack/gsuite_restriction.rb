require 'rack'
require 'rack/contrib'
require_relative './gsuite_restriction/request_controller'

module Rack
  class GSuiteRestriction
    class GSuiteRestrictionError < StandardError; end
    
    #
    # @param [Object] app
    # @param [String|Regexp] path
    # @param [Hash] config
    #
    def initialize(app, path, config = {})
      dumb_app = lambda {|env| [418, {}, ['not captured']]}
      @oauth_client = OAuthClient.new(app, config)
      auth_path = need_auth_path(path, @oauth_client)

      @path_segment = SimpleEndpoint.new(dumb_app, auth_path) {|req, res, match| need_auth(req, res, match) }
      @app = app
    end
    attr_reader :path_segment, :oauth_client

    #
    # @param [Object] env
    # @return [Array]
    #
    def call(env)
      res = @path_segment.call(env)

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

      status, header, body = (RequestController.new(oauth_client)).build(req, res)
      res.status = status
      header.keys.each { |k| res[k] = header[k] }

      body
    end

    # 
    # @param [String|Regexp] path
    # @param [Object] oauth_client
    # @return [Regexp]
    # 
    def need_auth_path(path, oauth_client)
      Regexp.union(path, oauth_client.request_path, oauth_client.callback_path)
    end
  end
end
