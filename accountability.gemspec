$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'accountability/version'

Gem::Specification.new do |spec|
  spec.name        = 'accountability'
  spec.version     = Accountability::VERSION
  spec.authors     = ['Joshua Stowers']
  spec.email       = ['joshua.stowers@elevatesystems.com', 'evan.gray@elevatesystems.com']
  spec.homepage    = 'https://elevatesystems.com'
  spec.summary     = 'All-in-one billing management solution'
  spec.description = 'In Development - Coming Soon'
  spec.license     = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'README.md']

  # Declare any development dependencies in the Gemfile.

  spec.add_dependency 'active_accountability_merchant'
  spec.add_dependency 'prawn'
  spec.add_dependency 'prawn-table'
  spec.add_dependency 'rails' # Verified on '~> 6.0.0.rc2'
end
