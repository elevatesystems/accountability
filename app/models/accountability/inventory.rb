require 'forwardable'

# The InventoryItems class is conceptually comparable to ActiveRecord's CollectionProxy.
# It provides an interface for interacting with inventory records within a product's scope.
#
# This is an improvement over the original approach of returning a source_class::ActiveRecord_Relation object which
# lacked any information related to the Accountability::Product record itself.
#
# Usage:
#   inventory = Inventory.new(product)
#   inventory.available.count

module Accountability
  class Inventory
    extend Forwardable

    attr_accessor :product

    def_delegators :product, :source_class, :source_scope, :offerable_template
    def_delegators :collection, :to_s, :each, :first, :last, :sort_by, :any?, :none?, :count

    def initialize(product, available_only: false)
      @product = product
      @scope_availability = available_only
    end

    def collection
      source_records.map { |record| InventoryItem.new(record: record, product: product, inventory: self) }
    end

    def source_records
      records = source_class.where(**source_scope).includes(:price_overrides)
      records = records.public_send(offerable_template.whitelist) if scope_availability?
      records
    end

    def available
      @scope_availability = true

      self
    end

    def available_source_ids
      return @available_source_ids if @available_source_ids.present?

      @available_source_ids = Inventory.new(product, available_only: true).source_records.ids
    end

    private

    class InventoryItem
      attr_accessor :record, :product, :inventory

      def initialize(record:, product:, inventory:)
        @record = record
        @product = product
        @inventory = inventory
      end

      def price
        # Iterating pre-loaded content is faster with Ruby than an N+1 in SQL
        price_override = record.price_overrides.find { |override| override.product_id == product.id }
        price_override&.price || product.price
      end

      def available?
        return @available unless @available.nil?

        @available = inventory.available_source_ids.include? record.id
      end

      def unavailable?
        !available?
      end
    end

    private

    def scope_availability?
      @scope_availability
    end
  end
end
