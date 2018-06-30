#!ruby -Ku
# coding: utf-8

require 'xbrl'
require 'open-uri'

RSpec.describe XBRL do
  it "has a version number" do
    expect(XBRL::VERSION).not_to be nil
  end

  it 'read XBRL from XBRL zip' do
    url = 'http://resource.ufocatch.com/data/tdnet/TD2018050900106'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x.get_fact('NetSalesUS', context_name: /Current/).value
    expect(sales).to eq 29379510000000
  end

  it 'read ixbrl.htm' do
    url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2018050900106/2018/5/9/081220180312488206/XBRLData/Summary/tse-acedussm-72030-20180312488206-ixbrl.htm'
    doc = open(url).read
    x = XBRL::XBRL.from_xbrl(doc)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x.get_fact('NetSalesUS', context_name: /Current/).value
    expect(sales).to eq 29379510000000
  end

  it 'read old tdnet XBRL' do
    url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2008080700103/2008/8/7/081220080710060067/tdnet-qcedussm-72030-20080710060067.xbrl'
    doc = open(url).read
    x = XBRL::XBRL.from_xbrl(doc)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x.get_fact('NetSalesUS', context_name: /Current/).value
    expect(sales).to eq 6215130000000
  end

  it 'read old tdnet XBRL from XBRL zip' do
    url = 'http://resource.ufocatch.com/data/tdnet/TD2008080700103'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x.get_fact('NetSalesUS', context_name: /Current/).value
    expect(sales).to eq 6215130000000
  end
end
