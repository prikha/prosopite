require_relative './prosopite/version'
require_relative './prosopite/query'
require_relative './prosopite/runner'

module Prosopite
  module_function def scan(whitelist: [], &block)
    Runner.new(whitelist: whitelist).scan(&block)
  end
end
