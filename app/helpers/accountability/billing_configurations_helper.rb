module Accountability
  module BillingConfigurationsHelper
    def payment_gateway_configuration_javascript
      provider = Accountability::Configuration.payment_gateway[:provider]
      case provider
      when :stripe
        stripe_gateway_javascript
      else
        raise NotImplementedError, "No JavaScript tag defined for #{provider}"
      end
    end

    def billing_address_preview(billing_address)
      [billing_address.address_1, "#{billing_address.state}, #{billing_address.zip}"].join(' ')
    end

    private

    def stripe_gateway_javascript
      snippets = [stripe_gateway_include, stripe_gateway_config]
      join_javascript_snippets(snippets)
    end

    def stripe_gateway_include
      javascript_include_tag stripe_v3_javascript_url
    end

    def stripe_gateway_config
      publishable_key = Accountability::Configuration.payment_gateway.dig(:authentication, :publishable_key)
      script = <<~SCRIPT
        ACTIVE_MERCHANT_CONFIG = {
          STRIPE_PUBLISHABLE_KEY: "#{publishable_key}"
        }
      SCRIPT
      content_tag(:script, format_javascript(script), type: 'text/javascript')
    end

    def format_javascript(javascript)
      tabbed_out_js = javascript.split("\n").map { |line| "  #{line}" }.join("\n")
      "\n#{tabbed_out_js}\n".html_safe # rubocop:disable Rails/OutputSafety
    end

    def join_javascript_snippets(snippets = [])
      snippets.join("\n").html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
