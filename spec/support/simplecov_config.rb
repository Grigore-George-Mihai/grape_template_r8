# frozen_string_literal: true

require "simplecov"

SimpleCov.start "rails" do
  skip "/bin/"
  skip "/lib/generators/"
end
