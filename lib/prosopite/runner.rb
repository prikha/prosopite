module Prosopite
  class Runner
    def initialize(whitelist: [])
      @whitelist = ['active_record/validations/uniqueness'] + whitelist
    end

    def scan(&block)
      init_store
      record_sql(&block)
      detect_n_plus_ones
    end

    private

    attr_reader :store, :whitelist

    def init_store
      @store = {}
    end

    def detect_n_plus_ones
      store.values.select do |statement|
        next if statement[:count] <= 1
        next if statement[:caller].any? {|backtrace_line| whitelist.any? {|whitelisted| backtrace_line.include?(whitelisted) }}

        compact_caller = statement[:caller].reject { |line| line.include?(::Bundler.bundle_path.to_s) }

        {
          sql: statement[:sql],
          count: statement[:count],
          caller: compact_caller
        }
      end
    end

    def record_sql(&block)
      subscriber = ActiveSupport::Notifications.subscribe 'sql.active_record' do |_, _, _, _, data|
        sql = data[:sql]

        next unless sql.include?('SELECT') && data[:cached].nil? && Query.fingerprint(sql)
        location_key = Digest::SHA1.hexdigest(caller.join)

        sql_fingerprint = Query.fingerprint(sql)

        next unless sql_fingerprint

        store["#{sql_fingerprint}_#{location_key}"] ||= {
          count: 0,
          sql: [],
          caller: nil
        }

        store["#{sql_fingerprint}_#{location_key}"][:count] += 1
        store["#{sql_fingerprint}_#{location_key}"][:sql] << sql
        store["#{sql_fingerprint}_#{location_key}"][:sql].uniq!
        store["#{sql_fingerprint}_#{location_key}"][:caller] ||= caller.dup
      end

      block.call

    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end
end
