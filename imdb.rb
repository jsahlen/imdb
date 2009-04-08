module IMDB
  require 'open-uri'
  require 'rubygems'
  require 'hpricot'
  require 'cgi'

  class Search
    attr_accessor :results

    def initialize(title)
      doc = Hpricot(open("http://www.imdb.com/find?s=tt&q=#{CGI.escape(title)}"))

      if (doc/"div#tn15.maindetails").length > 0
        # Single match

        akablock = (doc/"a[@href$='releaseinfo#akas']")[0].parent

        self.results = [Movie.new(
          :id    => (doc/"a[@href$='fullcredits]")[0].attributes["href"][/title\/(.*?)\//, 1],
          :title => CGI.unescape((doc/"h1").inner_html[/^(.*?)(?: <span)/, 1]),
          :year  => (doc/"h1 a[@href^='/Sections/Years/']").inner_html,
          :aka   => akablock.inner_html.scan(/(?:>)([^<]*?)\(/).collect { |x| CGI.unescapeHTML(x[0].strip) }
        )]
      else
        # Search result

        links = (doc/"td > a[@href^='/title/']").delete_if { |a| a.inner_html =~ /^</ }
        self.results = links.collect! do |a|
          td = a.parent
          aka = []

          aka_regexp = /aka\s+<em>"([^"]+)"<\/em>/

          akasearch = "#{td.inner_html}"

          akamatch = aka_regexp.match(akasearch)
          while akamatch != nil
            aka << CGI.unescapeHTML(akamatch[1])
            akasearch = akamatch.post_match
            akamatch = aka_regexp.match(akasearch)
          end

          Movie.new(
            :id    => a.attributes["href"].sub(/^\/title\/([^\/]+).*$/, '\1'),
            :title => CGI.unescapeHTML(a.inner_html),
            :year  => td.inner_html[/<\/a>\s\((\d+)\)/, 1],
            :aka   => aka
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