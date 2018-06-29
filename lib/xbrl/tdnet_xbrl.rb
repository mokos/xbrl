#!ruby -Ku
# coding: utf-8

require_relative 'xbrl.rb'

module XBRL

  class TdnetXBRL < XBRL

    def self.income_regexes_of_accounting_standard

      {
        IFRS: {
          net_sales: /((Net)?Sales|Revenue)IFRS/,
          operating_income: /OperatingIncomeIFRS/,
          ordinary_income: /ProfitBeforeTaxIFRS/,
          net_income: /ProfitAttributableToOwnersOfParentIFRS/,
        },
        US: {
          net_sales: /(NetSales(AndOperatingRevenues)?|Revenues|OperatingRevenues(Specific)?|TotalRevenues(AfterDeductingFinancialExpense)?)US/,
          operating_income: /OperatingIncome(US)?/,
          ordinary_income: /Income(FromContinuingOperations)?BeforeIncomeTaxesUS/,
          net_income: /NetIncomeUS/,
        },
        JP: {
          net_sales: /NetSales|OperatingRevenues(SE|Specific)?|OrdinaryRevenues(BK|IN)|NetSalesOfCompletedConstructionContracts|NetPremiumsWrittenIN|NetSalesAndOperatingRevenues|GrossOperatingRevenues/,
          operating_income: /OperatingIncome/,
          ordinary_income: /OrdinaryIncome/,
          net_income: /NetIncome|Profit(Loss)?AttributableToOwnersOfParent/,
        }
      }
    end


    def self.get_income_regexes(income_symbol)
      Regexp.union(
        self.income_regexes_of_accounting_standard.values.map do |hs|
          hs[income_symbol]
        end
      )
    end

    def self.get_income_change_regexes(income_symbol)
      /ChangeIn#{self.get_income_regexes(income_symbol)}/
    end

    def get_income_contexts
      get_facts(self.class.get_income_regexes(:net_sales)).map {|fact|
        fact.context
      }.sort.uniq
    end

  end

end
