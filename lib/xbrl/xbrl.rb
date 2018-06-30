#!ruby -Ku
# coding: utf-8

require 'nokogiri'
require 'date'
require 'open-uri'
require 'kconv'

require_relative 'parser'

module XBRL

  # 連結と単体データがあるときにどちらを優先するか
  module ConsolidationPriority
    PriorCons = 0 #連結優先
    PriorNonCons = 1 #個別優先
    Cons = 2 #連結指定
    NonCons = 3 #個別指定
  end

  module CurrentPriority
    Current = 0
    Prior = 1
  end

  module ResulstPriority
    Result = 0
    Forecast = 1
  end

  class XBRL
    attr_reader :facts
    def initialize(facts)
      @facts = facts
    end

    def self.from_zip(zip_data)
      Parser.read_xbrl_zip(zip_data)
    end

    def self.from_xbrl(xbrl_text)
      Parser.read_xbrl(xbrl_text)
    end

    def contexts
      @contexts ||= 
        @facts.map {|f|
          f.context
        }.sort.uniq
    end

    def get_context(context_name)
      contexts.each do |c|
        case c.name
        when context_name
          return c
        end
      end

      nil
    end

    def get_fact(*args)
      fs = get_facts(*args)
      return nil if fs.size==0
      raise 'many facts.' if fs.size>1

      fs.first
    end

    def get_facts(fact_name, context: nil, context_name: nil, start_date: nil, record_date: nil, consolidation_priority: ConsolidationPriority::PriorCons)
      res = @facts.select {|fact|
        if fact_name
          case fact.name
          when fact_name
          else
            next
          end
        end

        if context_name
          case fact.context.name
          when context_name
          else
            next
          end
        end

        if context
          next unless fact.context == context
        end

        if record_date
          next unless record_date == fact.context.record_date
        end

        if start_date
          next unless start_date == fact.context.start_date
        end

        case consolidation_priority
        when ConsolidationPriority::Cons
          next unless fact.context.consolidated?
        when ConsolidationPriority::NonCons
          next if fact.context.consolidated?
        end

        next unless fact.value

        true
      }

      case consolidation_priority
      when ConsolidationPriority::PriorCons
        res2 = res.select {|fact| fact.context.is_consolidated? }
        res = res2 if res2.size>0
      when ConsolidationPriority::PriorNonCons
        res2 = res.select {|fact| not fact.context.is_consolidated? }
        res = res2 if res2.size>0
      end

      res
    end

    def to_s
      @facts.to_s
    end

    def [](*args)
      fact = get_fact(*args)

      if fact
        fact.value
      else
        nil
      end
    end
  end

end
