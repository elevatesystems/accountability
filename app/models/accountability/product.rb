# A Product defines any product/service/offering available for users to buy.
# "Private" products can be made for special offers, one-time deals, or contracts.
# Terminology:
#   Activation Date - Date at which record becomes usable
#   Expired - No longer available, but still usable by prior adopters
#   Terminated - No longer available - even by prior adopters

# rubocop:disable Rails/HasAndBelongsToMany

module Accountability
  class Product < ApplicationRecord
    RECURRING_SCHEDULES = %i[weekly monthly annually].freeze

    has_and_belongs_to_many :coupons
    has_many :order_items, dependent: :restrict_with_error
    has_many :price_overrides, dependent: :destroy
    has_many :credits, through: :order_items, inverse_of: :product

    serialize :source_scope, Hash

    enum schedule: [:one_time, *RECURRING_SCHEDULES], _prefix: :accrues

    def active?
      return false unless activation_date.present?

      activation_date.past?
    end

    def billing_cycle_length
      case schedule
      when 'weekly' then 1.week
      when 'monthly' then 1.month
      when 'annually' then 1.year
      end
    end

    # Returns an Inventory object containing each record within the product's scope.
    # This method will eventually phase out the `inventory` and `available_inventory` methods.
    def inventory_items
      Inventory.new(self)
    end

    def inventory
      return [] if source_class.nil?

      source_class.where(**source_scope)
    end

    def available_inventory
      return [] if source_class.nil?

      source_class.where(**source_scope).public_send(offerable_template.whitelist)
    end

    # TODO: Update offerable_template.scopes to return an array of Scope objects and delegate to that instead
    def scopes
      return @scopes if @scopes.present?

      @scopes = offerable_template.scopes.map do |attribute, params|
        params.merge! source_class: source_class, attribute: attribute
        Offerable::Scope.new(**params)
      end
    end

    def offerable_template
      return if offerable_category.nil?
      return @offerable if @offerable.present?

      offerable = Offerable.collection[offerable_category.to_sym]

      return offerable if new_record?

      if offerable.present?
        @offerable = offerable
      else
        raise_offerable_not_found
      end
    end

    def source_class
      return if offerable_template.nil?

      offerable_template.class_name.constantize
    end

    delegate :callbacks, to: :offerable_template

    private

    def raise_offerable_not_found
      raise 'Offerable not found'
    end
  end
end
