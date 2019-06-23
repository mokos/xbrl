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
        when /dateerayearmonthdayj/
          d = doc.text.gsub(/<[^>]+>/, '')
          @value = jpdate2date d
        else
          raise
          # do nothing
        end
      else
        @value = doc.text.strip
      end
    end
    
    def jpdate2date jpdate
      jpdate.tr!('０-９', '0-9')
      unless jpdate.match(/^(..)((\d+)|元)年(\d+)月(\d+)日$/)
        raise "jp date parse error: #{jpdate}"
      end

      gengou = $1
      m = $4.to_i
      d = $5.to_i
      y = $2.gsub('元', '1').to_i

      case gengou
      when '昭和'
        y += 1925
      when '平成'
        y += 1988
      when '令和'
        y += 2018
      else
        raise 'gengou must heisei, reiwa'
      end

      Date.new(y, m, d)
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
