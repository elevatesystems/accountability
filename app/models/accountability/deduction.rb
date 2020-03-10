class Accountability::Deduction < ApplicationRecord
  belongs_to :discount
  belongs_to :credit
  has_one :coupon, through: :discount, inverse_of: :deductions

  after_initialize :set_amount

  delegate :name, to: :coupon, prefix: true

  private

  def set_amount
    return if amount.positive?

    self.amount = discount.expected_savings
  end
end
