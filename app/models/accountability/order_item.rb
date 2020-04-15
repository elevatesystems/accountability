# An OrderItem represents a Product that has been (or is being) purchased
# They are stored in an OrderGroup, which acts like a shopping cart

module Accountability
  class OrderItem < ApplicationRecord
    belongs_to :product, inverse_of: :order_items
    belongs_to :order_group
    has_one :account, through: :order_group
    has_many :credits, dependent: :destroy
    has_many :discounts, dependent: :destroy

    serialize :source_scope, Hash

    scope :active, -> { where(termination_date: Time.current..DateTime::Infinity.new).or(where(termination_date: nil)) }
    scope :recurring, -> { joins(:product).merge(Accountability::Product.recurring) }

    delegate :name, to: :product, prefix: true

    def accrue_credit!
      return unless accruing?

      credit = credits.new account: account
      discounts.each { |discount| discount.apply(credit) }
      credit.save!
    end

    def terminate!(date: Time.current)
      transaction(requires_new: true, joinable: false) do
        trigger_callback :before_terminate

        update! termination_date: date

        trigger_callback :after_terminate
      end
    end

    def terminated?
      return false if termination_date.nil?

      termination_date.past?
    end

    def accruing?
      return false unless accruable?
      return true if credits.none?
      return false if product.accrues_one_time?

      billing_cycle_threshold = product.billing_cycle_length.ago
      last_accruement_date.before? billing_cycle_threshold
    end

    def accruable?
      return false if terminated?
      return false if account.nil?

      order_group.complete?
    end

    def last_accruement_date
      credits.reload
      credits.maximum(:created_at)
    end

    def default_price
      return price_override.price if price_override.present?

      product.price
    end

    def price_override
      return @price_override unless @price_override.nil?
      return unless source_records.one?

      # Memoize as `false` if nil to avoid re-running query
      @price_override = product.price_overrides.find_by(offerable_source: source_records) || false
    end

    def trigger_callback(trigger)
      source_records.each do |record|
        next unless product.callbacks.has_key? trigger

        product.callbacks[trigger].each do |callback|
          data = { billable: account.billable, offerable_category: product.offerable_template }

          arguments = callback[:params]
          keyword_arguments = arguments.extract_options!

          arguments = data.values_at(*arguments)
          keyword_arguments = keyword_arguments.to_h { |keyword, data_type| [keyword, data[data_type]] }

          params = arguments
          params << keyword_arguments if keyword_arguments.present?

          record.public_send(callback[:method_name], *params)
        end
      end
    end

    def source_records
      return @source_records unless @source_records.nil?

      return [] if source_scope.empty?
      return [] if product.source_class.nil?

      @source_records = product.source_class.where(**source_scope)
    end
  end
end
