# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class QueryRequest # :nodoc:
      attr_reader :sql, :name, :prepare, :batch, :allow_retry, :materialize_transactions

      def initialize(sql:, name:, binds: nil, binds_payload: nil, prepare:, batch:, allow_retry:, materialize_transactions:)
        @sql = sql
        @name = name
        @binds = binds
        @binds_payload = binds_payload
        @prepare = prepare
        @batch = batch
        @allow_retry = allow_retry
        @materialize_transactions = materialize_transactions
        freeze
      end

      def with(sql: @sql, binds: self.binds, prepare: @prepare, allow_retry: @allow_retry)
        self.class.new(sql: sql, name: @name, binds: binds, prepare: prepare, batch: @batch,
          allow_retry: allow_retry, materialize_transactions: @materialize_transactions)
      end

      def binds
        @binds_payload ? Marshal.load(@binds_payload) : @binds
      end

      def shareable
        payload = RactorConnectionHandler::Proxy.dump_binds(binds)
        request = self.class.new(sql: @sql, name: @name,
          binds: payload ? nil : [], binds_payload: payload,
          prepare: !!@prepare, batch: !!@batch, allow_retry: !!@allow_retry,
          materialize_transactions: !!@materialize_transactions)
        ActiveSupport::Ractors.make_shareable(request)
      end
    end
  end
end
