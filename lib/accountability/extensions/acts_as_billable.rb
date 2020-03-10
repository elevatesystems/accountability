module Accountability
  module Extensions
    module ActsAsBillable
      extend ActiveSupport::Concern

      class_methods do
        def acts_as_billable
          after_create :create_default_account

          has_many :accounts, as: :billable, class_name: 'Accountability::Account', dependent: :nullify

          self.acts_as = acts_as.dup << :billable

          define_method :create_default_account do
            accounts.first_or_create
          end

          define_method :default_account do
            accounts.first
          end
        end
      end
    end
  end
end
