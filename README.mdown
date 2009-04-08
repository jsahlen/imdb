IMDb Parser
===========

Built this as a learning excercise, and because the existing libraries didn't work exactly as I wanted them to.

This is an extremely early version, which will likely be severely refactored as it progresses.

Search example
--------------

This is the only functionality that works right now.

    require 'imdb'

    results = IMDB::Search.new("howl")
    results.each do |movie|
      puts "#{movie.title} (#{movie.year}) [#{movie.id}]"
      unless movie.aka.empty?
        movie.aka.each { |aka| puts "  a.k.a. #{aka}" }
      end
    end
