module Accountability
  module ProductsHelper
    def source_class_options
      options = Accountability::Offerable.collection.stringify_keys
      options.keys.map { |offerable_name| [offerable_name.titleize, offerable_name] }
    end

    def schedule_options
      options = Accountability::Product.schedules
      options.keys.map { |schedule_name| [schedule_name.titleize, schedule_name] }
    end

    def scope_options(scope)
      scope.options.map { |option| [option.to_s.titleize, option] }
    end

    def disable_category_field?
      @stage != 'initial'
    end
  end
end
