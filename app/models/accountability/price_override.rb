module Accountability
  class PriceOverride < ApplicationRecord
    belongs_to :offerable_source, polymorphic: true
    belongs_to :product

    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
