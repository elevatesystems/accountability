require_dependency 'accountability/extensions/acts_as_billable'
require_dependency 'accountability/extensions/acts_as_offerable'

module Accountability
  module Extensions
    extend ActiveSupport::Concern

    included do
      class_attribute :acts_as, default: ActiveSupport::ArrayInquirer.new
    end

    include ActsAsBillable
    include ActsAsOfferable
  end
end
