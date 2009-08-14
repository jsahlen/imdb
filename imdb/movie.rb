module IMDB

  class Movie
    attr_accessor :id, :title, :year, :aka, :url, :extra

    def initialize(attributes={})
      self.extra = {}

      attributes.each_pair do |key, value|
        self.instance_variable_set "@#{key}", value
      end
    end

    def self.new_from_doc(doc)
      movie = self.new
      movie.parse_doc(doc)
      movie
    end

    def self.new_from_id(id)
      movie = self.new
      movie.id = id.to_s
      movie.get_full_details
      movie
    end

    def get_full_details
      doc = Hpricot(open(IMDB::TITLE_URL+CGI.escape(self.id)))
      self.parse_doc(doc)
      self
    end

    def parse_doc(doc)
      akalink = (doc/"a[@href$='releaseinfo#akas']")[0]

      self.id    = (doc/"a[@href$='fullcredits]")[0].attributes["href"][/title\/(.*?)\//, 1]
      self.title = IMDB.str_to_utf8(CGI.unescapeHTML((doc/"h1").inner_html[/^(.*?)(?: <span)/, 1]))
      self.year  = (doc/"h1 a[@href^='/Sections/Years/']").inner_html
      self.aka   = akalink ? akalink.parent.inner_html.scan(/(?:>)([^<]*?)\(/).collect { |x| IMDB.str_to_utf8(CGI.unescapeHTML(x[0].strip)) } : []

      parse_extra(doc)

      self
    end

    def parse_extra(doc)
      director_link  = (doc/"#director-info/a")[0]
      writer_links   = (doc/"a[@onclick*='writerlist']")
      tagline_header = (doc/"h5[text()='Tagline:']")[0]
      plot_link      = (doc/"a[@href$='/plotsummary]")[0]
      mpaa_link      = (doc/"a[@href='/mpaa']")[0]

      self.extra = {
        "director"    => director_link ? IMDB.str_to_utf8(CGI.unescapeHTML(director_link.inner_html)) : "",
        "writers"     => writer_links ? writer_links.collect { |w| IMDB.str_to_utf8(CGI.unescapeHTML(w.inner_html)) } : [],
        "tagline"     => tagline_header ? IMDB.str_to_utf8(CGI.unescapeHTML(tagline_header.parent.inner_html[/\/h5>(.+?)(<|$)/m, 1].strip)) : "",
        "plot"        => plot_link ? IMDB.str_to_utf8(CGI.unescapeHTML(plot_link.parent.inner_html[/\/h5>(.+?)<a/m, 1].strip)) : "",
        "cast"        => ((doc/"table.cast")[0]/"tr").collect { |tr| { "actor" => IMDB.str_to_utf8(CGI.unescapeHTML((tr/"td.nm")[0].inner_text)), "character" => IMDB.str_to_utf8(CGI.unescapeHTML((tr/"td.char")[0].inner_text)) } },
        "mpaa_rating" => mpaa_link ? IMDB.str_to_utf8(CGI.unescapeHTML(mpaa_link.parent.parent.inner_html[/\/h5>(.+)$/m, 1].strip)) : ""
      }

      self
    end

    def id=(id)
      @id = id
      self.url = IMDB::TITLE_URL + id
    end

    def to_json(*a)
      {
        "id"    => self.id,
        "title" => self.title,
        "year"  => self.year,
        "aka"   => self.aka,
        "extra" => self.extra
      }.to_json(*a)
    end
  end

end