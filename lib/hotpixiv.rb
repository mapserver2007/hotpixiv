require 'open-uri'
require 'cgi'
require 'kconv'
require 'nkf'
require 'pathname'
require 'date'
require 'timeout'

module HotPixiv
  VERSION = '0.0.2'

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
    TIMEOUT = 10
    PAGE = 20
    POINT = 0

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
      for i in 1..page
        url = "#{PIXIV_API}search.php?s_mode=s_tag&word="
        url+= "#{CGI.escape(keyword.toutf8)}&PHPSESSID=#{session_id}&p=#{i}"
        begin
          timeout(TIMEOUT) do
            open(url) do |f|
              print "."
              f.each_line do |line|
                d = data_parser(line)
                data << d unless d.nil?
              end
            end
          end
        rescue Timeout::Error
          puts ""
          puts "[ERROR]\tconnection timeout."
          next
        end
      end
      puts ""
      data
    end

    def trim(e)
      e.gsub(/\"/, "") unless e.nil?
    end

    def data_parser(data)
      point = @config[:point] || POINT
      e = data.split(/,/)
      # 総合点：e[16], 評価回数：e[15], 閲覧回数：e[17]
      if trim(e[16]).to_i > point
        "http://img#{trim(e[4])}.pixiv.net/img/#{trim(e[6]).split(/\//)[4]}/#{trim(e[0])}.#{trim(e[2])}"
      end
    end

    def save_pic(urls)
      urls.each do |url|
        begin
          save_and_download_pic(url)
          puts "[OK]\t#{@filepath.cleanpath}"
        # マンガの場合
        rescue OpenURI::HTTPError
          begin
            0.upto(0 / 0.0) do |page|
              url_with_page = url.gsub(/(\d*)\.[jpg|png|gif]{3}/) do |matched|
                f = matched.split(/\./)
                "#{f[0]}_p#{page}.#{f[1]}"
              end
              save_and_download_pic(url_with_page)
              puts "[OK]\t#{@filepath.cleanpath}"
            end
          rescue OpenURI::HTTPError
            next
          end
        # ホスト名が違う場合
        rescue SocketError
          begin
            if /^http:\/\/img(\d)./ =~ url
              url.gsub!(/^http?:\/\/img/) do |m| m + "0" end if $1.length == 1
            end
            save_and_download_pic(url)
            puts "[OK]\t#{@filepath.cleanpath}"
          # 画像のダウンロードに失敗した場合
          rescue => e
            puts "[NG]\t#{@filepath.cleanpath}"
            next
          end
        rescue
          File.unlink(@filepath.cleanpath)
          puts "[NG]\t#{@filepath.cleanpath}"
        end
      end
    end

    def save_and_download_pic(url)
      @filepath = Pathname.new(@config[:dir] + "/" + File.basename(url))
      open(url, "Referer" => REFERER) do |f|
        open(@filepath.cleanpath, 'wb') do |output|
          output.write(f.read)
        end
      end
    end

    def exec
      begin
        # ディレクトリが存在しなければ終了
        raise "directory not found." unless HotPixiv::Util.directory?(@config[:dir])

        # キーワードを取得
        data = HotPixiv::Util.read_text(@config[:file_keyword])
        origin_parent = @config[:dir]
        keywords = data.length == 0 ?
          (@config[:keyword].nil? ? [] : [@config[:keyword]]) : data

        # キーワードがなければ終了
        raise "keyword not found." if keywords.length == 0

        keywords.each do |keyword|
          # 日付のディレクトリを作成
          parent = origin_parent
          child = DateTime.now.strftime("%Y%m%d")
          HotPixiv::Util.create_dir(parent, child)

          # キーワードのディレクトリを作る
          parent = (parent + '/' + child).tosjis
          child = HotPixiv::Util.tosjis(keyword)
          child = keyword.tosjis if child.empty?
          HotPixiv::Util.create_dir(parent, child)

          @config[:dir] = parent + '/' + child

          # 画像のURLを取得
          pic_urls = pic_data(child)

          # 画像を保存
          save_pic(pic_urls)
        end
      rescue => e
        puts "[ERROR]\t#{e.message}"
      end
    end

  end
end