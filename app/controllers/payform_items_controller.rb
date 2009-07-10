class PayformItemsController < ApplicationController
  layout 'payforms'
  helper 'payforms'
  
  def new
    @payform = Payform.find(params[:payform_id])
    @payform_item = PayformItem.new
  end

  def create
    get_hours
    @payform_item = PayformItem.new(params[:payform_item])
    @payform = Payform.find(params[:payform_id])
    @payform_item.payform = @payform
    if @payform_item.save
      flash[:notice] = "Successfully created payform item."
      redirect_to @payform
    else
      render :action => 'new'
    end
  end

  def edit
    @payform_item = PayformItem.find(params[:id])
    @payform = @payform_item.payform
  end

  def update
    get_hours
    @payform_item = PayformItem.new(params[:payform_item])
    @payform_item.parent = PayformItem.find(params[:id])
    @payform = @payform_item.payform = @payform_item.parent.payform
    @payform_item.parent.payform = nil  # this line caused headache!
    @payform_item.source = current_user.name
    errors = []
    if !@payform_item.parent.save
      errors << "Failed to update the old payform item"
    end
    if !@payform_item.save
      errors << "Failed to create a new payform item"
    end
    if errors.length == 0
      if @payform_item.user == current_user  # just for testing; should be != instead
        AppMailer.deliver_payform_item_change_notification(@payform_item.parent, @payform_item)
      end
        flash[:notice] = "Successfully edited payform item."
        redirect_to @payform_item.payform    
    else
      flash[:error] =  "Error: "+errors*"<br/>" 
      render :action => 'edit'
    end
  end

  def destroy
    @payform_item = PayformItem.find(params[:id])
    @payform = @payform_item.payform
    @payform_item.active = false
    @payform_item.source = current_user.name
    if @payform_item.payform.user_id == current_user.id  # just for testing; should be != instead
      AppMailer.deliver_payform_item_change_notification(@payform_item)
    end
    if @payform_item.save
      flash[:notice] = "Payform item deleted."
    else
      flash[:notice] = "Error deleting payform item."
    end
    redirect_to @payform
  end
  
  protected
  
  def get_hours
    if params[:calculate_hours] == 'user_input'
        params[:payform_item][:hours] = params[:other][:hours].to_f + params[:other][:minutes].to_f/60
    else
      params[:payform_item][:hours] = 100
    end
  end
end

