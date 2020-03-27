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
      @order_group = OrderGroup.new(order_group_params)

      if @order_group.save
        redirect_to accountability_order_groups_path, notice: 'Successfully created new order_group'
      else
        render :new
      end
    end

    def update
      if @order_group.update(order_group_params)
        redirect_to accountability_order_groups_path, notice: 'Successfully updated order_group'
      else
        render :edit
      end
    end

    def destroy
      if @order_group.destroy
        redirect_to accountability_order_groups_path, notice: 'Successfully destroyed order_group'
      else
        redirect_to accountability_order_groups_path, alert: 'There was an issue destroying order_group'
      end
    end

    def add_item
      product = Product.find(params[:product_id])
      source_scope = params.to_unsafe_h[:source_scope]&.symbolize_keys

      if @order_group.add_item! product, source_scope: source_scope
        redirect_to accountability_order_group_path(current_order_group), notice: 'Successfully added to cart'
      else
        redirect_back fallback_location: accountability_order_groups_path, alert: 'Failed to add to cart'
      end
    end

    private

    def set_order_group
      @order_group = OrderGroup.find(params[:id])
    end

    def order_group_params
      params.require(:order_group).permit
    end
  end
end
