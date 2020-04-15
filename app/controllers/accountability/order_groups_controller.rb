module Accountability
  class OrderGroupsController < AccountabilityController
    before_action :set_order_group, except: %i[index new create]
    before_action :track_order, except: %i[index]

    def index
      @order_groups = OrderGroup.all
    end

    def new
      redirect_to accountability_order_group_path(current_order_group)
    end

    def show; end

    def edit; end

    def create
      @order_group = params[:order_group].present? ? OrderGroup.new(order_group_params) : OrderGroup.new
      source_scope = params.to_unsafe_h[:source_scope]&.symbolize_keys

      if @order_group.save
        @order_group.add_item!(params[:product_id], source_scope: source_scope) if params[:product_id].present?

        notice = I18n.t('accountability.flash.order_groups.create_success')
        redirect_to accountability_order_group_path(@order_group), notice: notice
      else
        alert = I18n.t('accountability.flash.order_groups.create_failure')
        redirect_back fallback_location: root_path, alert: alert
      end
    end

    def update
      if @order_group.update(order_group_params)
        notice = I18n.t('accountability.flash.order_groups.update_success')
        redirect_to accountability_order_groups_path, notice: notice
      else
        render :edit
      end
    end

    def destroy
      if @order_group.destroy
        notice = I18n.t('accountability.flash.order_groups.destroy_success')
        redirect_to accountability_order_groups_path, notice: notice
      else
        alert = I18n.t('accountability.flash.order_groups.destroy_failure')
        redirect_to accountability_order_groups_path, alert: alert
      end
    end

    def add_item
      product = Product.find(params[:product_id])
      source_scope = params.to_unsafe_h[:source_scope]&.symbolize_keys

      if @order_group.add_item! product, source_scope: source_scope
        notice = I18n.t('accountability.flash.order_groups.add_item_success')
        redirect_to accountability_order_group_path(current_order_group), notice: notice
      else
        alert = I18n.t('accountability.flash.order_groups.add_item_failure')
        redirect_back fallback_location: accountability_order_groups_path, alert: alert
      end
    end

    def checkout
      @order_group.assign_account!(helpers.current_account) if @order_group.unassigned?

      if @order_group.checkout!
        notice = I18n.t('accountability.flash.order_groups.checkout_success')
        redirect_to after_checkout_path(@order_group), notice: notice
      else
        if @order_group.errors.blank?
          alert = I18n.t('accountability.flash.order_groups.checkout_failure')
        else
          errors = @order_group.errors.full_messages.join(',')
          alert = I18n.t('accountability.flash.order_groups.checkout_failure_with_errors', errors: errors)
        end
        redirect_back fallback_location: accountability_order_group_path(@order_group), alert: alert
      end
    end

    private

    def set_order_group
      @order_group = OrderGroup.find(params[:id])
    end

    def order_group_params
      params.require(:order_group).permit
    end

    def after_checkout_path(_order_group)
      accountability_order_groups_path
    end
  end
end
