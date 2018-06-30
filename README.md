# XBRL

XBRL地獄をパースするためのRubyライブラリ。
TDNetの新旧仕様、EDINETのXBRLに(おそらく)対応しています。

## インストール
    $ gem install specific_install
    $ gem specific_install https://github.com/mokos/xbrl

## 使い方

UfoCatcherから取ってきたXBRLファイル(ixbrl.htm)を読み込みます。


```ruby
require 'open-uri'
require 'xbrl/xbrl'

# トヨタ自動車 2018年3月期4Q決算短信のXBRL
url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2018050900106/2018/5/9/081220180312488206/XBRLData/Summary/tse-acedussm-72030-20180312488206-ixbrl.htm'
doc = open(url).read
x = XBRL::XBRL.from_xbrl(doc)

puts x.contexts
puts x.facts

company_name = x.get_fact('CompanyName').value
puts company_name # トヨタ自動車株式会社

sales = x.get_fact('NetSalesUS', context_name: /Current/).value
puts sales # 29379510000000
```

zipファイルから直接読むこともできます。
```ruby
require 'open-uri'
require 'xbrl/xbrl'

# トヨタ自動車 2018年3月期4Q決算短信のXBRL zipファイル
url = 'http://resource.ufocatch.com/data/tdnet/TD2018050900106'
zip = open(url).read
x = XBRL::XBRL.from_zip(zip)

puts x.contexts
puts x.facts

company_name = x.get_fact('CompanyName').value
puts company_name # トヨタ自動車株式会社

sales = x.get_fact('NetSalesUS', context_name: /Current/).value
puts sales # 29379510000000
```

EDINET
```ruby
url = 'http://resource.ufocatch.com/data/edinet/ED2018062500789'
zip = open(url).read
x = XBRL::XBRL.from_zip(zip)

puts x.facts

sales = x.get_fact(/RevenuesUS/, context_name: /Current/).value
puts sales # 29379510000000
```
