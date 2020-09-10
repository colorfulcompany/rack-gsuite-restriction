require 'omniauth'
require 'omniauth-google-oauth2'

module Rack
  class GSuiteRestriction
    class OAuthClient
      OMNIAUTH_PATH_PREFIX = '/admin/auth'

      # 
      # @param [Object] app
      # @param [Hash] config
      # 
      def initialize(app, config)
        id = config.delete(:client_id)
        secret = config.delete(:client_secret)
        path_prefix = config.delete(:omniauth_path_prefix) || OMNIAUTH_PATH_PREFIX

        if !id || !secret
          raise ArgumentError.new('Rack::GSuiteRestriction::AuthClient need params: :client_id & :client_secret')
        end

        @client = OmniAuth::Builder.new(app) do
          configure { |config|
            config.path_prefix = path_prefix
          }
          provider :google_oauth2,
          id,
          secret,
          access_type: 'offline'
        end
      end
      attr_reader :client

      def call(env)
        client.call(env)
      end

      # 
      # @return [String]
      # 
      def request_path
        client.to_app.request_path
      end

      # 
      # @return [String]
      # 
      def callback_path
        client.to_app.callback_path
      end
    end
  end
end
