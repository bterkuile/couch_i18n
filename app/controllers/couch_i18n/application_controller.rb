module CouchI18n
  class ApplicationController < ActionController::Base
    before_filter :authorize_user
    layout 'couch_i18n/application'

    private

    def authorize_user
      if respond_to?(:authorize_couch_i18n)
        authorize_couch_i18n
      elsif respond_to?(:current_user) && current_user.present? && current_user.respond_to?(:is_admin) && !current_user.is_admin.present?
        redirect_to '/', :alert => I18n.t('couch_i18n.general.not_authorized')
      end
    end
  end
end
