# OrderGroups are like shopping carts - they group together purchases (ordered items) that were made together.
# We wanted to name this 'Order', but for obvious reasons that wouldn't work out
# In the future we can use this for tracking referrals and contracts.

module Accountability
  class OrderGroup < ApplicationRecord
    belongs_to :account, optional: true

    has_many :order_items, dependent: :destroy

    enum status: %i[pending complete abandoned]

    validates :account, presence: true, if: :complete?

    def checkout!
      transaction do
        trigger_callback :before_checkout

        complete!
        accrue_credits!

        trigger_callback :after_checkout
      end
    end

    def accrue_credits!
      return unless complete?

      initial_balance = account.balance
      order_items.each(&:accrue_credit!)
      current_balance = account.balance

      amount_charged = initial_balance - current_balance
      account.charge(amount_charged) if Configuration.automatic_billing_enabled?
    end

    def raw_total
      order_items.sum(&:default_price)
    end

    # The `product` parameter accepts Product, String, and Integer objects
    def add_item!(product, source_scope: nil)
      product = Product.find(product) unless product.is_a? Product

      order_items.create! product: product, source_scope: source_scope.presence
    end

    def unassigned?
      account.nil?
    end

    def assign_account!(account)
      update! account: account
    end

    private

    def trigger_callback(trigger)
      order_items.each do |item|
        item.trigger_callback trigger
      end
    end
  end
end
