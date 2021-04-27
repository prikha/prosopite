# frozen_string_literal: true

require_relative './prosopite/version'
require_relative './prosopite/query'
require_relative './prosopite/runner'

# Reliable N+1 detection based on sql fingerprinting
module Prosopite
  module_function

  def scan(whitelist: [], &block)
    Runner.new(whitelist: whitelist).scan(&block)
  end
end
