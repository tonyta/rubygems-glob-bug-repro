require "test_helper"

class Glob::Bug::ReproTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Glob::Bug::Repro::VERSION
  end
end
