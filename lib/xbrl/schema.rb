#!ruby -Ku
# coding: utf-8

require 'open-uri'
require 'nokogiri'

module XBRL

  class Schema
    def self.read_label_from_xsd(xsd_doc)
      doc = Nokogiri::XML.parse(xsd_doc)
      doc.remove_namespaces!

      doc.search('linkbaseRef').each do |ref|
        if ref['role'].match /labelLinkbaseRef$/
          return read_label_linkbase_ref(ref['href'])
        end
      end
    end

    def self.read_label_linkbase_ref(url)
      doc = open(url).read
      doc = Nokogiri::XML.parse(doc)
      doc.remove_namespaces!

      labels = {} 
      doc.search('label').each do |label|
        _, name, num = label['id'].split('_')
        labels[name] ||= []
        labels[name] << label.text
      end

      labels
    end
  end
end


