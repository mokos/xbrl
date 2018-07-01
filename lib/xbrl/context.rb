#!ruby -Ku
# coding: utf-8

module XBRL

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
      when /_CurrentMember_/, /Current[a-zA-Z].*(Duration|Instant)/
        true
      else
        false
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
