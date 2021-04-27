# frozen_string_literal: true

module Prosopite
  # MySQL query fingerprinting
  # Many thanks to https://github.com/genkami/fluent-plugin-query-fingerprint/
  module MysqlQuery
    module_function

    def fingerprint(query) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      query = query.dup

      return 'mysqldump' if query =~ %r{\ASELECT /\*!40001 SQL_NO_CACHE \*/ \* FROM `}
      return 'percona-toolkit' if query =~ %r{\*\w+\.\w+:[0-9]/[0-9]\*/}
      if match = /\A\s*(call\s+\S+)\(/i.match(query)
        return match.captures.first.downcase!
      end

      if match = /\A((?:INSERT|REPLACE)(?: IGNORE)?\s+INTO.+?VALUES\s*\(.*?\))\s*,\s*\(/im.match(query)
        query = match.captures.first
      end

      query.gsub!(%r{/\*[^!].*?\*/}m, '')
      query.gsub!(/(?:--|#)[^\r\n]*(?=[\r\n]|\Z)/, '')

      return query if query.gsub!(/\Ause \S+\Z/i, 'use ?')

      query.gsub!(/\\["']/, '')
      query.gsub!(/".*?"/m, '?')
      query.gsub!(/'.*?'/m, '?')

      query.gsub!(/\btrue\b|\bfalse\b/i, '?')

      query.gsub!(/[0-9+-][0-9a-f.x+-]*/, '?')
      query.gsub!(/[xb.+-]\?/, '?')

      query.strip!
      query.gsub!(/[ \n\t\r\f]+/, ' ')
      query.downcase!

      query.gsub!(/\bnull\b/i, '?')

      query.gsub!(/\b(in|values?)(?:[\s,]*\([\s?,]*\))+/, '\\1(?+)')

      query.gsub!(/\b(select\s.*?)(?:(\sunion(?:\sall)?)\s\1)+/, '\\1 /*repeat\\2*/')

      query.gsub!(/\blimit \?(?:, ?\?| offset \?)/, 'limit ?')

      query.gsub!(/\G(.+?)\s+asc/, '\\1') if query =~ /\border by/

      query
    end
  end
end
