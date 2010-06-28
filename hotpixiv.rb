require 'open-uri'
require 'net/http'
require 'cgi'
require 'kconv'
require 'optparse'
require 'pathname'

module Pixiv
  class Crawler

    PIXIV_API = 'http://iphone.pxv.jp/iphone/'
    REFERER = 'http://www.pixiv.net/'
    USER_AGENT = 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us)
      AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16'

    def initialize(config)
      @config = config
    end

    def directory?(dir)
      !!(FileTest::directory?(dir) rescue nil)
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

    def pic_data
      data = []
      begin
        for i in 1..3
          url = "#{PIXIV_API}search.php?s_mode=s_tag&word=#{@config[:keyword]}&PHPSESSID=#{session_id}&p=#{i}"
          open(url) do |f|
            f.each_line {|line| data << data_parser(line)}
          end
        end
        data.compact!
      rescue => e
        puts e.message
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
      # ディレクトリが存在しなければ終了
      if directory?(@config[:dir])
        # 画像のURLを取得
        pic_urls = pic_data
        # 画像を保存
        save_pic(pic_urls)
      else
        puts "[ERROR]\tdirectory not found."
      end
    end

  end
end

config = {}
opt = OptionParser.new
opt.on('-k', '--keyword KEYWORD') {|v| config[:keyword] = CGI.escape(v.toutf8)}
opt.on('-p', '--point POINT') {|v| config[:point] = v.to_i}
opt.on('-d', '--directory DIRECTORY') {|v| config[:dir] = v}
opt.parse!

pixiv = Pixiv::Crawler.new(config)
pixiv.exec
