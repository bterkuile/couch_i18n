module CouchI18n
  module ApplicationHelper
    def title(msg)
       content_for :title do
         msg
       end
    end

    def partfinder?
      params[:partfinder].present?
    end

    def valuefinder?
      params[:valuefinder].present?
    end

    def link_to_new_content(obj)
      t('couch_i18n.action.new.label')
    end
    def link_to_edit_content(obj = nil)
      t('couch_i18n.action.edit.label')
    end
    def link_to_show_content(obj = nil)
      t('couch_i18n.action.show.label')
    end
    def link_to_index_content(singular_name)
      t('couch_i18n.action.index.label')
    end
    def link_to_destroy_content(obj = nil)
      t('couch_i18n.action.destroy.label')
    end
    def update_button_text(obj = nil)
      t('couch_i18n.action.update.button_text')
    end
    def create_button_text(obj = nil)
      t('couch_i18n.action.create.button_text')
    end
    def boolean_show(truefalse)
      truefalse ? t('couch_i18n.general.boolean_true') : t('couch_i18n.general.boolean_false')
    end
    def are_you_sure(obj = nil)
      t('couch_i18n.general.are_you_sure')
    end
  end
end
