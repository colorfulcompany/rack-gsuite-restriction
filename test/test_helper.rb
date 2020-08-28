$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rack/gsuite_restriction"

require "pry-byebug"
require "rack/test"
require "minitest/reporters"
require "minitest-power_assert"
require "minitest/autorun"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
