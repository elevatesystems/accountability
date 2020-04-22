# TODO: Implement #unstore_active_merchant_data

module Accountability
  module ActiveMerchantInterface::StripeInterface
    extend ActiveSupport::Concern

    included do
      attribute :stripe_api_errors, default: []
      validate :validate_no_stripe_errors

      # It is important to clear these errors after validation
      # so that store_active_merchant_data will run again.
      after_validation :clear_stripe_api_errors, on: %i[create update]
      after_save_commit :save_customer_info_to_stripe
    end

    def charge(amount)
      gateway = initialize_payment_gateway
      amount_in_cents = (amount * 100).round
      card_id = active_merchant_data['authorization']

      response = gateway.purchase(amount_in_cents, card_id)

      return true if response.success?

      translate_and_append_error_code(response.error_code)
      false
    end

    def store_active_merchant_data(**options)
      response = store_card_in_gateway

      unless response.success?

        translate_and_append_error_code(response.error_code)
        return
      end

      active_merchant_data = extract_active_merchant_data(response)
      validate_chargeable(**active_merchant_data) if options.fetch(:verify_card)

      self.active_merchant_data = active_merchant_data
    end

    private

    # Translates error codes from stripe into our I18n localizations and push them into stripe_api_errors.
    def translate_and_append_error_code(error_code)
      translated_error_code = I18n.t("accountability.gateway.errors.#{error_code}", default: 'accountability.gateway.errors.config_error')
      stripe_api_errors.append(translated_error_code)
    end

    def store_card_in_gateway(gateway = initialize_payment_gateway)
      raise 'No token found' if token.blank?

      gateway.store(token, description: configuration_name, email: contact_email, set_default: true)
    end

    def validate_chargeable(gateway = initialize_payment_gateway, **active_merchant_data)
      authorization = active_merchant_data[:authorization]

      response = gateway.verify(authorization, verification_params)
      return if response.success?

      translate_and_append_error_code(response.error_code)
    end

    def extract_active_merchant_data(response)
      customer_id = response.params['id']
      card_id = response.params['sources']['data'].first['id']
      authorization = response.authorization

      data = { authorization: authorization, customer_id: customer_id, card_id: card_id }
      data.symbolize_keys
    end

    def initialize_payment_gateway
      secret_key = Accountability::Configuration.payment_gateway.dig(:authentication, :secret_key)
      ActiveMerchant::Billing::StripeGateway.new(login: secret_key)
    end

    def add_customer_info(customer_id, gateway = initialize_payment_gateway)
      response = gateway.update_customer(customer_id, customer_params)
      return unless response.error_code

      Rails.logger.warn %(Warning: add_customer_info failed for #{self.class}: #{id}; card_id: #{card_id};
        customer_id: #{customer_id}; Stripe Error: #{add_customer_info_response.error_code}).squish
    end

    def add_card_info(customer_id, card_id, gateway = initialize_payment_gateway)
      response = gateway.update(customer_id, card_id, card_params)
      return unless response.error_code

      Rails.logger.warn %(Warning: add_card_info failed for #{self.class}: #{id}; card_id: #{card_id};
        customer_id: #{customer_id}; Stripe Error: #{add_customer_info_response.error_code}).squish
    end

    def save_customer_info_to_stripe(gateway = initialize_payment_gateway)
      customer_id, card_id = active_merchant_data.with_indifferent_access.values_at(:customer_id, :card_id)
      return unless customer_id && card_id

      add_customer_info(customer_id, gateway)
      add_card_info(customer_id, card_id, gateway)
    end

    def verification_params
      { description: 'Accountability Verification Charge', statement_description: 'Card Verification' }
    end

    def card_params
      { metadata: { billing_configuration_id: id, account_id: account.id },
        name: contact_name,
        address_line1: billing_address.address_1,
        address_line2: billing_address.address_2,
        address_city: billing_address.city,
        address_zip: billing_address.zip,
        address_state: billing_address.state,
        address_country: billing_address.country }
    end

    def customer_params
      { metadata: { billing_configuration_id: id, account_id: account.id },
        name: contact_name, email: contact_email,
        address: { line1: billing_address.address_1,
                   line2: billing_address.address_2,
                   city: billing_address.city,
                   postal_code: billing_address.zip,
                   state: billing_address.state,
                   country: billing_address.country } }
    end

    def validate_no_stripe_errors
      stripe_api_errors.each { |error| errors.add(:base, error) }
    end

    def clear_stripe_api_errors
      stripe_api_errors.clear
    end
  end
end
