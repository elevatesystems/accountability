module Accountability
  class BillingConfiguration < ApplicationRecord
    include Accountability::ActiveMerchantInterface
    after_initialize :set_provider, :set_default_country, if: :new_record?
    after_create :set_default_primary

    belongs_to :account
    has_many :payments, dependent: :nullify

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

    def set_default_country
      return unless self.billing_address.present?
      return unless Configuration.country_whitelist.present?

      self.billing_address.country = Configuration.country_whitelist.first
    end

    def set_default_primary
      return unless account.billing_configurations.one?

      primary!
    end
  end
end
