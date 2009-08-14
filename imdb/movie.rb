module IMDB

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
      self.title = IMDB.str_to_utf8(CGI.unescapeHTML((doc/"h1").inner_html[/^(.*?)(?: <span)/, 1]))
      self.year  = (doc/"h1 a[@href^='/Sections/Years/']").inner_html
      self.aka   = akablock.inner_html.scan(/(?:>)([^<]*?)\(/).collect { |x| IMDB.str_to_utf8(CGI.unescapeHTML(x[0].strip)) }

      self
    end

    def id=(id)
      @id = id
      self.url = IMDB::TITLE_URL + id
    end

    def to_json(*a)
      {
        "id" => self.id,
        "title" => self.title,
        "year" => self.year,
        "aka" => self.aka
      }.to_json(*a)
    end
  end

end