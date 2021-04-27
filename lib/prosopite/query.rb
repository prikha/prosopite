require_relative 'mysql_query'

module Prosopite
  module Query
    module_function def fingerprint(query)
      if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
        MysqlQuery.fingerprint(query)
      else
        begin
          require 'pg_query'
        rescue LoadError => e
          msg = "Could not load the 'pg_query' gem. Add `gem 'pg_query'` to your Gemfile"
          raise LoadError, msg, e.backtrace
        end

        begin
          PgQuery.fingerprint(query)
        rescue PgQuery::ParseError
          nil
        end
      end
    end
  end
end
