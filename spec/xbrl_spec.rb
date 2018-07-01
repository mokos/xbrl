#!ruby -Ku
# coding: utf-8

require 'xbrl'
require 'open-uri'

RSpec.describe XBRL do
  it "has a version number" do
    expect(XBRL::VERSION).not_to be nil
  end

  it 'read TDnet XBRL(ixbrl.htm)' do
    url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2018050900106/2018/5/9/081220180312488206/XBRLData/Summary/tse-acedussm-72030-20180312488206-ixbrl.htm'
    doc = open(url).read
    x = XBRL::XBRL.from_xbrl(doc)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    current_result_x = x.select_current.select_result
    sales = current_result_x['NetSalesUS']
    expect(sales).to eq 29379510000000
  end

  it 'read TDnet XBRL from zip' do
    url = 'http://resource.ufocatch.com/data/tdnet/TD2018050900106'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    company_name = x['CompanyName']
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x['NetSalesUS', context_name: /Current/]
    expect(sales).to eq 29379510000000
  end

  it 'read old TDnet XBRL' do
    url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2008080700103/2008/8/7/081220080710060067/tdnet-qcedussm-72030-20080710060067.xbrl'
    doc = open(url).read
    x = XBRL::XBRL.from_xbrl(doc)

    company_name = x.get_fact('CompanyName').value
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x['NetSalesUS', context_name: /Current/]
    expect(sales).to eq 6215130000000
  end

  it 'read old tdnet XBRL from zip' do
    url = 'http://resource.ufocatch.com/data/tdnet/TD2008080700103'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    company_name = x['CompanyName']
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x['NetSalesUS', context_name: /Current/]
    expect(sales).to eq 6215130000000
  end

  it 'read EDINET XBRL from zip' do 
    url = 'http://resource.ufocatch.com/data/edinet/ED2018062500789'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    sales = x[/RevenuesUS/, context_name: /Current/]
    expect(sales).to eq 29379510000000
  end

  it 'raise if multi facts' do
    url = 'http://resource.ufocatch.com/data/edinet/ED2018062500789'
    zip = open(url).read
    x = XBRL::XBRL.from_zip(zip)

    expect{ x[/RevenuesUS/] }.to raise_error RuntimeError
  end

  it 'read labelname' do
    url = 'http://resource.ufocatch.com/data/tdnet/TD2018050900106'
    zip = open(url).read
    x = XBRL::XBRL.from_zip_with_labelname(zip)

    company_name = x['CompanyName']
    expect(company_name).to eq 'トヨタ自動車株式会社'

    sales = x[labelname: '売上高', context_name: /Current/]
    expect(sales).to eq 29379510000000
  end
end
