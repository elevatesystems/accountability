require 'active_merchant'
require_dependency 'accountability/types/billing_configuration_types'

module Accountability
  module Types
    include BillingConfigurationTypes
    ActiveRecord::Type.register(:billing_address, Accountability::Types::BillingAddressType)
  end
end
