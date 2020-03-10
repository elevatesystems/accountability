class Accountability::Discount < ApplicationRecord
  belongs_to :coupon
  belongs_to :order_item
  has_many :deductions, dependent: :nullify

  delegate :amount, to: :coupon, prefix: true

  def apply(credit)
    return unless usable?

    credit.deductions.new(discount: self)
  end

  def usages
    deductions.count
  end

  def usable?
    return false if used_up?

    coupon.usable?
  end

  def expected_savings
    percent_off = coupon_amount / 100.00
    order_item.default_price * percent_off
  end

  private

  def used_up?
    return false if coupon.usage_cap.blank?

    usages >= coupon.usage_cap
  end
end
