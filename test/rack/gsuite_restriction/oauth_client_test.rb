require "test_helper"

describe Rack::GSuiteRestriction::OAuthClient do
  TEST_APP_MESSAGE = 'Hello, from App defined in Test !'
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }

  def config
    {
      :client_id => 'test_id',
      :client_secret => 'test_secret'
    }
  end

  describe '#initialize' do
    describe 'config id is empty ' do
      it {
        assert_raises ArgumentError do
          Rack::GSuiteRestriction::OAuthClient.new(app, {
            :client_secret => 'test_secret'
          })
        end
      }
    end
    describe 'config secret is empty ' do
      it {
        assert_raises ArgumentError do
          Rack::GSuiteRestriction::OAuthClient.new(app, {
            :client_id => 'test_id'
          })
        end
      }
    end
  end

  describe '#request_path' do
    describe 'request path is default' do
      before {
        @client = Rack::GSuiteRestriction::OAuthClient.new(app, config)
      }
      it {
        assert {
          @client.request_path == '/admin/auth/google_oauth2'
        }
      }
    end
    describe 'request path is custom' do
      before {
        @client = Rack::GSuiteRestriction::OAuthClient.new(app, config.merge(:omniauth_path_prefix => '/foo/bar'))
      }
      it {
        assert {
          @client.request_path == '/foo/bar/google_oauth2'
        }
      }
    end
  end

  describe '#callback_path' do
    describe 'request path is default' do
      before {
        @client = Rack::GSuiteRestriction::OAuthClient.new(app, config)
      }
      it {
        assert {
          @client.callback_path == '/admin/auth/google_oauth2/callback'
        }
      }
    end
    describe 'request path is custom' do
      before {
        @client = Rack::GSuiteRestriction::OAuthClient.new(app, config.merge(:omniauth_path_prefix => '/foo/bar'))
      }
      it {
        assert {
          @client.callback_path == '/foo/bar/google_oauth2/callback'
        }
      }
    end
  end
end
