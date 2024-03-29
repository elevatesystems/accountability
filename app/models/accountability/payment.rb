class Accountability::Payment < ApplicationRecord
  after_validation :process_transaction!, if: :pending?

  belongs_to :account
  belongs_to :billing_configuration, optional: true

  has_one :debit, dependent: :restrict_with_error

  enum status: %i[pending processing complete failed]

  validates :amount, presence: true

  def process_transaction!
    return if debit.present?
    return if errors.present?

    charge!
  end

  def charge!
    processing!

    transaction(requires_new: true, joinable: false) do
      # Do not attempt to create charges for 0. Most payment processors
      # will not allow that.
      if amount.positive?
        billing_configuration.charge(amount)
      end

      build_debit(account: account, amount: amount) if billing_configuration.validate!
      complete!
    rescue ActiveRecord::RecordInvalid
      failed!
      billing_configuration.errors.full_messages.each { |error| errors.add(:base, error.titleize) }
      raise ActiveRecord::Rollback
    end
  end
end
