#!/usr/bin/ruby
require 'test/unit'
require 'hotpixiv'

class UtilTest < Test::Unit::TestCase
  # 各テストメソッドが呼ばれる前に呼ばれるメソッド
  def setup
    # テスト用親ディレクトリ
    @temp_parent_dir = "C:/" + DateTime.now.strftime("%Y%m%d%H%M%S")
    @keyword_dir = "天使ちゃんマジ天使"
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

  # ファイルが存在すること
  def test_ok_file
    # テスト用ディレクトリ作成
    create_dir

    # テスト用のファイル作成
    filepath = @temp_parent_dir + '/dummy.txt'
    f = File.open(filepath, 'w')
    f.close

    assert_equal(Pixiv::Util.file?(filepath), true)

    # テスト用ディレクトリ削除
    delete_dir
  end

  # ディレクトリが存在すること
  def test_ok_directory
    # テスト用ディレクトリ作成
    create_dir

    assert_equal(Pixiv::Util.directory?(@temp_parent_dir), true)

    # テスト用ディレクトリ削除
    delete_dir
  end

  # 日付ディレクトリを生成できること
  def test_ok_create_dir_by_date
    # テスト用ディレクトリ作成
    create_dir

    # 日付のディレクトリを作成
    t = DateTime.now
    child_dir = t.strftime("%Y%m%d")
    assert_equal(
      Pixiv::Util.create_dir(@temp_parent_dir, child_dir),
      true
    )

    # テスト用ディレクトリ削除
    delete_dir
  end

  # キーワード名(日本語を含む)のディレクトリを生成できること
  def test_ok_create_dir_by_keyword
    # テスト用ディレクトリ作成
    create_dir

    # 日本語を含むディレクトリを作成
    assert_equal(
      Pixiv::Util.create_dir(@temp_parent_dir, @keyword_dir),
      true
    )

    # テスト用ディレクトリ削除
    delete_dir
  end

  # キーワードを改行区切りしたテキストを読み込んで配列で取得できること
  def test_ok_read_keywords
    # テスト用ディレクトリ作成
    create_dir

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
    data = Pixiv::Util.read_text(filepath)
    assert_not_equal(data.length, 0)

    # テスト用ディレクトリ削除
    delete_dir
  end

  #============ 異常系テスト ============#

  # ディレクトリを生成(ディレクトリ名は日本語含む場合でテスト)できないこと
  def test_ng_create_dir_by_keyword
    # 親ディレクトリが存在しない場合
    assert_equal(
      Pixiv::Util.create_dir(@temp_parent_dir, @keyword_dir),
      false
    )

    # 親ディレクトリが存在する場合かつディレクトリが既に存在する場合
    # テスト用ディレクトリ作成
    create_dir

    Pixiv::Util.create_dir(@temp_parent_dir, @keyword_dir)
    assert_equal(
      Pixiv::Util.create_dir(@temp_parent_dir, @keyword_dir),
      false
    )

    # テスト用ディレクトリ削除
    delete_dir
  end

  # キーワードを改行区切りしたテキストを読み込んで配列で取得できないこと
  # テキストは存在するがデータがない場合
  def test_ng_read_keywords
    # テスト用ディレクトリ作成
    create_dir

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
    data = Pixiv::Util.read_text(filepath)
    assert_equal(data.length, 0)

    # テスト用ディレクトリ削除
    delete_dir
  end
end