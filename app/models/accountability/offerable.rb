# TODO: Reconsider using names as keys, maybe just arrays?

class Accountability::Offerable
  cattr_accessor :collection, default: {}
  attr_accessor :tenant, :category, :class_name, :trait, :scopes, :properties, :callbacks, :whitelist

  def initialize(category, tenant: :default, trait: nil, class_name:)
    @category = category
    @tenant = tenant
    @class_name = class_name
    @trait = trait
    @scopes = {}
    @properties = {}
    @callbacks = {}
    @whitelist = :all
  end

  def self.add(category, tenant: :default, trait: nil, class_name:)
    category = category.to_s.underscore.downcase.to_sym
    offerable = new(category, tenant: tenant, trait: trait, class_name: class_name)
    collection[category] = offerable

    offerable
  end

  # Used when creating a product to define queries identifying saleable records from the host table.
  # This can be used to de-scope sold inventory, but it is recommended to define a whitelist for that instead.
  #
  # CONSIDER: Add a parameter for indicating optional scopes
  def add_scope(name, title: name, options: :auto)
    scopes[name] = { title: title.to_s, options: options, category: category }

    self
  end

  # Used for limiting the product's full inventory scope to a subset.
  # Non-whitelisted records will be treated the same as a private product's inventory.
  #
  # The method takes the name of a pre-defined ActiveRecord scope as an argument.
  # If no whitelist is specified, :all will be used instead.
  def inventory_whitelist(whitelist_scope)
    self.whitelist = whitelist_scope.to_sym

    self
  end

  # Used to differentiate records within a product's scope/inventory.
  # For example, consider a co-location that allows customers to choose their own cabinet:
  #   `offer.add_property :cabinet_location_column, title: 'Asset Tag'`
  #
  # Use the `position` column if it is important that the properties display in a specific order.
  #
  # CONSIDER: Add support for property-specific pricing
  def add_property(name, title: name, position: nil)
    position = properties.size.next if position.nil?
    properties[name] = { title: title.to_s, position: position }

    self
  end

  # Used for setting multiple properties in a single line.
  # Column names will be used as titles, and property order retained.
  # `offer.add_properties :asset_tag, :room_number, :color`
  def add_properties(*names)
    names.each do |name|
      add_property(name)
    end

    self
  end

  def add_callback(method_name, **options)
    tense, event = options.slice(:before, :after).flatten
    trigger = "#{tense}_#{event}".to_sym

    params = if options[:with_options].present?
               options[:with_options].to_h { |option| [option, option] }
             else
               [*options[:with]]
             end

    callbacks[trigger] ||= []
    callbacks[trigger] << { method_name: method_name, params: params }

    self
  end

  def trait?
    trait.present?
  end

  private

  # TODO: Abstract this out
  def current_tenant
    :default
  end
end

# Load all models so offerable items are registered
Dir[Rails.root + 'app/models/*.rb'].each do |path|
  require_dependency path
end
