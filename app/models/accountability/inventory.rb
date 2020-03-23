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
      records = source_class.where(**source_scope)
      records = records.public_send(offerable_template.whitelist) if scope_availability?

      records.map { |record| InventoryItem.new(record: record, product: product) }
    end

    def available
      @scope_availability = true

      self
    end

    private

    class InventoryItem
      attr_accessor :record, :product

      def initialize(record:, product:)
        @record = record
        @product = product
      end

      def price
        product.price
      end
    end

    private

    def scope_availability?
      @scope_availability
    end
  end
end
