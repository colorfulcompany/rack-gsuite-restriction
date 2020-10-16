require_relative './oauth_client'
require_relative './session/user'
require_relative './session/location'

module Rack
  class GSuiteRestriction
    class RequestController
      PERMIT_DOMAINS = ['colorfulcompany.co.jp'].freeze

      #
      # @param [OAuthClient] oauth_client
      #
      def initialize(oauth_client, config)
        @oauth_client = oauth_client
        @domains = config[:oauth_permit_domains] || PERMIT_DOMAINS
      end
      attr_reader :oauth_client

      #
      # @param [Rack::Request] request
      # @param [Rack::Response] response
      # @return [Object]
      #
      def build(request, response)
        res = response.finish

        user_session = create_user_session(request, @domains)
        location = Session::Location.new(request)
  
        case request.path
  
        when oauth_client.request_path
          res = oauth_client.call(request.env)
  
        when oauth_client.callback_path
          oauth_client.call(request.env)
  
          if user_session.create(request.env['omniauth.auth'])
            res = redirect_to(location.restore)
          else
            res = forbidden
          end
  
        else
          # user is not authenticated.
          if user_session.find.nil?
            location.store(request.url)
            res = redirect_to(oauth_client.request_path)
  
          # user is authenticated.
          else
            res = is_authenticated
          end
        end

        res
      end

      # 
      # @param [String] path
      # @return [Object]
      # 
      def redirect_to(path)
        [302, { 'Location' => path }, []]
      end

      # 
      # @return [Object]
      # 
      def is_authenticated
        [200, {}, 'pass'.to_sym]
      end

      #
      # @return [Object]
      #
      def forbidden
        [403, {}, 'invalid user']
      end

      # 
      # @param [Rack::Request] req
      # @return [Session::User]
      # 
      def create_user_session(req, domeins)
        Session::User.new(req, domeins)
      end
    end
  end
end
