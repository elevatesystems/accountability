module Accountability
  class ProductsController < AccountabilityController
    before_action :track_order, only: :index
    before_action :set_product, except: %i[index new create]

    def index
      @products = Product.all
    end

    def new
      @product = Product.new
      @stage = 'initial'
    end

    def show; end

    def edit; end

    def create
      @product = Product.new(product_params)

      if params[:stage] == 'initial'
        @stage = 'final'
        render :new
      elsif @product.save
        redirect_to accountability_products_path, notice: 'Successfully created new product'
      else
        render :new
      end
    end

    def update
      if @product.update(product_params)
        redirect_to accountability_products_path, notice: 'Successfully updated product'
      else
        render :edit
      end
    end

    def destroy
      if @product.destroy
        redirect_to accountability_products_path, notice: 'Successfully destroyed product'
      else
        redirect_to accountability_products_path, alert: 'There was an issue destroying product'
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :sku, :price, :description, :source_class, :source_trait, :source_scope, :offerable_category)
    end
  end
end
