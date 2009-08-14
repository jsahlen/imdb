module IMDB
  require 'open-uri'
  require 'rubygems'
  require 'hpricot'
  require 'cgi'
  require 'iconv'
  require 'json'

  FILES=%w{search movie}
  FILES.each { |f| require File.join(File.dirname(__FILE__), 'imdb', f) }

  TITLES_SEARCH_URL="http://www.imdb.com/find?s=tt&q="
  TITLE_URL="http://www.imdb.com/title/"

  def self.str_to_utf8(str)
    Iconv.conv('UTF-8', 'LATIN1', str)
  end

end