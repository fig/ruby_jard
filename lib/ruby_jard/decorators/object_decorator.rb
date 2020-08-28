# frozen_string_literal: true

module RubyJard
  class ObjectDecorator
    OBJECT_ADDRESS_PATTERN = /#<(.*)(:0x[0-9]+.*)>/i.freeze

    def initialize(general_decorator)
      @general_decorator = general_decorator
    end

    def decorate_singleline(variable, line_limit:)
      object_address = variable.to_s
      match = object_address.match(OBJECT_ADDRESS_PATTERN)
      if match
        detail =
          if match[2].length < line_limit - match[1].length - 3
            match[2]
          else
            match[2][0..line_limit - match[1].length - 4] + '…'
          end
        [
          RubyJard::Span.new(content: '#<', styles: :text_secondary),
          RubyJard::Span.new(content: match[1], styles: :text_secondary),
          RubyJard::Span.new(content: detail, styles: :text_secondary),
          RubyJard::Span.new(content: '>', styles: :text_secondary)
        ]
      elsif object_address.length <= line_limit
        [
          RubyJard::Span.new(
            content: object_address[0..line_limit],
            styles: :text_secondary
          )
        ]
      else
        [
          RubyJard::Span.new(
            content: object_address[0..line_limit - 3] + '…>',
            styles: :text_secondary
          )
        ]
      end
    end

    def decorate_multiline(variable, first_line_limit:, lines:, line_limit:)
      spans = [decorate_singleline(variable, line_limit: first_line_limit)]

      return spans if !variable.respond_to?(:instance_variables) ||
                      !variable.respond_to?(:instance_variable_get)

      item_count = 0
      variable.instance_variables.each do |instance_variable|
        spans << (
          [
            RubyJard::Span.new(content: '▸', margin_right: 1, margin_left: 2, styles: :text_dim),
            RubyJard::Span.new(content: instance_variable.to_s, margin_right: 1, styles: :text_secondary),
            RubyJard::Span.new(content: '=', margin_right: 1, styles: :text_secondary)
          ] + @general_decorator.decorate_singleline(
            variable.instance_variable_get(instance_variable),
            line_limit: line_limit - instance_variable.to_s.length - 7
          )
        )

        item_count += 1
        break if item_count >= lines - 2
      end

      if variable.instance_variables.length > item_count
        spans << [
          RubyJard::Span.new(
            content: "▸ #{variable.instance_variables.length - item_count} more...",
            margin_left: 2, styles: :text_dim
          )
        ]
      end

      spans
    end
  end
end
