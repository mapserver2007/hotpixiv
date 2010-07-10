#!/usr/bin/ruby
# -*- coding: utf-8 -*-

HOTPIXIV_ROOT = File.dirname(File.expand_path($PROGRAM_NAME))
$: << HOTPIXIV_ROOT + "/../lib/"

require 'test/unit'
require 'hotpixiv'

class CrawlerTest < Test::Unit::TestCase
  # 各テストメソッドが呼ばれる前に呼ばれるメソッド
  def setup
    @temp_parent_dir = "C:/" + DateTime.now.strftime("%Y%m%d%H%M%S")
    @test_keyword = '天使ちゃんマジ天使'
    @crawler = HotPixiv::Crawler.new({
      :keyword => @test_keyword,
      :point => 1000,
      :dir => @temp_parent_dir
    })
  end

  # テスト用に一時ディレクトリを作成
  def create_dir
    Dir::mkdir(@temp_parent_dir)
  end

  # テスト用の一時ディレクトリを削除(サブディレクトも削除)
  def delete_dir
    delete_dir_all(@temp_parent_dir)
  end

  def delete_dir_all(delthem)
    if FileTest.directory?(delthem)
      Dir.foreach( delthem ) do |file|
        next if /^\.+$/ =~ file
        delete_dir_all(delthem.sub(/\/+$/,"") + "/" + file)
      end
      Dir.rmdir(delthem) rescue ""
    else
      File.delete(delthem)
    end
  end

  #============ 正常系テスト ============#

  # セッションIDの取得
  def test_ok_session_id
    assert_match(/^[a-z0-9]{32}$/, @crawler.session_id)
  end

  # 画像URLを取得
  def test_ok_pic_data
    # テスト用ディレクトリ作成
    create_dir

    # 配列でURLのリストを取得
    urls = @crawler.pic_data(@test_keyword, 1)
    result = false
    unless urls.length == 0
      result = true
      urls.each do |url|
        if /^http?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+/ =~ url
          result & true
        else
          result & false
        end
      end
    end
    assert(result)

    # テスト用ディレクトリ削除
    delete_dir
  end

  #============ 異常系テスト ============#


end