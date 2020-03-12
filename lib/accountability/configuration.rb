module Accountability
  class Configuration
    class << self
      attr_accessor :logo_path, :payment_gateway, :dev_tools_enabled
      attr_writer :tax_rate, :admin_checker, :billable_identifier, :billable_name_column

      def tax_rate
        @tax_rate || 0.0
      end

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

      def billable_name_column
        @billable_name_column || :id
      end

      def dev_tools_enabled?
        !!dev_tools_enabled
      end
    end
  end
end
