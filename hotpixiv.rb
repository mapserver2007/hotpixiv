require 'open-uri'
require 'cgi'
require 'kconv'
require 'nkf'
require 'optparse'
require 'pathname'
require 'date'

module Pixiv
  module Util
    def self.read_text(path)
      data = []
      if file?(path)
        open(path) do |f|
          while line = f.gets do
            data << line.chomp unless line.chomp.empty?
          end
        end
      end
      data
    end

    def self.file?(e)
      !!(FileTest.exist?(e) rescue nil)
    end

    def self.directory?(e)
      !!(FileTest::directory?(e) rescue nil)
    end

    def self.create_dir(parent, child)
      # Windows用にディレクトリ名はShift_JISにする
      parent = parent.tosjis
      child = tosjis(child)

      # 親ディレクトリが存在しない場合
      return false unless directory?(parent)

      path = Pathname.new(parent + "/" + child)
      pathname = path.cleanpath

      # すでにディレクトリがある場合
      return false if directory?(pathname)

      # ディレクトリの生成
      begin
        Dir::mkdir(pathname)
        true
      rescue => e
        puts e.message
        false
      end
    end

    def self.tosjis(s)
      if (RUBY_VERSION < "1.9")
        return NKF::nkf('-Wsm0', s)
      else
        return s.encode("Shift_JIS")
      end
    end
  end

  class Crawler
    PIXIV_API = 'http://iphone.pxv.jp/iphone/'
    REFERER = 'http://www.pixiv.net/'
    USER_AGENT = 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us)
      AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16'
    PAGE = 20

    def initialize(config)
      @config = config
    end

    def session_id
      php_session_id = nil
      begin
        url = "#{PIXIV_API}login.php?mode=login&pixiv_id=&pass=&skip=0"
        open(url) do |e|
          cookie = e.meta["set-cookie"]
          re = Regexp.new('PHPSESSID=(.*?);')
          sess_str = cookie.split(/,/)[2]
          php_session_id = re.match(sess_str)[1]
        end
      rescue => e
        puts e.message
      end
      php_session_id
    end

    def pic_data(keyword, p = nil)
      data = []
      page = p || PAGE
      print "Collecting image list: "
      begin
        for i in 1..page
          url = "#{PIXIV_API}search.php?s_mode=s_tag&word="
          url+= "#{CGI.escape(keyword.toutf8)}&PHPSESSID=#{session_id}&p=#{i}"
          open(url) do |f|
            print "."
            f.each_line do |line|
              data << data_parser(line)
            end
          end
        end
        puts ""
        data.compact!
      rescue => e
        puts e.message
      rescue Timeout::Error => e
        puts "[ERROR]\tconnection timeout."
      end
      data
    end

    def trim(e)
      e.gsub(/\"/, "") unless e.nil?
    end

    def data_parser(data)
      e = data.split(/,/)
      # 総合点：e[16], 評価回数：e[15], 閲覧回数：e[17]
      if trim(e[16]).to_i > @config[:point]
        "http://img#{trim(e[4])}.pixiv.net/img/#{trim(e[6]).split(/\//)[4]}/#{trim(e[0])}.#{trim(e[2])}" rescue nil
      end
    end

    def save_pic(urls)
      urls.each do |url|
        filename = File.basename(url)
        filepath = Pathname.new(@config[:dir] + "/" + filename)
        begin
          open(filepath.cleanpath, 'wb') do |output|
            open(url, "Referer" => REFERER) do |f|
              output.write(f.read)
              puts "[OK]\t#{filepath.cleanpath}"
            end
          end
        rescue
          File.unlink(filepath.cleanpath)
          puts "[NG]\t#{filepath.cleanpath}"
        end
      end
    end

    def exec
      begin
        # ディレクトリが存在しなければ終了
        raise "directory not found." unless Pixiv::Util.directory?(@config[:dir])

        # キーワードを取得
        data = Pixiv::Util.read_text(@config[:file_keyword])
        origin_parent = @config[:dir]
        keywords = data.length == 0 ?
          (@config[:keyword].nil? ? [] : [@config[:keyword]]) : data

        # キーワードがなければ終了
        raise "keyword not found." if keywords.length == 0

        keywords.each do |keyword|
          # 日付のディレクトリを作成
          parent = origin_parent
          child = DateTime.now.strftime("%Y%m%d")
          Pixiv::Util.create_dir(parent, child)

          # キーワードのディレクトリを作る
          parent = parent + '/' + child
          child = keyword
          Pixiv::Util.create_dir(parent, child)

          @config[:dir] = parent + '/' + Pixiv::Util.tosjis(child)

          # 画像のURLを取得
          pic_urls = pic_data(keyword, 5)
          # 画像を保存
          save_pic(pic_urls)
        end
      rescue => e
        puts "[ERROR]\t#{e.message}"
      end
    end

  end
end

config = {}
opt = OptionParser.new
opt.on('-k', '--keyword KEYWORD') {|v| config[:keyword] = v}
opt.on('-f', '--file_keyword FILE_KEYWORD') {|v| config[:file_keyword] = v}
opt.on('-p', '--point POINT') {|v| config[:point] = v.to_i}
opt.on('-d', '--directory DIRECTORY') {|v| config[:dir] = v}
opt.parse!

pixiv = Pixiv::Crawler.new(config)
pixiv.exec