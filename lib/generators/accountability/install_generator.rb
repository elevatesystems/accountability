require 'rails/generators/active_record'

module Accountability
  module Generators
    class InstallGenerator < Rails::Generators::Base
      # Executes with: `rails generate accountability:install`
      # Note: All public instance methods will be called sequentially

      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, 'templates')

      def create_initializer_file
        initializer_content = "Accountability.configure { |_config| }"
        create_file "config/initializers/accountability.rb", initializer_content
      end

      def copy_migration
        # Note: migration.rb is always up-to-date
        if fresh_installation?
          destination = 'db/migrate/create_accountability_tables.rb'
          migration_template 'migration.rb', destination, migration_version: migration_version
          return true
        end

        # Existing applications may need new migration files
        if missing_price_overrides?
          destination = 'db/migrate/create_accountability_price_overrides_tables.rb'
          migration_template 'price_overrides_migration.rb', destination, migration_version: migration_version
        end

        if missing_payments_null_true?
          destination = 'db/migrate/remove_accountability_payments_on_billing_configuration_not_null_constraint.rb'
          migration_template 'remove_payments_on_billing_configuration_not_null_constraint.rb', destination, migration_version: migration_version
        end
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      private

      def fresh_installation?
        !ActiveRecord::Base.connection.table_exists?('accountability_accounts')
      end

      def missing_price_overrides?
        !ActiveRecord::Base.connection.table_exists?('accountability_price_overrides')
      end

      # Previously, the belong_to billing configuration on payments was not optional.
      # To allow for deletion of billing configurations, it has been set to optional.
      def missing_payments_null_true?
        payments_columns = ActiveRecord::Base.connection.columns('accountability_payments')
        billing_configuration_id = payments_columns.find { |column| column if column.name == 'billing_configuration_id' }

        true if billing_configuration_id&.null == false
      end
    end
  end
end
