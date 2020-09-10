require_relative './base'

module Rack
  class GSuiteRestriction
    class Session
      class User < Base
        KEY = "#{KEY_BASE}.user".freeze
        DOMAIN = 'colorfulcompany.co.jp'.freeze

        # 
        # @param [Rack::Request] request
        # @param [String] domain
        # 
        def initialize(request, domain = DOMAIN)
          super(request)
          @domain = domain
        end
        attr_reader :domain

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
          domain == user.info.email.split('@')[1]
        end
      end
    end
  end
end
