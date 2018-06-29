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
end
