# TODO: Reconsider using names as keys, maybe just arrays?

class Accountability::Offerable
  cattr_accessor :collection, default: {}
  attr_accessor :tenant, :category, :class_name, :trait, :scopes, :properties, :callbacks

  def initialize(category, tenant: :default, trait: nil, class_name:)
    @category = category
    @tenant = tenant
    @class_name = class_name
    @trait = trait
    @scopes = {}
    @properties = {}
    @callbacks = {}
  end

  def self.add(category, tenant: :default, trait: nil, class_name:)
    category = category.to_s.underscore.downcase.to_sym
    offerable = new(category, tenant: tenant, trait: trait, class_name: class_name)
    collection[category] = offerable

    offerable
  end

  def add_scope(name, title: name, options: :auto)
    scopes[name] = { title: title.to_s, options: options, category: category }

    self
  end

  def add_property(name, title: name, position: nil)
    position = properties.size.next if position.nil?
    properties[name] = { title: title.to_s, position: position }
    self
  end

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
