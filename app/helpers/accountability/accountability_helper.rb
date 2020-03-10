module Accountability
  module AccountabilityHelper
    def admin_session?
      instance_exec(&Configuration.admin_checker)
    end

    def current_account
      return if session[:current_account_id].nil?

      Account.find_by(id: session[:current_account_id])
    end

    def current_order_group
      return if session[:current_order_group_id].nil?

      OrderGroup.find_by(id: session[:current_order_group_id])
    end
  end
end
