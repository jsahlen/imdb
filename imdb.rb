module IMDB
  require 'open-uri'
  require 'rubygems'
  require 'hpricot'
  require 'cgi'

  class Search
    include Enumerable

    attr_accessor :results

    def initialize(title)
      doc = Hpricot(open("http://www.imdb.com/find?s=tt&q=#{CGI.escape(title)}"))

      # Single match
      unless (doc/"div#tn15.maindetails").empty?
        akablock = (doc/"a[@href$='releaseinfo#akas']")[0].parent

        self.results = [Movie.new(
          :id    => (doc/"a[@href$='fullcredits]")[0].attributes["href"][/title\/(.*?)\//, 1],
          :title => CGI.unescape((doc/"h1").inner_html[/^(.*?)(?: <span)/, 1]),
          :year  => (doc/"h1 a[@href^='/Sections/Years/']").inner_html,
          :aka   => akablock.inner_html.scan(/(?:>)([^<]*?)\(/).collect { |x| CGI.unescapeHTML(x[0].strip) }
        )]

      # Search result
      else
        links = (doc/"td > a[@href^='/title/']").delete_if { |a| a.inner_html =~ /^</ }
        self.results = links.collect! do |a|
          td = a.parent

          Movie.new(
            :id    => a.attributes["href"][/^\/title\/([^\/]+)/, 1],
            :title => CGI.unescapeHTML(a.inner_html),
            :year  => td.inner_html[/<\/a>\s\((\d+)\)/, 1],
            :aka   => td.inner_html.scan(/aka\s+<em>"([^"]+)"<\/em>/).collect { |x| CGI.unescapeHTML(x[0].strip) }
          )
        end
      end
    end

    def each
      self.results.each { |x| yield x }
    end
  end

  class Movie
    attr_accessor :id, :title, :year, :aka

    def initialize(attributes={})
      attributes.each_pair do |key, value|
        self.instance_variable_set "@#{key}", value
      end
    end
  end

end