# XBRL

XBRL地獄をパースするためのライブラリ。

## インストール
    $ gem install specific_install
    $ gem install https://github.com/mokos/xbrl

## 使い方

require 'xbrl/parser'

x = XBRL::Parser::get_sbrl(xbrl_text)
puts s.facts
puts s.contexts
