require_relative './base'

module Rack
  class GSuiteRestriction
    class Session
      class Location < Base
        KEY = "#{KEY_BASE}.location".freeze

        # 
        # @param [String] url
        # 
        def store(url)
          session[KEY] = url
        end

        # 
        # @return [String]
        # 
        def restore
          url = session[KEY]
          session[KEY] = nil
          url
        end
      end
    end
  end
end
