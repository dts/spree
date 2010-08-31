# Handles checkout logic.  This is somewhat contrary to standard REST convention since there is not actually a
# Checkout object.  There's enough distinct logic specific to checkout which has nothing to do with updating an
# order that this approach is waranted.
class CheckoutController < Spree::BaseController

  before_filter :load_order

  # Updates the order and advances to the next state (when possible.)
  def update
    if @order.update_attributes(object_params)
      if @order.can_next? and @order.next
        redirect_to checkout_state_path(@order.state) and return
      end
    end
    render :edit
  end

  private

  def object_params
    # For payment step, filter order parameters to produce the expected nested attributes for a single payment and its source, discarding attributes for payment methods other than the one selected
    if @order.payment?
      if params[:payment_source].present? && source_params = params.delete(:payment_source)[params[:order][:payments_attributes].first[:payment_method_id].underscore]
        params[:order][:payments_attributes].first[:source_attributes] = source_params
      end
      if (params[:order][:payments_attributes])
        params[:order][:payments_attributes].first[:amount] = @order.total
      end
    end
    params[:order]
  end

  def load_order
    @order = current_order
    redirect_to cart_path and return unless @order and @order.checkout_allowed?
    if @order.complete?
      session[:order_id] = nil
      unless params[:state] == 'complete'
        redirect_to cart_path and return
      end
    end
    @order.state = params[:state] if params[:state]
    state_callback(:before)
  end

  def state_callback(before_or_after = :before)
    method_name = :"#{before_or_after}_#{@order.state}"
    send(method_name) if respond_to?(method_name, true)
  end

  def before_payment
    current_order.payments.destroy_all if request.put?
  end

  def before_address
    @order.bill_address ||= Address.new(:country => default_country)
    @order.ship_address ||= Address.new(:country => default_country)
  end

  def default_country
    Country.find Spree::Config[:default_country_id]
  end

end