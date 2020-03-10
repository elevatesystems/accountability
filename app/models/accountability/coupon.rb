# rubocop:disable Rails/HasAndBelongsToMany

class Accountability::Coupon < ApplicationRecord
  has_and_belongs_to_many :products
  has_many :discounts, dependent: :restrict_with_error
  has_many :deductions, through: :discounts, inverse_of: :coupon

  validates :name, :amount, presence: true

  def usable?
    return false if used_up?

    active?
  end

  def active?
    return false if activation_date.blank?
    return false if expired?

    activation_date.past?
  end

  def expired?
    return false if expiration_date.blank?
    return false if terminated?

    expiration_date.past?
  end

  def terminated?
    return false if termination_date.blank?

    termination_date.past?
  end

  def used_up?
    return false if limit.nil?

    discounts.count >= limit
  end
end
