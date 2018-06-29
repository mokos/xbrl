require 'bigdecimal'

module XBRL
  class Value
    attr_reader :value

    def initialize(doc)
      @doc = doc
      @unit_ref = doc['unitRef']
    end

    def self.make(tag, kind)
      case kind
      when 'nonFraction'
        NonFraction.new(tag)
      when 'fraction', 'Fraction'
        raise kind
      when 'nonNumeric', nil
        NonNumeric.new(tag)
      else
        raise 
      end
    end
  end

  class NonNumeric < Value
    def initialize(doc)
      super(doc)

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

    def initialize(doc)
      super(doc)

      v = doc.text.gsub(',', '')
      if v=='' or doc['nil']
        @value = nil
      else
        v = BigDecimal(v)

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

  class Context
    attr_reader :start_date, :end_date, :instant, :name
    def initialize(nokogiri_doc)
      doc = nokogiri_doc
      @start_date = Date.parse(doc.at('period > startDate').text) rescue nil
      @end_date   = Date.parse(doc.at('period > endDate').text) rescue nil
      @instant    = Date.parse(doc.at('period > instant').text) rescue nil

      @name = doc['id']
    end

    def record_date
      @end_date || @instant
    end

    def is_duration?
      @instant.nil?
    end

    def is_instant?
      not is_duration?
    end

    def is_consolidated?
      # Consolidated / Non Consolidated Axis
      case @name
      when /_ConsolidatedMember/
        true
      when /_NonConsolidatedMember/
        false
      when /NonConsolidated/ # for EDINET
        false
      else
        true
      end
    end

    def is_current?
      # Current / Previous Axis
      case @name
      when /_CurrentMember_/
        true
      when /_PreviousMember_/
        false
      else
        true
      end
    end

    def is_result?
      case @name
      when /_ResultMember/
        true
      when /_(Forecast|Upper|Lower)Member/ # Upper と Lower ということは予想
        false
      else
        true
      end
    end

    def to_s
      if is_duration?
        "#{@name} #{@start_date.strftime('%Y/%m/%d')}-#{@end_date.strftime('%Y/%m/%d')}"
      else
        "#{@name}  #{@instant.strftime("%Y/%m/%d")}"
      end
    end

    def <=>(other)
      if self.name==other.name
        0
      else
        self.record_date <=> other.record_date
      end
    end

    def inspect
      to_s
    end

  end
end
