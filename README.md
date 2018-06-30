# XBRL

XBRL地獄をパースするためのライブラリ。

## インストール
    $ gem install specific_install
    $ gem specific_install https://github.com/mokos/xbrl

## 使い方

UfoCatcherから取ってきたXBRLファイル(ixbrl.htm)を読み込みます。


```ruby
require 'open-uri'
require 'xbrl/xbrl'
url = 'http://resource.ufocatch.com/xbrl/tdnet/TD2018050900106/2018/5/9/081220180312488206/XBRLData/Summary/tse-acedussm-72030-20180312488206-ixbrl.htm'
doc = open(url).read
x = XBRL::XBRL.from_xbrl(doc)
puts x.contexts
puts x.facts
```
