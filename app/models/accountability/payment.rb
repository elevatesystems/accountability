class Accountability::Payment < ApplicationRecord
  after_validation :process_transaction!, if: :pending?

  belongs_to :account
  belongs_to :billing_configuration, optional: true

  has_one :debit, dependent: :restrict_with_error

  enum status: %i[pending processing complete failed]

  validates :amount, presence: true, numericality: { greater_than: 10.00 }

  def process_transaction!
    return if debit.present?
    return if errors.present?

    if billing_configuration.charge(amount)
      self.status = :complete
      build_debit(account: account, amount: amount)
    elsif billing_configuration.invalid?
      self.status = :failed
      billing_configuration.errors.full_messages.each { |error| errors.add(:base, error.titleize) }
    else
      self.status = :failed
    end
  end
end
