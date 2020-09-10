# :reek:disb

require "test_helper"

describe Rack::GSuiteRestriction do
  TEST_APP_MESSAGE = 'Hello, from App defined in Test !'
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }
  let(:domain) { 'test.com' }
  let(:user) { Hashie::Mash.new({ info: {email: "foo@#{domain}"}}) }

  def config
    {
      :client_id => 'foo',
      :client_secret => 'bar',
    }
  end

  #
  # @param [Object] args
  # @return [Rack::GSuiteRestriction]
  #
  def restrict(args)
    Rack::GSuiteRestriction.new(app, args, config)
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
    env
  end

  def create_user(env)
    (Rack::GSuiteRestriction::Session::User.new(Rack::Request.new(env), domain)).create(user)
  end

  describe 'initialize' do
    before {
      @request = request('/')
    }
    describe 'no block' do
      describe 'user is not authenticated' do
        it 'return redirect' do
          assert {
            status, header, body = restrict('/').call(@request)
            status == 302
          }
        end
      end
      describe 'user is authenticated' do 
        before {
          create_user(@request)
        }
        it 'return app response' do
          assert {
            status, header, body = restrict('/').call(@request)
            [status, body] == [200, [TEST_APP_MESSAGE]]
          }
        end
      end
    end
  end

  describe 'specific path require auth ( with Regexp )' do
    describe 'whole' do
      before {
        @request = request('/')
        @restrict = restrict(/^\/.*/)
      }
      it {
        status, headers, body = @restrict.call(@request)
        assert {
          status == 302
        }
      }
    end

    describe 'under /admin' do
      let(:middleware) { restrict(/^\/admin.*/) }

      describe '/' do
        it 'auth not required' do
          status, headers, body = middleware.call(request('/'))
          assert {
            [status, body] == [200, [TEST_APP_MESSAGE]]
          }
        end
      end

      describe '/admin/user' do
        before {
          @request = request('/admin/user')
        }
        it 'user is not authenticated' do
          status, headers, body = middleware.call(@request)
          assert {
            status == 302
          }
        end
        it 'user is  authenticated' do
          create_user(@request)
          status, headers, body = middleware.call(@request)
          assert {
            status == 200
          }
        end
      end
    end
  end

  describe 'option omniauth path prefix' do
    describe 'not under need auth path' do
      before {
        c = config.merge(omniauth_path_prefix: '/foo')
        @restrict = Rack::GSuiteRestriction.new(app, /^\/admin.*/, c)
        @request = request('/admin')
      }
      it 'redirect to omniauth request path' do
        assert {
          status, header, body = @restrict.call(@request)
          status == 302
        }
      end
      it 'user is authenticated' do
        create_user(@request)
        assert {
          status, header, body = @restrict.call(@request)
          [status, body] == [200, [TEST_APP_MESSAGE]]
        }
      end
    end
  end
end
