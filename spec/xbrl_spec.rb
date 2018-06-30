require 'xbrl/parser'

RSpec.describe XBRL do
  it "has a version number" do
    expect(XBRL::VERSION).not_to be nil
  end

  it "read XBRL file and contexts exist" do
    filepath = File.dirname(__FILE__)+'/test.xbrl' 
    xbrltext = File.open(filepath).read
    res = XBRL::Parser.read_xbrl(xbrltext)
    res.contexts.size
    expect(res.contexts.size).not_to be 0
  end

  it 'open XBRL from ufocatcher' do
    require 'open-uri'
    url = 'http://resource.ufocatch.com/data/tdnet/TD2018050900106'
    open(url)
  end
  it 'open ixbrl.htm from ufocatcher' do
    require 'open-uri'
    url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2018050900106/2018/5/9/081220180312488206/XBRLData/Summary/tse-acedussm-72030-20180312488206-ixbrl.htm'
    doc = open(url).read
    x = XBRL::XBRL.from_xbrl(doc)
    puts x.contexts
    puts x.facts
  end
end
