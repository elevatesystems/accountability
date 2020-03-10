module Accountability
  class BillingConfiguration < ApplicationRecord
    include Accountability::ActiveMerchantInterface
    after_initialize :set_provider, if: :new_record?

    belongs_to :account
    has_many :payments, dependent: :restrict_with_error

    attribute :billing_address, :billing_address, default: {}
    attribute :active_merchant_data, :json, default: {}

    enum provider: %i[unselected stripe]

    scope :primary, -> { where primary: true }

    validates :configuration_name, presence: true
    validates :contact_first_name, :contact_last_name,
              format: { with: Regex::LETTERS_AND_NUMBERS, message: :invalid }, presence: true
    validates :contact_email, format: { with: Regex::EMAIL_ADDRESS, message: :invalid }
    validates_attributes :billing_address

    def contact_name
      "#{contact_first_name} #{contact_last_name}"
    end

    def primary!
      return if primary?

      transaction do
        account.billing_configurations.primary.update_all(primary: false) # rubocop:disable Rails/SkipsModelValidations
        update!(primary: true)
      end
    end

    private

    def set_provider
      self.provider = Configuration.payment_gateway[:provider]
    end
  end
end
