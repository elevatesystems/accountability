require 'forwardable'

module Accountability
  class Transactions
    extend Forwardable

    attr_accessor :transactions

    def_delegators :transactions, :each, :sort_by, :any?, :none?

    def initialize(debits: [], credits: [])
      debit_transactions = debits.map do |debit|
        Transaction.new(:debit, record: debit, amount: debit.amount, description: 'Payment')
      end

      credit_transactions = credits.map do |credit|
        Transaction.new(:credit, record: credit, amount: credit.amount, description: credit.product_name)
      end

      @transactions = debit_transactions + credit_transactions
    end

    class Transaction
      attr_accessor :type, :record, :description, :amount, :date

      def initialize(type, record:, amount:, description:, date: nil)
        @type = type
        @record = record
        @amount = amount
        @description = description
        @date = date.presence || record.created_at
      end

      def debit?
        type == :debit
      end

      def credit?
        type == :credit
      end

      def base_amount
        debit? ? base_amount : record.base_price
      end

      def deductions
        debit? ? [] : record.deductions
      end

      def taxes
        debit? ? 0 : record.taxes
      end
    end
  end
end
