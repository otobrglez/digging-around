#!/usr/bin/env ruby

require "matrix"
require "pp"

class Movie < Struct.new(:id, :name)
end

class User < Struct.new(:id, :name)

  # We create square matrix of user ids
  def self.matrix
    Matrix[*
      USERS.map do |user_a|
        USERS.map do |user_b|
          [user_a.id, user_b.id]
        end
      end
    ]
  end

  # Index of user inside User.matrix
  def index
    @index ||= User.matrix.row(0).map(&:last).to_a.index(self.id)
  end

  def similar_users
    users_vector = Similarity.matrix.row self.index

    list = users_vector.map.with_index do |k,i|
      [ USERS.detect { |u| u.index == i }, k ]
    end.sort{ |a,b| a.last <=> b.last }.reverse.reject { |l| l.last == 1.0 }

  end

end

class Rating < Struct.new(:id, :user_id, :movie_id, :rating)

  # We create another matrix of user by movies ids
  def self.matrix
    Matrix[*
      USERS.map do |user|
        MOVIES.map do |movie|

          pair = RATINGS.detect do |m|
            m.movie_id == movie.id and
              m.user_id == user.id and
              not m.rating.nil?
          end

          pair.nil? ? 0 : pair.rating
        end
      end
    ]
  end

end

class Similarity

  # Similarity matrix
  def self.matrix
    Matrix[*
      (0..User.matrix.row_count-1).map do |r|
        (0..User.matrix.row_count-1).map do |c|

          user_b_ratings = Rating.matrix.row(c)

          # Sum square root of differences
          under = Rating.matrix.row(r).map.with_index do |p,i|
            (p.to_f-user_b_ratings[i].to_f)  ** 2
          end.inject(:+)

          (1/(1+Math.sqrt(under))).round(2)
        end
      end
    ]
  end

end


# Read and parse the data from end of this file
MOVIES = DATA.read.split("\n").grep(/^M/) do |p|
  Movie.new *((p.split(" ", 3)[1,2]).map.with_index {
    |v,i| if i == 0; v.to_i; else v; end })
end; DATA.rewind

USERS = DATA.read.split("\n").grep(/^U\ /) do |p|
  User.new *((p.split(" ", 3)[1,2]).map.with_index {
    |v,i| if i == 0; v.to_i; else v; end })
end; DATA.rewind

RATINGS = DATA.read.split("\n").grep(/^\d+\s+/) do |p|
  Rating.new *p.split(" ").map(&:to_i)
end

me = USERS.detect { |u| u.name == "Frank" }
pp me.similar_users

__END__

type id name
M    1  Matrix
M    2  Jurassic Park
M    3  Australia
M    4  Forest gump

type id name
U    9  Oto
U    2  Jack
U    3  Mike
U    4  Frank
U    5  Luke

id user_id movie_id rating
1  1       1        5
2  1       2        5
3  1       4        2
4  2       1        4
5  2       2        5
6  2       3        2
7  2       4        2
8  3       2        3
9  3       3        3
10 3       4        4
11 4       3        5
12 5       1        2
13 5       3        5
14 5       4        4
