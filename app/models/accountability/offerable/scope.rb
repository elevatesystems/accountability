# Scope objects represent an offerable's scoping options as defined by `offer.add_scope`
# The plan is to replace the Offerable#scopes hash attribute with an array of scope objects

class Accountability::Offerable::Scope
  attr_accessor :source_class, :category, :attribute, :title
  attr_writer :options

  def initialize(source_class:, category:, attribute:, title: nil, options: :auto)
    @source_class = source_class
    @category = category
    @attribute = attribute
    @title = title.presence || attribute.to_s.titleize
    @options = options
  end

  # Returns an array of values to choose from when defining the scope for a new product.
  # The product's `source_scope` column stores a hash mapping each scopes' @attribute with the selected options.
  #
  # For example, if an offerable called 'Bucket' has a scoped :color attribute with options %w[red green black grey],
  # a "colored bucket" product can be created with a `source_scope` of `{ color: %w[red green] }`.
  # Buckets available for purchase would be automatically found by querying `Bucket.where(color: %w[red green])`.
  #
  # When an offerable's scope has no options, it defaults to `:auto` and is generated automatically based on the
  # attribute type when `#options` is called instead.
  #    String  - Returns a unique array of values plucked from the attribute's column
  #    Enum    - Returns am array containing each valid enum value
  #    Boolean - Returns [true, false]
  # Any other attribute type will return an empty array.
  def options
    return @options unless @options == :auto

    @options = case attribute_type
               when ActiveModel::Type::String
                 source_class.distinct.pluck(attribute)
               when ActiveRecord::Enum::EnumType
                 enums = source_class.defined_enums.with_indifferent_access
                 enums[attribute].keys
               when ActiveModel::Type::Boolean
                 [true, false]
               else
                 []
               end
  end

  def attribute_type
    source_class.type_for_attribute(attribute)
  end
end
