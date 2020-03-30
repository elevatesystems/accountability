module Accountability
  module Types
    module BillingConfigurationTypes
      class BillingAddress
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :address_1, :string
        attribute :address_2, :string
        attribute :zip, :integer
        attribute :city, :string
        attribute :state, :string
        attribute :country, :string

        validates :address_1, :city, :state, :country, presence: true
        validates :zip, numericality: { only_integer: true }
        validate :validate_country_whitelisted

        def validate_country_whitelisted
          return unless Configuration.country_whitelist.present?
          return if country.blank?

          errors.add(:country, :not_permitted) unless Configuration.country_whitelist.include? country
        end
      end

      class BillingAddressType < ActiveModel::Type::Value
        def type
          :text
        end

        def cast_value(value)
          case value
          when String
            decoded_value = ActiveSupport::JSON.decode(value)
            BillingAddress.new(decoded_value)
          when Hash
            BillingAddress.new(value)
          when BillingAddress
            value
          end
        end

        # Only serialize the attributes that we have defined
        # and keep extraneous things like "errors" or
        # "validation_context" from slipping into the database.
        def serialize(data)
          case data
          when Hash
            billing_address = BillingAddress.new(data)
            ActiveSupport::JSON.encode(billing_address.attributes)
          when BillingAddress
            ActiveSupport::JSON.encode(data.attributes)
          else
            super(data)
          end
        end

        def changed_in_place?(raw_old_value, new_value)
          cast_value(raw_old_value) != new_value
        end
      end
    end
  end
end
