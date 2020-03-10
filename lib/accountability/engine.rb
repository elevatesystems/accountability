module Accountability
  class Engine < ::Rails::Engine
    isolate_namespace Accountability

    ActiveSupport.on_load :active_record do
      include Extensions
      include Types
    end

    ActiveSupport.on_load :action_controller do
      helper Accountability::BillingConfigurationsHelper
    end
  end
end
