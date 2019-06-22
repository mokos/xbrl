#!ruby -Ku
# coding: utf-8

require 'bigdecimal'

module XBRL

  class Value
    attr_reader :value, :text, :kind

    def initialize(doc, kind)
      @doc = doc
      @unit_ref = doc['unitRef']
      @text = doc.text
      @kind = kind
    end

    def self.make(doc, kind)
      case kind
      when 'nonFraction'
        NonFraction.new(doc, kind)
      when 'fraction', 'Fraction'
        # TODO Fraction class
        NonFraction.new(doc, kind)
      when 'nonNumeric', nil
        NonNumeric.new(doc, kind)
      else
        raise 
      end
    end
  end

  class NonNumeric < Value
    def initialize(doc, kind)
      super(doc, kind)

      # 参照 決算単身サマリー報告書インスタンス作成要領
      if w=doc.attribute('format')
        case w.text
        when /booleantrue/
          @value = 'true'
        when /booleanfalse/
          @value = 'false'
        else
          # do nothing
        end
      else
        @value = doc.text.strip
      end
    end
  end

  class NonFraction < Value
    # ref. http://www.fsa.go.jp/search/20130118/02_b1.pdf
    # 報告書インスタンス作成ガイドライン

    def initialize(doc, kind)
      super(doc, kind)

      v = doc.text.gsub(',', '')
      if v=='' or doc['nil']
        @value = nil
      else
        case v
        when /(\d+)円(\d+)銭/
          v = BigDecimal("#{$1}.%02d" % $2.to_i)
        else
          v = BigDecimal(v)
        end

        if w=doc['scale']
          v *= 10**w.to_i
        end
        if w=doc['sign'] and w=='-'
          v *= -1
        end

        @value = v
      end
    end
  end

end
