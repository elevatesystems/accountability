require 'active_support/core_ext/hash'

module ActionDispatch::Routing
  class Mapper
    def accountability_for(_tenants, options = {})
      options[:controllers] ||= {}
      options[:routes] ||= {}

      options[:controllers].reverse_merge! default_accountability_controller_options
      options[:routes].reverse_merge! default_accountability_route_options

      options[:path_prefix] ||= options[:path] if options[:path_prefix].nil?

      define_accountability_routes(options)
    end

    def define_accountability_routes(options)
      cartographer = -> { accountability_routes(options) }

      cartographer.call
      Accountability::Engine.routes.draw(&cartographer)
    end

    def accountability_routes(options)
      scope path: options[:path_prefix], as: :accountability do
        resources :accounts, controller: options.dig(:controllers, :accounts), path: options.dig(:routes, :accounts) do
          resources :billing_configurations, controller: options.dig(:controllers, :billing_configurations), path: options.dig(:routes, :billing_configurations) do
            member { patch :designate_as_primary }
          end

          resources :payments, only: :create, controller: 'accountability/payments', path: 'payments'
          resources :statements, only: [], controller: 'accountability/statements', path: 'statements' do
            member { get :download_pdf }
          end
        end

        resources :products, controller: options.dig(:controllers, :products), path: options.dig(:routes, :products)

        resources :order_groups, controller: options.dig(:controllers, :order_groups), path: options.dig(:routes, :order_groups) do
          member { post :add_item }
        end
      end

      unscoped_direct(:stripe_v3_javascript) { 'https://js.stripe.com/v3/' }
    end

    def default_accountability_controller_options
      {
        accounts: 'accountability/accounts',
        products: 'accountability/products',
        order_groups: 'accountability/order_groups',
        billing_configurations: 'accountability/billing_configurations'
      }
    end

    def default_accountability_route_options
      {
        accounts: 'accounts',
        products: 'products',
        order_groups: 'orders',
        billing_configurations: 'billing_configurations'
      }
    end

    # Mimic the functionality of Mapper#direct so that we can add a "direct" route from the cartographer proc even
    # though we are in a scope because of #isolate_namespace.
    # https://github.com/rails/rails/blob/6-0-stable/actionpack/lib/action_dispatch/routing/mapper.rb#L2119-L2125
    def unscoped_direct(name, options = {}, &block)
      @set.add_url_helper(name, options, &block)
    end
  end
end
