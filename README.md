# Accountability
An extensible Rails library for easy product & billing management.

## Usage
### Installing the gem
To get started, add Accountability to your application's Gemfile.
```ruby
gem 'accountability'
``` 

Next you must run Bundler, generate the install files, and run migrations.

```bash
bundle install
rails generate accountability:install
rake db:migrate
```

### Adding routes
You must specify a path to mount Accountability's engine to from inside your `config/routes.rb` file. In this example, we will mount everything to `/billing`. 

```ruby
accountability_views_for :admin, :public, path: '/billing'
```

The `accountability_views_for` routing helper can take any number of tenant names as arguments. Specifying tenants is only necessary if your application needs to use Accountability multiple times (such as an app with several e-commerce sites).

This will generate the following routes:
* `/billing` - Redirects to products page 
* `/billing/products`
* `/billing/orders` 
* `/billing/accounts`

**Note:** Accountability does not have its own `ApplicationController` and will use yours instead. This means that your layouts file will be used. Prepend path helpers with `main_app.` to prevent links from breaking within Accountability's default views.

### Defining billable models
Billable models (such as a User, Customer, or Organization) need to be declared in order to accrue credits and make payments.  

```ruby
class User < ApplicationRecord
  acts_as_billable  

  ...
```

By default, Accountability identifies the billable entity from the `@current_user` variable. This can be changed from the [initializer file](Customizing configuration options). 

### Creating products
In order to make a `Product`, at least one model must indicate that it is "offerable." For example, let's say we want to sell baskets:
```ruby
class Basket < ApplicationRecord
  acts_as_offerable

  ...
```  
You can now visit the `/billing/products/new` page and select "Basket" category.

If you want to have multiple offerable categories on the same model, you can set a custom category name:
```ruby
class Basket < ApplicationRecord
  has_offerable :basket
  has_offerable :bucket

  ...
```

Note that `has_offerable` is an alias of `acts_as_offerable`.

For additional ways to define offerable content, see the "Advanced Usage" section. 
### Customizing configuration options
To customize Accountability, create a `config/initializers/accountability.rb` file:
```ruby
Accountability.configure do |config|
  # Customize Accountability settings here
end
``` 

#### Customer identification
By default, Accountability will reference the `@current_user` variable when identifying a billable user. 
This will work for most applications using Devise with a User model representing customers.

You can customize this behavior by defining either a proc or lamda that returns an instance of any "billable" record. A nil response will trigger a new guest session.

You can optionally specify one of the billable record's attributes to reference as a user-friendly name in the views. The ID is used by default.   

```ruby
config.billable_identifier = -> { current_user&.organization }
config.billable_name_column = :full_name
```      

#### Tax rates
Currently, tax rates are defined statically as a percentage of the product's price. Feel free to open a PR if you require something more complex.

The default value is `0.0`.

```ruby
config.tax_rate = 9.53
```

Note that products can be marked as tax exempt.  

#### Debugger tools
To print helpful session information in the views such as the currently tracked billable entity, enable the dev tools.

```ruby
config.dev_tools_enabled = true
```

## Advanced Usage
### Defining Offerable Content
#### Scopes
Scoping options can be defined to constrain products to a narrower set of records. Let's say that we want to sell both large and small baskets:
```ruby
class Basket < ApplicationRecord
  enum style: %i[small large narrow deep]
  
  acts_as_offerable do |offer|
    offer.add_scope :style, title: 'Size', options: %i[small large] 
  end
end
```  

#### Callbacks
#### Multi-Tenancy
#### Dynamic Pricing
AKA traits

## TODO
- [ ] Finish implementing multi-tenanting features
- [ ] Add support for controller overrides
- [ ] Implement product creation workflow in views
