module Rack
  class GSuiteRestriction
    class Session
      class Base
        KEY_BASE = 'gsuite.restriction'.freeze
        # 
        # @param [Rack::Request] request
        # 
        def initialize(request)
          @request = request
        end
        attr_reader :request

        # 
        # @return [Object]
        # 
        def session
          request.env['rack.session']
        end
      end
    end
  end
end
