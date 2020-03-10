# TODO: Set the parent class dynamically (Accountability.parent_controller.constantize)

module Accountability
  class AccountabilityController < ApplicationController
    protect_from_forgery with: :exception

    private

    def track_order
      # Check if session is billable (billable_identifier proc returns a record)
      billable_record = instance_exec(&Configuration.billable_identifier)

      if billable_record.present?
        track_user_session(billable_record)
      else
        track_guest_session
      end
    end

    def track_user_session(billable_record)
      raise 'Record not billable' unless billable_record.acts_as.billable?

      current_account = billable_record.accounts.first_or_create!
      session[:current_account_id] = current_account.id

      if current_order_group&.unassigned?
        current_order_group.assign_account! current_account
      else
        current_order_group = current_account.order_groups.pending.first_or_create!
        session[:current_order_group_id] = current_order_group.id
      end
    end

    def track_guest_session
      # Check if the order already belongs to someone
      return if current_order_group&.unassigned?

      current_order_group = OrderGroup.create!
      session[:current_order_group_id] = current_order_group.id
    end

    def current_order_group
      order_group_id = session[:current_order_group_id]
      OrderGroup.find_by(id: order_group_id)
    end
  end
end
