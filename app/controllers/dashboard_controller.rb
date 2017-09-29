class DashboardController < ApplicationController
  def index
    @harambees = UserHarambee.where(user_id:current_user.id)
  end
end
