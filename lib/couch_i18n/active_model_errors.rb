# This file overwrites the default activemode error message lookup behaviour.

module ActiveModel
  class Errors

    # The code for this method is base on rails revision: f3531a8fc9f661f96759f0a851540745876e5d6c
    # The error lookup now consists of:
    # namespace.errors.messages
    def generate_message(attribute, type = :invalid, options = {})
      type = options.delete(:message) if options[:message].is_a?(Symbol)

      value = (attribute != :base ? @base.send(:read_attribute_for_validation, attribute) : nil)

      # Create key. Remove class in model name and add errors.messages
      key = (@base.class.model_name.underscore.sub(/\w+$/, '').scan(/\w+/) + ['errors.messages', type]).join('.')

      options = {
        :model => @base.class.model_name.human,
        :attribute => @base.class.human_attribute_name(attribute),
        :value => value
      }.merge(options)

      I18n.translate(key, options)
    end

    def full_messages
      map { |attribute, message| full_message(attribute, message) }
    end

    def full_message(attribute, message)
      return message if attribute == :base
      attr_name = attribute.to_s.gsub('.', '_').humanize
      attr_name = @base.class.human_attribute_name(attribute, :default => attr_name)

      # Create key. Remove class in model name and add errors.messages
      key = (@base.class.model_name.underscore.sub(/\w+$/, '').scan(/\w+/) + ['errors.conjunction.attribute_message']).join('.')
      I18n.t(key, {
        :default   => "%{attribute} %{message}",
        :attribute => attr_name,
        :message   => message
      })
    end
  end
end
