class Promotion < ActiveRecord::Base
  acts_as_cached
  after_save :expire_cache
  
  cattr_reader :per_page
  @@per_page = 10
  
  has_and_belongs_to_many :orders
  has_and_belongs_to_many :products
  validates_uniqueness_of :code, :message => "This promo code is already in system."
  validates_numericality_of :discount, :minimum
  validates_presence_of :code, :discount, :active, :active_start, :active_end, :minimum
  validates_inclusion_of :promotion_type, :in => %w( P F ), :message => "P or F are only choices!"
  
  def active?(today = Date.today)
    if self.active > 0
      if (self.active_start..self.active_end).member?(today)
        return true
      end
    end
    false
  end
  
  def can_apply_to_cart?(cart)
    if self.active? && (self.active_start..self.active_end).member?(Date.today)
      discountable_subtotal = get_discountable_sub_total(cart)
      case self.promotion_type
        when 'P'
        return true if self.minimum <= cart.total_price && discountable_subtotal > 0
        
        when 'F'
        return true if self.minimum <= cart.total_price && self.discount <= discountable_subtotal
      end
    end
    return false
  end
  
  def apply_to_cart(cart)
    discountable_subtotal = get_discountable_sub_total(cart)
    promo_item = cart.add_product(Product.find_by_code('DSC-Promo'), nil)
    case self.promotion_type
      when 'P'
      promo_item.unit_price = -self.discount * discountable_subtotal
      return promo_item.unit_price
      
      when 'F'
      promo_item.unit_price = -self.discount
      return self.discount
      
    end
  end
  
  def total_discount_using
    total = 0.0
    orders.each{ |order|
      promo = order.line_items.detect{ |item| item.product.code =~ /DSC-Promo/ }
      total += promo.unit_price if promo
    }
    return total
  end
  
  #I needed a specialized version of this to exclude bulk order codes and other discount codes.
  def options_for_select
    opts = ""
    Product.find(:all,
                 :conditions => ['includeable_in_promotions = ?', true],
    :order => 'id').each {|prod|
      opts += "<option value='#{prod.id}'"
      #      opts += " selected='selected'" if user.has_event?(role.name)
      opts += " selected='selected'" if self.products.include?(prod)
      opts += ">#{prod.name}</option>"
    }
    #    logger.info(opts.inspect)
    return opts
  end
  
  protected
  
  def get_promo_products_in_cart(cart)
    promo_products = []
    cart.items.each do |item|
      promo_products << item if self.products.include?(item.product)
    end
    return promo_products
  end
  
  
  def get_discountable_sub_total(cart)
    discountable_subtotal = 0.0
    promo_products = self.get_promo_products_in_cart(cart)
    if products.length > 0 # Only includeable_in_promotions items are in this collection.
      promo_products.each {|item| discountable_subtotal += item.unit_price * item.quantity }
    else
      cart.items.each do |item| 
        if item.product.includeable_in_promotions 
          #Only include products that are includeable_in_promotions.
          #For example, this will exclude any "DSC-" products, Bulk or Brochures if that bit is false.
          discountable_subtotal += item.unit_price * item.quantity
        end
      end
    end
    return discountable_subtotal
  end
  
end
