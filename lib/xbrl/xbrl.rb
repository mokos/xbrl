#!ruby -Ku
# coding: utf-8

require 'nokogiri'
require 'date'
require 'open-uri'
require 'kconv'

require_relative 'parser'

module XBRL

  # 連結と単体データがあるときにどちらを優先するか
  PriorCons = 0 #連結優先
  PriorNonCons = 1 #個別優先
  Cons = 2 #連結指定
  NonCons = 3 #個別指定

  class XBRL
    attr_reader :facts
    def initialize(facts, labelname: nil)
      @facts = facts
      @labelname = labelname
    end

    def set_labelname(hs)
      @labelname = hs
    end

    def self.from_zip(zip_data)
      Parser.read_xbrl_zip(zip_data)
    end

    def self.from_zip_with_labelname(zip_data)
      Parser.read_xbrl_zip(zip_data, labelname: true)
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

    def select_current
      filter(is_current: true)
    end

    def select_result
      filter(is_result: true)
    end

    def select_forcast
      filter(is_result: false)
    end

    def select_prior_consolidated
      filter
    end

    def filter(fact_name=nil, context: nil, context_name: nil, start_date: nil, record_date: nil, consolidation_priority: PriorCons, is_current: nil, is_result: nil, labelname: nil)

      fs =
        @facts.select {|fact|
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

          if labelname
            names = @labelname[fact.name]
            if not names.any? {|name|
              case name
              when labelname
                true
              else
                false
              end
            }
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

          unless is_current.nil?
            if is_current
              next unless fact.context.is_current?
            else
              next unless not fact.context.is_current?
            end
          end

          unless is_result.nil?
            if is_result
              next unless fact.context.is_result?
            else
              next unless not fact.context.is_result?
            end
          end

          case consolidation_priority
          when Cons
            next unless fact.context.consolidated?
          when NonCons
            next if fact.context.consolidated?
          end

          next unless fact.value

          true
        }

        case consolidation_priority
        when PriorCons
          fs2 = fs.select {|fact| fact.context.is_consolidated? }
          fs = fs2 if fs2.size>0
        when PriorNonCons
          fs2 = fs.select {|fact| not fact.context.is_consolidated? }
          fs = fs2 if fs2.size>0
        end

      XBRL.new(fs, labelname: @labelname)
    end

    def get_facts(*args)
      self.filter(*args).facts
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
