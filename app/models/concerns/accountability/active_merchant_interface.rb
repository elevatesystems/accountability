module Accountability
  module ActiveMerchantInterface
    extend ActiveSupport::Concern

    included do
      provider = Accountability::Configuration.payment_gateway[:provider]
      case provider
      when :stripe
        include StripeInterface
      else
        raise NotImplementedError, "No ActiveMerchantInterface defined for #{provider}"
      end
    end
  end
end
