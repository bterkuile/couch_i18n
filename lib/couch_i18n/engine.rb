require 'i18n'
module CouchI18n
  class Engine < ::Rails::Engine
    isolate_namespace CouchI18n
    initializer 'couch_i18n.cmtool', after: 'cmtool.build_menu' do
      if defined? Cmtool
        require 'cmtool'
        require 'couch_i18n/translation'

        Cmtool::Menu.register do
          append_to :site do
            resource_link CouchI18n::Translation, label: :couch_i18n
          end
        end
      end
    end
  end
end
