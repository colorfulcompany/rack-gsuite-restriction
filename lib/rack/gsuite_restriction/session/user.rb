require_relative './base'

module Rack
  class GSuiteRestriction
    class Session
      class User < Base
        KEY = "#{KEY_BASE}.user".freeze

        # 
        # @param [Rack::Request] request
        # @param [Array] domains
        # 
        def initialize(request, domains)
          super(request)
          @domains = domains
        end
        attr_reader :domains

        # 
        # @param [Object] user
        # @return [Object] or nil
        # 
        def create(user)
          if valid?(user)
            session[KEY] = user.info.email
          end
        end

        # 
        # @return [Object] or nil
        # 
        def find
          session[KEY]
        end

        # 
        # @param [Object] user
        # @return [Boolean]
        # 
        def valid?(user)
          domains.include?(user.info.email.split('@')[1])
        end
      end
    end
  end
end
