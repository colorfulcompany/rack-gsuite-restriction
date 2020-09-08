# :reek:disb

require "test_helper"

describe Rack::GSuiteRestriction do
  TEST_APP_MESSAGE = 'Hello, from App defined in Test !'
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }

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
  def restrict(args, &block)
    if block_given?
      Rack::GSuiteRestriction.new(app, args, config) {|req, res, match| block.call(req, res, match) }
    else
      Rack::GSuiteRestriction.new(app, args, config)
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
    before {
      @request = request('/')
    }
    describe 'block given' do
      before {
        @restrict = restrict('/') do |req, res|
          res.status = 401
          'block given'
        end
      }
      it 'block called' do
        @restrict.controller.stub(:build_response, @restrict.path_segment.call(@request)) do
          assert {
            status, header, body = @restrict.call(@request)
            body == ['block given']
          }
        end
      end
    end

    describe 'no block' do
      before {
        @restrict = restrict('/')
      }
      it 'return default response' do
        @restrict.controller.stub(:build_response, @restrict.path_segment.call(@request)) do
          assert {
            [401, {'Content-Length' => '0'}, ['']] == @restrict.call(@request)
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
        @restrict.controller.stub(:build_response, @restrict.path_segment.call(@request)) do
          status, headers, body = @restrict.call(@request)
          assert {
            status == 401
          }
        end
      }
    end

    describe 'under /admin' do
      let(:middleware) { restrict(/^\/admin.*/) }

      describe '/' do
        before {
          @request = request('/')
          @restrict = middleware
        }
        it 'auth not required' do
          @restrict.controller.stub(:build_response, @restrict.path_segment.call(@request)) do
            status, headers, body = @restrict.call(request('/'))
            assert {
              [status, body] == [200, [TEST_APP_MESSAGE]]
            }
          end
        end
      end

      describe '/admin/user' do
        before {
          @request = request('/admin/user')
          @restrict = middleware
        }
        it {
          @restrict.controller.stub(:build_response, @restrict.path_segment.call(@request)) do
            status, headers, body = @restrict.call(@request)
            assert {
              status == 401
            }
          end
        }
      end
    end
  end
end
