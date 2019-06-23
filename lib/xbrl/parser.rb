#!ruby -Ku
# coding: utf-8

require_relative 'xbrl'
require_relative 'fact'
require_relative 'schema'

require 'nokogiri'
require 'date'
require 'open-uri'
require 'kconv'
require 'tmpdir'

module XBRL

  class Parser
    def self.read_xbrl_zip(xbrl_zip, labelname: false, xbrl_output_path: nil)
      xbrls, xsds = search_xbrl_files(xbrl_zip)
      xbrl_text = xbrls.first
      if (xbrl_output_path)
        File.open(xbrl_output_path, 'w+').write xbrl_text
      end

      return nil unless xbrl_text

      x = read_xbrl(xbrl_text)
      if labelname
        l = Schema.read_label_from_xsd(xsds.first)
        x.set_labelname(l)
      end
      x
    end

    def self.read_labelname(xbrl_zip)
      xbrls, xsds = search_xbrl_files(xbrl_zip)
      Schema.read_label_from_xsd(xsds.first)
    end

    def self.read_xbrl_htmls(xbrl_htmls)
      self.read_xbrl(
        xbrl_htmls.map do |html|
          html.gsub(/<\/?html>/, '')
        end.join('')
      )
    end

    def self.read_xbrls(xbrls)
    end

    def self.read_xbrl(xbrl_text)
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

    def self.search_xbrl_files(xbrl_zip_data)
      xbrls = []
      xsds = []

      case xbrl_zip_data
      when File
        xbrl_zip_data = xbrl_zip_data.read
      end

      Dir.mktmpdir {|dir|
        Dir.chdir(dir) {

          File.open('tmp.zip', 'wb+') {|f|
            f.write xbrl_zip_data
          }
          `unzip tmp.zip`

          # EDINET
          # AuditDocは監査報告書なので不要
          `rm -rf */AuditDoc`
          [
            './**/PublicDoc/*.xbrl',
            './**/Summary/*.xbrl', 
            './**/Summary/*ixbrl.htm',
            './**/*ixbrl.htm',
            './**/*.xbrl'
          ].each do |pattern|
            Dir.glob(pattern).each do |f|
              xbrls << File.open(f).read
            end
          end

          [
            './**/PublicDoc/*.xsd',
            './**/Summary/*.xsd', 
          ].each do |pattern|
            Dir.glob(pattern).each do |f|
              xsds << File.open(f).read
            end
          end

          # 複数のixbrl.htmを一つのHTMLファイルにする
          if (w=Dir.glob('./**/*ixbrl.htm')).size>0
            res =
              w.map do |f|
                doc = Nokogiri::HTML.parse(File.open(f, 'r').read)
                if doc.at('body')
                  doc.at('body').inner_html
                else
                  nil
                end
              end.compact.join
            xbrls << "<html><body>#{res}</body></html>"
          end

        }
      }

      [xbrls, xsds]
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

      if doc.at('nonFraction') # ixbrl.htm file
        %w(fraction nonFraction nonNumeric).each do |value_kind|
          doc.search(value_kind).each do |tag|
            context = contexts[tag['contextRef']]
            unless context
              raise 'no context'
            end
            name = tag['name'].split(':').last
            value = Value.make(tag, value_kind)
            facts << Fact.new(context, name, value)
          end
        end
      else # .xbrl file

        doc.search('unit').each do |u|
          measure = u.at('measure')
          value_kinds[u['id']] = 
            if u.at('divide')
              'Fraction'
            elsif measure.nil?
              'nonNumeric'
            else
              case measure.text.split(':').last.downcase
              when 'jpy', 'numberofcompanies', 'shares', 'pure', 'nonnegativeinteger'
                'nonFraction'
              else
                STDERR.puts 'no unit'
                'nonNumeric'
              end
            end
        end

        doc.search('*').each do |tag|
          if context_name = tag['contextRef']
            context = contexts[context_name]
            name = tag.name.split(':').last
            value_kind = value_kinds[tag['unitRef']]
            value = Value.make(tag, value_kind)
            facts << Fact.new(context, name, value)
          end
        end
      end

      XBRL.new(facts)
    end
  end

end
