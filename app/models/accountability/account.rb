# The Account class acts as a ledger. It compares the accrued credits (expenses) and debits (deposits).

module Accountability
  class Account < ApplicationRecord
    belongs_to :billable, polymorphic: true

    has_many :statements, dependent: :destroy
    has_many :order_groups, dependent: :destroy
    has_many :order_items, through: :order_groups, inverse_of: :account
    has_many :purchased_order_groups, -> { complete }, class_name: 'OrderGroup', inverse_of: :account
    has_many :purchased_order_items, through: :purchased_order_groups, source: :order_items, inverse_of: :account
    has_many :payments, dependent: :nullify
    has_many :credits, dependent: :destroy
    has_many :debits, dependent: :destroy
    has_many :billing_configurations, dependent: :destroy

    enum statement_schedule: %i[end_of_month bi_weekly]

    def build_billing_configuration_with_active_merchant_data(billing_configuration_params, **options)
      billing_configuration = billing_configurations.build(billing_configuration_params)
      # We don't want to run this too often as it does create a charge against the card when verify_card is true.
      # so we'll only run this when the config is valid.
      billing_configuration.store_active_merchant_data(**options) if billing_configuration.valid?
      billing_configuration
    end

    def balance
      accrued_credits = credits.sum(:amount)
      accrued_debits = debits.sum(:amount)

      accrued_debits - accrued_credits
    end

    def balanced?
      balance >= 0.00
    end

    def transactions
      associated_credits = credits.includes(:product, deductions: :discount).references(:order_item)

      Transactions.new(debits: debits, credits: associated_credits)
    end

    def current_statement
      latest_statement = statements.last

      return if latest_statement.nil?
      return if latest_statement.past?

      latest_statement
    end
  end
end
