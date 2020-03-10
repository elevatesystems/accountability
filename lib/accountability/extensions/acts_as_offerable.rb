module Accountability
  module Extensions
    module ActsAsOfferable
      extend ActiveSupport::Concern

      class_methods do
        def has_offerable(category = name, **options)
          tenants = options.values_at(:tenants, :tenant)
          tenants.append(:default) if tenants.empty?

          tenants.each do |tenant|
            offerable_category = Offerable.add(category, tenant: tenant, class_name: name)
            yield offerable_category if block_given?
          end

          self.acts_as = acts_as.dup << :offerable
        end

        alias_method :acts_as_offerable, :has_offerable

        def has_offerable_trait(trait_name, **options)
          tenants = options.values_at(:tenants, :tenant)
          tenants.append(:default) if tenants.empty?
          category = options[:category].presence || trait_name

          tenants.each do |tenant|
            offerable_category = Offerable.add(category, tenant: tenant, trait: trait_name, class_name: name)
            yield offerable_category if block_given?
          end

          self.acts_as = acts_as.dup << :offerable
        end
      end
    end
  end
end
