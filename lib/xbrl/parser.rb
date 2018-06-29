#!ruby -Ku
# coding: utf-8

require_relative 'xbrl.rb'
require_relative 'fact.rb'

require 'nokogiri'
require 'date'
require 'open-uri'
require 'kconv'

module XBRL

  class Parser
    def self.read_xbrl_zip(xbrl_zip)
      read_xbrl(get_xbrl_file(xbrl_zip))
    end

    def self.read_xbrl_zip_url(xbrl_zip_url)
      read_xbrl_zip(open(xbrl_zip_url).read)
    end

    def self.read_xbrl_htmls(xbrl_htmls)
      self.read_xbrl(
        xbrl_htmls.map do |html|
          html.gsub(/<\/?html>/, '')
        end.join('')
      )
    end

    def self.delete_needless_str!(xbrl_text)
      needless_tags = %w(style width height)
      needless_tags.each do |tag|
        xbrl_text.scan(/(\s+#{tag}="[^"]*")/m).each do |m|
          xbrl_text.gsub!(m.first.to_s, '')
        end
      end
      xbrl_text.gsub!(/<\/?span>/, '')
    end

    def self.read_xbrl(xbrl_text)
      # 不要な文字列を削除しread_xbrl_docで読み込む
      xbrl_text = xbrl_text.toutf8

      doc = Nokogiri::XML.parse(xbrl_text)
      doc.remove_namespaces!

      # delete style tag
      doc.search('style').each do |style|
        style.remove
      end

      self.read_xbrl_doc(doc)
    end


    private

    def self.search_xbrl_file(xbrl_zip_data)
      Dir.mktmpdir {|dir|
        Dir.chdir(dir) {

          File.open('tmp.zip', 'wb+') {|f|
            f.puts xbrl_zip_data
          }
          `unzip tmp.zip`

          # EDINET
          # AuditDocは監査報告書なので不要
          Dir.glob('./**/PublicDoc/*.xbrl').each do |f|
            return File.open(f).read
          end

          Dir.glob('./**/Summary/*.xbrl').each do |f|
            return File.open(f).read
          end
          Dir.glob('./**/Summary/*ixbrl.htm').each do |f|
            return File.open(f).read
          end

          Dir.glob('./**/*.xbrl').each do |f|
            return File.open(f).read
          end

          if (w=Dir.glob('./**/*ixbrl.htm')).size>0
            res = w.map do |f|
              doc = Nokogiri::HTML.parse(File.open(f, 'r').read)
              doc.at('body').inner_html
            end.join
            return "<html><body>#{res}</body></html>"
          end

        }
      }

      nil
    end

    def self.read_xbrl_doc(nokogiri_doc)
      # xbrlパーサ本体
      doc = nokogiri_doc

      facts = []
      contexts = {}
      value_kinds = {}

      doc.search('context').each do |c|
        contexts[c['id']] = Context.new(c)
      end

      doc.search('unit').each do |u|
        value_kinds[u['id']] = 
          if u['divide']
            'Fraction'
          else
            case u['measure']
            when 'JPY', 'NumberOfCompanies', 'Shares', 'Pure'
              'nonFraction'
            when nil
              'nonNumeric'
            else
              raise 'no unit'
            end
          end
      end

      if doc.at('nonFraction') # ixbrl.html file
        %w(fraction nonFraction nonNumeric).each do |value_kind|
          doc.search(value_kind).each do |a|
            context = contexts[a['contextRef']]
            unless context
              puts a['contextRef']
              raise 'no context'
            end
            name = a['name'] #.gsub(/^tse-ed-t:/, '')
            value = Value.make(a, value_kind)
            facts << Fact.new(context, name, value)
          end
        end
      else # .xbrl file
        doc.search('*').each do |tag|
          if context_name = tag['contextRef']
            context = contexts[context_name]
            name = tag.name
            value_kind = value_kinds[tag['unitRef']]
            value = Value.make(tag, value_kind)
            facts << Fact.new(context, name, value)
          end
        end
      end

      File.open(File.dirname(__FILE__)+'/tmp.xbrl', 'w+').puts doc

      XBRL.new(facts)
    end
  end

end
