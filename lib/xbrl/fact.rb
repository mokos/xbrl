require_relative 'value.rb'

module XBRL

  class Fact
    attr_reader :context, :name

    def initialize(context, name, value)
      @context = context
      @name = name
      @value = value
    end

    def to_s
      "#{@context} : #{@name} => #{value}"
    end

    def kind
      @value.class
    end

    def value
      text_value or numeric_value
    end

    def text_value
      if @value.class==NonNumeric
        @value.value
      else
        nil
      end
    end

    def numeric_value
      if @value.class==NonFraction
        @value.value
      else
        nil
      end
    end

    def inspect
      to_s
    end

  end

end
