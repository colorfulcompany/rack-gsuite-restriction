# :reek:disb

require "test_helper"

describe Rack::GSuiteRestriction do
  TEST_APP_MESSAGE = 'Hello, from App defined in Test !'
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }

  #
  # @param [Object] args
  # @return [Rack::GSuiteRestriction]
  #
  def restrict(args, &block)
    if block_given?
      Rack::GSuiteRestriction.new(app, args) {|req, res, match| block.call(req, res, match) }
    else
      Rack::GSuiteRestriction.new(app, args)
    end
  end

  #
  # @param [String] uri
  # @param [Hash] opts
  # @return [Rack::MockRequest]
  #
  # :reek:UtilityFunction
  def request(uri, opts = {})
    Rack::MockRequest.env_for(uri, opts.merge(lint: true))
  end
  
  describe 'initialize' do
    describe 'block given' do
      it 'block called' do
        middleware = restrict('/') do |req, res|
          res.status = 401
          'block given'
        end
                             
        assert {
          status, header, body = middleware.call(request('/'))
          body == ['block given']
        }
      end
    end

    describe 'no block' do
      it 'return default response' do
        assert {
          [401, {'Content-Length' => '0'}, ['']] == restrict('/').call(request('/'))
        }
      end
    end
  end

  describe 'specific path require auth ( with Regexp )' do
    describe 'whole' do
      it {
        status, headers, body = restrict(/^\/.*/).call(request('/'))
        assert {
          status == 401
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
        it {
          status, headers, body = middleware.call(request('/admin/user'))
          assert {
            status == 401
          }
        }
      end
    end
  end
end
