require_relative 'context'
require_relative 'value'

module XBRL

  class Fact
    attr_reader :context, :name, :kind

    def initialize(context, name, value)
      @context = context
      @name = name
      @value = value
    end

    def to_s
      "#{@context} : #{@name} => #{value}"
    end

    def kind
      @value.kind
    end

    def value
      if @value.class==NonNumeric
        return @value.value
      end
      if @value.class==NonFraction
        return @value.value
      end

      nil
    end

    def text_value
      @value.text
    end

    def inspect
      to_s
    end

  end

end
