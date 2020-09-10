require "test_helper"

describe Rack::GSuiteRestriction::Session::Base do
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }

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

  describe '#session' do
    describe 'session is empty ' do
      it {
        store = Rack::GSuiteRestriction::Session::Base.new(request('/'))
        assert {
          store.session.count == 0
        }
      }
    end
  end
end
