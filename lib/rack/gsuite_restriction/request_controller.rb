require_relative './session/user'
require_relative './session/location'

module Rack
  class GSuiteRestriction
    class RequestController
      # 
      # @param [Object] app
      # @param [Object] oauth_client
      # 
      def initialize(app, oauth_client)
        @app = app
        @oauth_client = oauth_client
      end
      attr_reader :app, :oauth_client

      # 
      # @param [Object] request
      # @param [Object] response
      # @return [Boolean]
      # 
      def build_response(request, response)
        res = response

        user_session = create_user_session(request)
        location = create_location_session(request)

        if is_authenticated?(res, user_session.find)
          res = app.call(request.env)

        elsif need_auth?(res, user_session.find)
          case request.path
          when oauth_client.request_path
            res = oauth_client.call(request.env)

          when oauth_client.callback_path
            # get userInfo
            oauth_client.call(request.env)
            if user_session.create(request.env['omniauth.auth'])
              res = redirect_to(location.restore)
            end

          else
            location.store(request.url)
            res = redirect_to(oauth_client.request_path)
          end
        end

        res
      end

      # 
      # @param [Object] res
      # @param [Object] user
      # @return [Boolean]
      # 
      def need_auth?(res, user)
        res[0] == 401 && user.nil?
      end

      # 
      # @param [Object] res
      # @param [Object] user
      # @return [Boolean]
      # 
      def is_authenticated?(res, user)
        res[0] == 401 && !user.nil?
      end

      # 
      # @param [String] path
      # @return [Object]
      # 
      def redirect_to(path)
        [301, { 'Location' => path }, []]
      end

      # 
      # @param [Rack::Request] reqiest
      # @return [Session::User]
      # 
      def create_user_session(request)
        Session::User.new(request)
      end

      # 
      # @param [Rack::Request] reqiest
      # @return [Session::Location]
      # 
      def create_location_session(request)
        Session::Location.new(request)
      end
    end
  end
end

