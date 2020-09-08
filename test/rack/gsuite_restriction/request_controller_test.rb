require "test_helper"

describe Rack::GSuiteRestriction::RequestController do
  TEST_APP_MESSAGE = 'Hello, from App defined in Test !'
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }
  let(:auth_client) { Rack::GSuiteRestriction::OAuthClient.new(app, {:client_id => 'foo', :client_secret => 'bar'})}
  let(:domain) { 'test.com' }
  let(:user) { Hashie::Mash.new({ info: {email: "foo@#{domain}"}}) }
  let(:invalid_user) { Hashie::Mash.new({ info: {email: "foo@bar.com"}}) }


  #
  # @param [String] uri
  # @param [Hash] opts
  # @return [Rack::MockRequest]
  #
  # :reek:UtilityFunction
  def request(uri, opts = {})
    env = Rack::MockRequest.env_for(uri, opts.merge(lint: true))
    session = Rack::Session::Cookie.new(app, {secret: 'test'})
    session.call(env)
    Rack::Request.new(env)
  end

  def unauthorized
    [401, {'Content-Length' => '0'}, ['']]
  end

  def ok
    [200, {'Content-Length' => '0'}, ['']]
  end

  describe '#build_response' do
    before {
      @auth_client = auth_client
      @controller = Rack::GSuiteRestriction::RequestController.new(app, @auth_client)
    }
    describe 'user is authenticated' do
      before {
        @request = request('/')
        user_session = Rack::GSuiteRestriction::Session::User.new(@request, domain)
        user_session.create(user)
      }
      it 'path segment is unauthorized' do
        assert {
          @controller.build_response(@request, unauthorized) == [200, {}, [TEST_APP_MESSAGE]]
        }
      end
      it 'path segment is ok' do
        assert {
          @controller.build_response(@request, ok) == ok
        }
      end
    end
    describe 'user is need auth' do
      describe 'request path is not auth request path' do
        before {
          @request = request('/')
        }
        it 'path segment is unauthorized' do
          status, header, body = @controller.build_response(@request, unauthorized)

          assert {
            status == 301 && header == {"Location"=>@auth_client.request_path}
          }
        end
        it 'path segment is ok' do
          status, header, body = @controller.build_response(@request, ok)

          assert {
            status == 200
          }
        end
      end
      describe 'request path is auth callback path' do
        describe 'user is invalid' do 
          before {
            @request = request(@auth_client.callback_path)
            @request.env['omniauth.auth'] = invalid_user
          }
          it {
            @auth_client.stub(:call, nil) do
              status, header, body = @controller.build_response(@request, unauthorized)
              assert {
                status == 401
              }
            end
          }
        end
        describe 'user is valid' do 
          before {
            @request = request(@auth_client.callback_path)
            @request.env['omniauth.auth'] = user
            @location_path = '/path/to/redirect'
            location = Rack::GSuiteRestriction::Session::Location.new(@request)
            location.store(@location_path)
          }
          it {
            @auth_client.stub(:call, nil) do
              @controller.stub(:create_user_session, Rack::GSuiteRestriction::Session::User.new(@request, domain)) do
                status, header, body = @controller.build_response(@request, unauthorized)
                assert {
                  status == 301 && header == {"Location"=>@location_path}
                }
              end
            end
          }
        end
      end
    end
  end

  describe '#need_auth?' do
    before {
      @controller = Rack::GSuiteRestriction::RequestController.new(app, auth_client)
    }
    it 'response is 200 ok' do
      assert {
        @controller.need_auth?(ok, user) == false
      }
    end
    it 'unauthorized && user is exist' do
      assert {
        @controller.need_auth?(unauthorized, user) == false
      } 
    end
    it 'unauthorized && user is nil' do
      assert {
        @controller.need_auth?(unauthorized, nil) == true
      } 
    end
  end

  describe '#is_authenticated?' do
    before {
      @controller = Rack::GSuiteRestriction::RequestController.new(app, auth_client)
    }
    it 'response is 200 ok' do
      assert {
        @controller.is_authenticated?(ok, user) == false
      }
    end
    it 'unauthorized && user is exist' do
      assert {
        @controller.is_authenticated?(unauthorized, user) == true
      } 
    end
    it 'unauthorized && user is nil' do
      assert {
        @controller.is_authenticated?(unauthorized, nil) == false
      } 
    end
  end
end
