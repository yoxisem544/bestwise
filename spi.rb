require 'rest_client'
require 'nokogiri'
require 'json'
require 'iconv'
require 'uri'
require_relative 'course.rb'
# 難得寫註解，總該碎碎念。
class Spider
  attr_reader :semester_list, :courses_list, :query_url, :result_url

  def initialize
  	@query_url = "http://www.bestwise.com.tw/Book_default.aspx"
    @front_url = "http://www.bestwise.com.tw//"
    @next_page_url = "&startno="
  end

  def prepare_post_data
    puts "hey yo bestwise here"
    r = RestClient.get @query_url
    ic = Iconv.new("utf-8//translit//IGNORE","big-5")
    @query_page = Nokogiri::HTML(ic.iconv(r.to_s))
    nil
  end

  def get_books
  	# 初始 courses 陣列
    @books = []
    puts "getting books...\n"
    # 一一點進去YO

    @i = 0
    @query_page.css('div#BodyContentLeftBook a').each_with_index do |row, index|
      # get every link to every classification
      # puts @front_url + row['href'].to_s
      puts index
      puts row
      r = RestClient.get @front_url + row['href'].to_s
      ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
      hello_books = Nokogiri::HTML(ic.iconv(r.to_s))
      
      # 拿到每個page
      hello_books.css('td.pages a').each_with_index do |row, index|
        if hello_books.css('td.pages a').size == index + 1
          next
        end
        puts row['href']

        r = RestClient.get @front_url + row['href'].to_s
        ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
        page = Nokogiri::HTML(ic.iconv(r.to_s))

        page.css('div.title15 a').each_with_index do |row, index|
          puts index, row['href']

          r = RestClient.get @front_url + row['href'].to_s
          ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
          detail_page = Nokogiri::HTML(ic.iconv(r.to_s))

          puts detail_page.css('th').text
          # hello data init here
          @book_name = detail_page.css('th').text
          @author = ""
          @proofreading = ""
          @audited = ""
          @book_number = ""
          @price = ""
          @publish_store = ""
          @publish_date = ""
          @edition = ""
          @isbn = ""

          detail_page.css('div.title li').each_with_index do |row, index|
            # puts row.text.rpartition('：').first, row.text.rpartition('：').last

            if row.text.rpartition('：').first == "作者"
              @author = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "審訂"
              @audited = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "總校閱"
              @proofreading = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "書號"
              @book_number = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "定價"
              @price = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "出版社"
              @publish_store = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "出版日"
              @publish_date = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "版次"
              @edition = row.text.rpartition('：').last
            elsif row.text.rpartition('：').first == "ISBN"
              @isbn = row.text.rpartition('：').last
            end

            # puts isbn
          end
            @books << Course.new({
                :book_name => @book_name,
                :author => @author,
                :proofreading => @proofreading,
                :audited => @audited,
                :book_number => @book_number,
                :price => @price,
                :publish_store => @publish_store,
                :publish_date => @publish_date,
                :edition => @edition,
                :isbn => @isbn
              }).to_hash

        end


      end
      

    end

    
  end
  

  def save_to(filename='bestwise_book.json')
    File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(@books))}
  end
    
end






spider = Spider.new
spider.prepare_post_data
spider.get_books
spider.save_to