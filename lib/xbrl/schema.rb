require 'open-uri'
require 'nokogiri'

module XBRL

  class Schema
    def self.read(url)
      doc = open(url).read
      doc = Nokogiri::XML.parse(doc)
      doc.remove_namespaces!

      p doc.search('import')
    end
  end
end

if __FILE__ == $0
  XBRL::Schema.read('http://disclosure.edinet-fsa.go.jp/taxonomy/jpcrp/2018-02-28/jpcrp_cor_2018-02-28.xsd')
end

