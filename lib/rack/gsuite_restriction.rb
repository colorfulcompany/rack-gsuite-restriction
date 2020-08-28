require 'rack'
require 'rack/contrib'

module Rack
  class GSuiteRestriction
    class GSuiteRestrictionError < StandardError; end
    
    #
    # @param [Object] app
    # @param [String|Regexp] path
    # @param [Proc] block
    #
    def initialize(app, path, &block)
      dumb_app = lambda {|env| [418, {}, ['not captured']]}
      @path_segment = if block_given?
                        SimpleEndpoint.new(dumb_app, path) {|req, res, match| block.call(req, res, match) }
                      else
                        SimpleEndpoint.new(dumb_app, path) {|req, res, match| need_auth(req, res, match) }
                      end
      @app = app
    end

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

      ''
    end
  end
end
