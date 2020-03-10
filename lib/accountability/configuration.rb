module Accountability
  class Configuration
    class << self
      attr_accessor :billable_identifier, :logo_path, :tax_rate, :payment_gateway
      attr_writer :admin_checker

      def admin_checker
        if @admin_checker.is_a? Proc
          @admin_checker
        else
          -> { true }
        end
      end
    end
  end
end
