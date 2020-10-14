require "test_helper"

describe Rack::GSuiteRestriction::Session::User do
  let(:app) { lambda {|env| [200, {}, [TEST_APP_MESSAGE]]} }
  let(:domains) { ['example.com'] }

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

  def invalid_user
    Hashie::Mash.new({
      info: {
        email: 'foo@bar.com'
      }
    })
  end

  def valid_user
    Hashie::Mash.new({
      info: {
        email: "foo@#{domains.first}"
      }
    })
  end

  describe '#create' do
    before {
      @user_session = Rack::GSuiteRestriction::Session::User.new(request('/'), domains)
    }
    describe 'invalid user' do
      it {
        assert {
          @user_session.create(invalid_user) == nil
        }
      }
    end
    describe 'valid user' do
      it {
        assert {
          @user_session.create(valid_user) == valid_user.info.email
        }
      }
    end
  end

  describe '#find' do
    before {
      @user_session = Rack::GSuiteRestriction::Session::User.new(request('/'), domains)
    }
    describe 'user is empty' do
      it {
        assert {
          @user_session.find == nil
        }
      }
    end
    describe 'user found' do
      before {
        @user_session.create(valid_user)
      }
      it {
        assert {
          @user_session.find == valid_user.info.email
        }
      }
    end
  end

  describe '#valid?' do
    before {
      @user_session = Rack::GSuiteRestriction::Session::User.new(request('/'), domains)
    }
    it 'invalid user' do
      assert {
        @user_session.valid?(invalid_user) == false
      }
    end
    it 'valid user' do
      assert {
        @user_session.valid?(valid_user) == true
      }
    end
  end

  describe 'mulutiple permit domains' do
    def another_valid_user
      Hashie::Mash.new({
        info: {
          email: "foo@bar.example.com"
        }
      })
    end
  
    before {
      @user_session = Rack::GSuiteRestriction::Session::User.new(request('/'), domains.push('bar.example.com'))
    }
    it 'bar.example.com' do
      assert {
        @user_session.valid?(another_valid_user) == true
      }
    end

    it 'valid user' do
      @user_session.valid?(valid_user) == true
    end
  end
end
