class ApplicationController < ActionController::Base
  protect_from_forgery

  private

  def authorize_cmtool
    redirect_to main_app.new_user_session_path unless current_user.present?
  end
end
