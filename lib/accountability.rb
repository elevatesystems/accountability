require_dependency 'accountability/engine'
require_dependency 'accountability/configuration'
require_dependency 'accountability/rails/routes'
require_dependency 'accountability/extensions'
require_dependency 'accountability/types'

module Accountability
  def self.configure(_tenant = :default)
    yield Configuration if block_given?
  end
end
