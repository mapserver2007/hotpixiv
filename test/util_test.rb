#!/usr/bin/ruby
# -*- coding: utf-8 -*-

$: << File.dirname(File.expand_path($PROGRAM_NAME)) + "/../lib/"

require 'test/unit'
require 'fileutils'
require 'hotpixiv'

class UtilTest < Test::Unit::TestCase
  # 各テストメソッドが呼ばれる前に呼ばれるメソッド
  def setup
    # テスト用親ディレクトリ
    @temp_parent_dir = "C:/" + DateTime.now.strftime("%Y%m%d%H%M%S")
    @keyword_dir = "天使ちゃんマジ天使"
    @temp_notfound_dir = @temp_parent_dir + '/' + DateTime.now.strftime("%Y%m%d%H%M%S")
    # テスト用ディレクトリ作成
    FileUtils.mkdir(@temp_parent_dir)
  end

  # 各テストメソッドが呼ばれた後に呼ばれるメソッド
  def teardown
    # テスト用ディレクトリ削除
    FileUtils.rm_r(@temp_parent_dir)
  end

  #============ 正常系テスト ============#

  # ファイルが存在すること
  def test_ok_file
    # テスト用のファイル作成
    filepath = @temp_parent_dir + '/dummy.txt'
    f = File.open(filepath, 'w')
    f.close

    assert_equal(HotPixiv::Util.file?(filepath), true)
  end

  # ディレクトリが存在すること
  def test_ok_directory
    assert_equal(HotPixiv::Util.directory?(@temp_parent_dir), true)
  end

  # 日付ディレクトリを生成できること
  def test_ok_create_dir_by_date
    # 日付のディレクトリを作成
    t = DateTime.now
    child_dir = t.strftime("%Y%m%d")
    assert_equal(
      HotPixiv::Util.create_dir(@temp_parent_dir, child_dir),
      true
    )
  end

  # キーワード名(日本語を含む)のディレクトリを生成できること
  def test_ok_create_dir_by_keyword
    # 日本語を含むディレクトリを作成
    assert_equal(
      HotPixiv::Util.create_dir(@temp_parent_dir, @keyword_dir),
      true
    )
  end

  # キーワードを改行区切りしたテキストを読み込んで配列で取得できること
  def test_ok_read_keywords
    # テスト用のファイル作成
    filepath = @temp_parent_dir + '/keywords.txt'
    # テスト用のキーワードを作成
    data = [
      '天使ちゃんマジ天使',
      '伊波まひる',
      '中野梓',
      '', # 空のデータは無視される
      'けいおん'
    ]
    f = File.open(filepath, 'w')
    # データはShift_JISにする
    data.each do |e|
      f.puts e.tosjis
    end
    f.close

    # ファイルを読み込み、データが取得できること
    data = HotPixiv::Util.read_text(filepath)
    assert_not_equal(data.length, 0)
  end

  #============ 異常系テスト ============#

  # ディレクトリを生成(ディレクトリ名は日本語含む場合でテスト)できないこと
  def test_ng_create_dir_by_keyword
    # 親ディレクトリが存在しない場合
    assert_equal(
      HotPixiv::Util.create_dir(@temp_notfound_dir, @keyword_dir),
      false
    )
    # 親ディレクトリが存在する場合かつディレクトリが既に存在する場合
    HotPixiv::Util.create_dir(@temp_parent_dir, @keyword_dir)
    assert_equal(
      HotPixiv::Util.create_dir(@temp_parent_dir, @keyword_dir),
      false
    )
  end

  # キーワードを改行区切りしたテキストを読み込んで配列で取得できないこと
  # テキストは存在するがデータがない場合
  def test_ng_read_keywords
    # テスト用のファイル作成
    filepath = @temp_parent_dir + '/keywords.txt'
    # テスト用のキーワードを作成
    data = [
      '',
      ''
    ]
    f = File.open(filepath, 'w')
    # データはShift_JISにする
    data.each do |e|
      f.puts e.tosjis
    end
    f.close

    # ファイルを読み込み、データが取得できること
    data = HotPixiv::Util.read_text(filepath)
    assert_equal(data.length, 0)
  end
end