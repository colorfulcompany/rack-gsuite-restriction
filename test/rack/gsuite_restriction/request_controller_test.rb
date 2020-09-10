require "test_helper"

describe Rack::GSuiteRestriction::RequestController do
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }
  let(:domain) { 'test.com' }
  let(:user) { Hashie::Mash.new({ info: {email: "foo@#{domain}"}}) }
  let(:invalid_user) { Hashie::Mash.new({ info: {email: "foo@bar.com"}}) }

  def oauth_client
    Rack::GSuiteRestriction::OAuthClient.new(app, {
      :client_id => 'foo',
      :client_secret => 'bar',
    })
  end

  def controller(cllient = oauth_client)
    Rack::GSuiteRestriction::RequestController.new(cllient)
  end

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

  def response
    res = Rack::Response.new
    res.status = 401
    res
  end

  def create_user(req)
    (Rack::GSuiteRestriction::Session::User.new(req, domain)).create(user)
  end

  def set_location(req, url)
    (Rack::GSuiteRestriction::Session::Location.new(req)).store(url)
  end

  describe '#build' do
    describe 'request path is not oauth request path' do
      describe 'user is not authenticated' do
        it {
          assert {
            status, header, body = controller.build(request('/'), response)
            status == 301
          }
        }
      end
      describe 'user is authenticated' do
        before {
          @req = request('/')
          create_user(@req)
        }
        it {
          assert {
            status, header, body = controller.build(@req, response)
            [status, body] == [200, :pass]
          }
        }
      end
    end

    describe 'request path is oauth request path' do
      before {
        @client = oauth_client
      }
      it 'return redirect' do
        status, header, body = controller(@client).build(request(@client.request_path), response)
        assert {
          status == 302
        }
      end
    end

    describe 'request path is oauth callback path' do
      before {
        @client = oauth_client
        @req = request(@client.callback_path)
        set_location(@req, '/foo')
        @controller = controller(@client)
      }
      it 'invalid user' do
        @client.stub(:call, nil) do
          @req.env['omniauth.auth'] = invalid_user
          status, header, body = @controller.build(@req, response)
          assert {
            status == 401
          }
        end
      end
      it 'valid user redirect to location path' do
        @client.stub(:call, nil) do
          @controller.stub(:create_user_session, Rack::GSuiteRestriction::Session::User.new(@req, domain)) do

            @req.env['omniauth.auth'] = user
            status, header, body = @controller.build(@req, response)
            assert {
              status == 301
            }
          end
        end
      end
    end
  end
end