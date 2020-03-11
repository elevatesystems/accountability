module Accountability
  class Configuration
    class << self
      attr_accessor :logo_path, :tax_rate, :payment_gateway
      attr_writer :admin_checker, :billable_identifier

      def admin_checker
        if @admin_checker.is_a? Proc
          @admin_checker
        else
          -> { true }
        end
      end

      def billable_identifier
        if @billable_identifier.is_a? Proc
          @billable_identifier
        else
          -> { @current_user }
        end
      end
    end
  end
end
