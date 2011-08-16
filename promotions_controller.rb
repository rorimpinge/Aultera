class PromotionsController < ApplicationController
  before_filter :check_authentication, :check_authorization, :force_no_cache
  
  def index
    @promotions = Promotion.paginate(:page => params[:page], :order => 'active_start desc', :include => [:products, :orders])
  end
  
  def show
    @promotion = Promotion.get_cache(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @promotion }
    end
  end
  
  def new
    @promotion = Promotion.new(:active => true, :active_start => Date.today, :active_end => Date.today + 1.month)
    @product_options = @promotion.options_for_select
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @promotion }
    end
  end
  
  def create
    @promotion = Promotion.new(params[:promotion])
    respond_to do |format|
      if @promotion.save
        flash[:notice] = 'Coupon code was successfully created.'
        update_products(@promotion, params)
        format.html { redirect_to(promotions_url) }
        format.xml  { render :xml => @promotion, :status => :created, :location => @promotion }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blob.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @promotion = Promotion.find(params[:id])
    @product_options = @promotion.options_for_select
  end
  
  def update
    @promotion = Promotion.get_cache(params[:id])
    respond_to do |format|
      if @promotion.update_attributes(params[:promotion])
        flash[:notice] = 'Coupon code was successfully updated.'
        update_products(@promotion, params)
        format.html { redirect_to(@promotion) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @promotion.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    promotion = Promotion.find_by_id(params[:id])
    promotion.destroy unless promotion.nil?
    respond_to do |format|
      format.html { redirect_to(promotions_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  def update_products(promo, params)
    promo.products.clear
    if params[:products]
      params[:products].each{ |prod_id| promo.products << Product.find_by_id(prod_id) }
    end
  end
end
