# A Credit represents a single charge to an Account
# To preserve data integrity, credits should never be modified

module Accountability
  class Credit < ApplicationRecord
    before_validation :set_amount, :set_statement

    belongs_to :account
    belongs_to :statement
    belongs_to :order_item
    has_many :deductions, dependent: :destroy
    has_one :product, through: :order_item, inverse_of: :credits

    validates :amount, :taxes, presence: true
    validate :validate_amount_unchanged

    delegate :name, to: :product, prefix: true

    def base_price
      if new_record?
        order_item.default_price
      else
        amount + total_deductions + taxes
      end
    end

    def total_deductions
      if persisted?
        deductions.sum(:amount)
      else
        deductions.map(&:amount).sum
      end
    end

    private

    def set_amount
      return if persisted?

      pre_tax_total = base_price - total_deductions

      self.taxes = if product.tax_exempt?
                     0.00
                   else
                     pre_tax_total * Configuration.tax_rate / 100
                   end

      self.amount = pre_tax_total - taxes
    end

    def set_statement
      return if statement.present?

      current_statement = account.current_statement

      if current_statement.present?
        self.statement = current_statement
      else
        build_statement account: account
      end
    end

    def validate_amount_unchanged
      return if new_record?
      return unless amount_changed?

      errors.add(:amount, 'cannot be changed')
    end
  end
end
