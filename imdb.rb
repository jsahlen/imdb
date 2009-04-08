module IMDB
  require 'open-uri'
  require 'rubygems'
  require 'hpricot'
  require 'cgi'

  TITLES_SEARCH_URL="http://www.imdb.com/find?s=tt&q="
  TITLE_URL="http://www.imdb.com/title/"

  class Search
    include Enumerable

    attr_accessor :results

    def initialize(title, opts={})
      @limit = opts[:limit] || 0

      doc = Hpricot(open(IMDB::TITLES_SEARCH_URL+CGI.escape(title)))

      # Single match
      unless (doc/"div#tn15.maindetails").empty?
        self.results = [Movie.new_from_doc(doc)]

      # Search result
      else
        links = (doc/"td > a[@href^='/title/']").delete_if { |a| a.inner_html =~ /^</ }
        self.results = links.collect! do |a|
          td = a.parent
          movie = Movie.new

          movie.id    = a.attributes["href"][/^\/title\/([^\/]+)/, 1]
          movie.title = CGI.unescapeHTML(a.inner_html)
          movie.year  = td.inner_html[/<\/a>\s\((\d+)\)/, 1]
          movie.aka   = td.inner_html.scan(/aka\s+<em>"([^"]+)"<\/em>/).collect { |x| CGI.unescapeHTML(x[0].strip) }

          movie
        end
      end

      self.results = self.results.slice(0, @limit) if @limit != 0
    end

    def each
      self.results.each { |x| yield x }
    end
  end

  class Movie
    attr_accessor :id, :title, :year, :aka, :url

    def initialize(attributes={})
      attributes.each_pair do |key, value|
        self.instance_variable_set "@#{key}", value
      end
    end

    def self.new_from_doc(doc)
      movie = self.new
      movie.parse_doc(doc)
    end

    def parse_doc(doc)
      akablock = (doc/"a[@href$='releaseinfo#akas']")[0].parent

      self.id    = (doc/"a[@href$='fullcredits]")[0].attributes["href"][/title\/(.*?)\//, 1]
      self.title = CGI.unescape((doc/"h1").inner_html[/^(.*?)(?: <span)/, 1])
      self.year  = (doc/"h1 a[@href^='/Sections/Years/']").inner_html
      self.aka   = akablock.inner_html.scan(/(?:>)([^<]*?)\(/).collect { |x| CGI.unescapeHTML(x[0].strip) }

      self
    end

    def id=(id)
      @id = id
      self.url = IMDB::TITLE_URL + id
    end
  end

end