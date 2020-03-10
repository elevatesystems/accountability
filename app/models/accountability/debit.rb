# We reset the account's :last_balanced_at after a debit is created.
# It is very important to make sure that the value is always accurate.

class Accountability::Debit < ApplicationRecord
  before_validation :set_amount
  after_create :update_last_balanced_at!

  belongs_to :account
  belongs_to :payment, optional: true

  private

  def set_amount
    return unless amount.zero?

    self.amount = payment.amount
  end

  def update_last_balanced_at!
    return unless account.balanced?

    account.update(last_balanced_at: created_at)
  end
end
