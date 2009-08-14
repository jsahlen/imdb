module IMDB

  class Search
    include Enumerable

    attr_accessor :results

    def initialize(title, opts={})
      @limit = opts[:limit] || 0

      if title =~ /^\s*$/
        self.results = []
        return self.results
      end

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
          movie.title = IMDB.str_to_utf8(CGI.unescapeHTML(a.inner_html))
          movie.year  = td.inner_html[/<\/a>\s\((\d+)\)/, 1]
          movie.aka   = td.inner_html.scan(/aka\s+<em>"([^"]+)"<\/em>/).collect { |x| IMDB.str_to_utf8(CGI.unescapeHTML(x[0].strip)) }

          movie
        end
      end

      self.results = self.results.slice(0, @limit) if @limit != 0
    end

    def each
      self.results.each { |x| yield x }
    end

    def to_json(*a)
      self.results.to_json(*a)
    end
  end

end