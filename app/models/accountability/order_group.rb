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
      trigger_callback :before_checkout

      transaction do
        complete!
        accrue_credits!

        trigger_callback :after_checkout
      end
    end

    def accrue_credits!
      return unless complete?

      order_items.each(&:accrue_credit!)
    end

    def add_item!(product)
      order_items.create! product: product
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
