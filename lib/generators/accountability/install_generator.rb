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
        migration_template 'migration.rb', 'db/migrate/create_accountability_tables.rb', migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
