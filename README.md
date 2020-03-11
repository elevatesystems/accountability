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
### Configuration
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
