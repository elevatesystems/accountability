class Accountability::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation :validate_validatable_attributes
  cattr_accessor :validatable_attribute_names, default: []

  def self.validates_attributes(*attribute_names)
    self.validatable_attribute_names = attribute_names
  end

  private

  def validate_validatable_attributes
    validatable_attribute_names.each do |attribute_name|
      attribute = public_send attribute_name

      next if attribute.blank?

      attribute.validate

      attribute.errors.each do |sub_attribute_name, error_message|
        target = "#{attribute_name}.#{sub_attribute_name}".to_sym
        errors.add target, error_message
      end
    end
  end
end
