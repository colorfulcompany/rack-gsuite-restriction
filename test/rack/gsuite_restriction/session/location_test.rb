require "test_helper"

describe Rack::GSuiteRestriction::Session::Location do
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }
  let(:path) { '/path/to/test' }

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

  describe '#store' do
    it {
      location = Rack::GSuiteRestriction::Session::Location.new(request('/'))
      location.store(path)
      assert {
        location.session[location::class::KEY] == path
      }
    }
  end

  describe '#restore' do
    before {
      @location = Rack::GSuiteRestriction::Session::Location.new(request('/'))
      @location.store(path)
    }
    it 'get stored path' do
      assert {
        @location.restore == path
      }
    end
    it 'read one time only' do
      @location.restore
      assert {
        @location.session[@location::class::KEY] == nil
      }
    end
  end
end
