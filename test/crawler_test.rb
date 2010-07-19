#!/usr/bin/ruby
# -*- coding: utf-8 -*-

$: << File.dirname(File.expand_path($PROGRAM_NAME)) + "/../lib/"

require 'test/unit'
require 'fileutils'
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
    # テスト用ディレクトリ作成
    FileUtils.mkdir(@temp_parent_dir)
  end

  # 各テストメソッドが呼ばれた後に呼ばれるメソッド
  def teardown
    # テスト用ディレクトリ削除
    FileUtils.rm_r(@temp_parent_dir)
  end

  #============ 正常系テスト ============#

  # セッションIDの取得
  def test_ok_session_id
    assert_match(/^[a-z0-9]{32}$/, @crawler.session_id)
  end

  # 画像URLを取得
  def test_ok_pic_data
    # 配列でURLのリストを取得できること
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
  end

  # 画像保存Server名の数値が一桁の場合に画像を取得できること
  # 例：http://img3.pixiv.net/img/xxx/111111.jpg
  def test_ok_pic_data_fixed_servername
    # 画像サーバの名前がimg\d{1}(削除等で変更される可能性あり)
    url = "http://img1.pixiv.net/img/lunatic-joker/11899522.jpg"
    fixed_url = "http://img01.pixiv.net/img/lunatic-joker/11899522.jpg"
    urls = [url]

    # 画像を保存
    @crawler.save_pic(urls)

    # 保存した画像が存在するかどうか
    savepath = Pathname.new(@temp_parent_dir + "/" + File.basename(fixed_url))
    assert(HotPixiv::Util.file?(savepath))
  end

  # ページに分かれている画像を取得できること(漫画)
  def test_ok_pic_data_with_page
    # ページに分かれているURL(削除等で変更される可能性あり)
    url = "http://img50.pixiv.net/img/motimiyahotti/11924998.jpg"
    url_with_page = "http://img50.pixiv.net/img/motimiyahotti/11924998_p0.jpg"
    urls = [url]

    # 画像を保存
    @crawler.save_pic(urls)

    # 保存した画像が存在するかどうか
    savepath = Pathname.new(@temp_parent_dir + "/" + File.basename(url_with_page))
    assert(HotPixiv::Util.file?(savepath))
  end

  #============ 異常系テスト ============#


end