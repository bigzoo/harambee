class UserHarambeesController < ApplicationController
  # before_action :params, only: [:update, :create]
  def index
    @harambees = UserHarambee.order(:updated_at).page params[:page]
  end
  def show
    @harambee = UserHarambee.find(params[:id])
  end
  def edit
    @harambee = UserHarambee.find(params[:id])
  end
  def new
    @harambee = UserHarambee.new
  end
  def create
    user_id = current_user.id
    user = {'user_id':user_id}
    params = harambee_params.merge(user)
    @harambee = UserHarambee.new(params)
    if @harambee.save
      flash[:notice]='Harambee Created Successfully.'
      redirect_to dashboard_index_path
    else
      flash[:alert]='We\'re sorry but an error occurred.'
      redirect_to dashboard_index_path
    end
  end
  def update
    user_id = current_user.id
    user = {'user_id':user_id}
    params = harambee_params.merge(user)
    @harambee = UserHarambee.find(params[:id])
    if @harambee.update(params)
      flash[:notice]='Harambee updated Successfully!'
      redirect_to dashboard_index_path
    else
      flash[:alert]='Requested updates were not completed Successfully.'
      redirect_to dashboard_index_path
    end
  end
  def destroy
    @harambee = UserHarambee.find(params[:id])
    if @harambee.destroy
      flash[:notice]='Harambee deleted successfully!'
      redirect_to dashboard_index_path
    else
      flash[:alert]='Requested delete was not successfull!'
      redirect_to dashboard_index_path
    end
  end
  private
  def harambee_params
    params.require(:user_harambee).permit(:name,:description,:target_amount,:raised_amount,:phone_no,:deadline)
  end
end
