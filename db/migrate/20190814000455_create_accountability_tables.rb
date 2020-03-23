# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/MethodLength

class CreateAccountabilityTables < ActiveRecord::Migration[6.0]
  def change
    create_table :accountability_accounts do |t|
      t.belongs_to :billable, null: true, polymorphic: true
      t.integer :statement_schedule, default: 0, null: false # end_of_month bi_weekly
      t.datetime :last_balanced_at, default: nil, null: true

      t.timestamps
    end

    create_table :accountability_statements do |t|
      t.belongs_to :account, null: false, index: { name: :index_account_on_statement }
      t.datetime :end_date, default: nil, null: false

      t.timestamps
    end

    create_table :accountability_debits do |t|
      t.belongs_to :account, null: false, index: { name: :index_account_on_debit }
      t.belongs_to :payment, null: true, index: { name: :index_payment_on_debit }
      t.decimal :amount, default: 0.00, precision: 8, scale: 2, null: false

      t.timestamps
    end

    create_table :accountability_credits do |t|
      t.belongs_to :account, null: false, index: { name: :index_account_on_credit }
      t.belongs_to :order_item, null: false, index: { name: :index_order_item_on_credit }
      t.belongs_to :statement, null: false, index: { name: :index_statement_on_credit }
      t.decimal :amount, default: 0.00, precision: 8, scale: 2, null: false
      t.decimal :taxes, default: 0.00, precision: 8, scale: 2, null: false

      t.timestamps
    end

    create_table :accountability_payments do |t|
      t.belongs_to :account, null: false, index: { name: :index_account_on_payment }
      t.belongs_to :billing_configuration, null: false, index: { name: :index_billing_configuration_on_payment }

      t.decimal :amount, default: 0.00, precision: 8, scale: 2, null: false
      t.integer :status, default: 0, null: false # Pending, Processing, Complete, Failed

      t.timestamps
    end

    create_table :accountability_order_groups do |t|
      t.belongs_to :account, null: true, index: { name: :index_account_on_order_group }

      t.integer :status, default: 0, null: false # Pending, Complete, Abandoned
      t.text :notes, default: nil, null: true, limit: 10_000

      t.timestamps
    end

    create_table :accountability_order_items do |t|
      t.belongs_to :order_group, null: false, index: { name: :index_order_group_on_order_iem }
      t.belongs_to :product, null: false, index: { name: :index_product_on_order_iem }

      t.text :source_scope, default: nil, null: true, limit: 1_000
      t.datetime :termination_date, default: nil, null: true

      t.timestamps
    end

    create_table :accountability_deductions do |t|
      t.belongs_to :credit, null: false, index: { name: :index_credit_on_deduction }
      t.belongs_to :discount, null: false, index: { name: :index_discount_on_deduction }

      t.decimal :amount, default: 0.00, precision: 8, scale: 2, null: false

      t.timestamps
    end

    create_table :accountability_discounts do |t|
      t.belongs_to :order_item, null: false, index: { name: :index_order_item_on_discount }
      t.belongs_to :coupon, null: false, index: { name: :index_coupon_on_discount }

      t.timestamps
    end

    create_table :accountability_products do |t|
      t.boolean :public, default: true, null: false
      t.boolean :tax_exempt, default: false, null: false
      t.decimal :price, default: 0.00, precision: 8, scale: 2, null: false
      t.integer :quantity, default: 1, null: false
      t.string :name, default: nil, null: false
      t.string :sku, default: nil, null: true
      t.text :description, default: nil, null: true, limit: 10_000
      t.integer :schedule, default: 0, null: false # OneTime, Weekly, Monthly, Annually
      t.string :offerable_category, default: nil, null: false
      t.text :source_scope, default: nil, null: true, limit: 1_000
      t.text :billing_configuration, default: nil, null: true, limit: 1_000

      t.datetime :activation_date, default: nil, null: true
      t.datetime :expiration_date, default: nil, null: true
      t.datetime :termination_date, default: nil, null: true

      t.timestamps
    end

    create_table :accountability_coupons do |t|
      t.decimal :amount, default: 0.00, precision: 8, scale: 2, null: false
      t.boolean :public, default: true, null: false
      t.integer :limit, default: nil, null: true
      t.string :name, default: nil, null: false
      t.string :code, default: nil, null: true

      t.integer :usage_cap, default: 1, null: false

      t.datetime :activation_date, default: nil, null: true
      t.datetime :expiration_date, default: nil, null: true
      t.datetime :termination_date, default: nil, null: true

      t.timestamps
    end

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :accountability_coupons_products, id: false do |t|
      t.belongs_to :product, index: { name: :index_product_on_product_coupon }
      t.belongs_to :coupon, index: { name: :index_coupon_on_product_coupon }
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :accountability_identities do |t|
      t.belongs_to :identifiable, polymorphic: true, index: { name: :index_identifiable_on_identity }
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    create_table :accountability_billing_configurations do |t|
      t.belongs_to :account, null: false, index: { name: :index_account_on_billing_configuration }
      t.boolean :primary, default: false, null: false
      t.text :billing_address, default: nil, null: true # JSON serialized value object
      t.text :active_merchant_data, default: nil, null: true # JSON serialized data for ActiveMerchant
      t.integer :provider, default: 0, null: false # [unselected, stripe]
      t.string :token, default: nil, null: true # Used to retrieve & charge the payment method from the provider
      t.string :configuration_name, default: nil, null: true # A name for the payment method
      t.string :contact_email, default: nil, null: true
      t.string :contact_first_name, default: nil, null: true
      t.string :contact_last_name, default: nil, null: true

      t.timestamps
    end

    create_table :accountability_price_overrides do |t|
      t.belongs_to :product, index: { name: :index_product_on_price_override }
      t.belongs_to :offerable_source, null: false, polymorphic: true, index: { name: :index_offerable_source_on_price_override }

      t.decimal :price, default: 0.00, precision: 8, scale: 2, null: false # The inventory item's new price
      t.text :description, default: nil, null: true, limit: 10_000 # Optional field for describing adjustment rationale

      t.timestamps
    end
  end
end
