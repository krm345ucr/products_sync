class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = Product.all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product was successfully destroyed."
  end

  # SYNC ACTION MUTLAKA CLASS İÇİNDE
  def sync
    GoogleSheetsSyncService.new.sync_from_sheet
    redirect_to products_path, notice: "Sync çalıştı"
  end

  private

  def set_product
    @product = Product.find_by(id: params[:id])

    return redirect_to(products_path, alert: "Ürün zaten silinmiş.") unless @product
  end

  def product_params
    params.require(:product).permit(:name, :price, :stock, :category)
  end
end
