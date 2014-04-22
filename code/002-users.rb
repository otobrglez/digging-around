#!/usr/bin/env ruby

require 'pp'
require 'pry'
require 'pry-remote'

class Movie < Struct.new(:id, :name); end

class User < Struct.new(:id, :name); end

class Rating < Struct.new(:id, :user_id, :movie_id, :rating); end

class Similarity < Struct.new(:a, :b, :score); end

class Recommender

  def similarities
    @similarity ||= USERS.combination(2).map do |a, b|

      pairs = MOVIES.map do |movie|
        rating_from_a = RATINGS.detect {|r| r.user_id == a.id and r.movie_id == movie.id }[:rating] rescue 0.0
        rating_from_b = RATINGS.detect {|r| r.user_id == b.id and r.movie_id == movie.id }[:rating] rescue 0.0
        (rating_from_b - rating_from_a) ** 2
      end

      score = 1/(1+Math.sqrt(pairs.inject(&:+)))

      Similarity.new(a.id, b.id, score.round(3) )
    end
  end

  def users_to user
    similarities
      .select { |s| s.a == user.id or s.b == user.id }
      .sort { |b,a| a.score <=> b.score }
  end

  def movies_to user
    ids_of_movies_user_has_seen = RATINGS.select {|r| r.user_id == user.id }.map(&:movie_id)

    first_similar_user = users_to(user).first

    first_similar_user_id = first_similar_user.a == user.id ? first_similar_user.b : first_similar_user.a

    id_of_movies_similar_has_seen = RATINGS
      .select { |r| r.user_id == first_similar_user_id }
      .sort { |b,a| a.rating <=> b.rating }
      .map(&:movie_id)

    movies_to_recommend = id_of_movies_similar_has_seen - ids_of_movies_user_has_seen

    movies = []
    movies_to_recommend.each do |movie_id|
      movies << MOVIES.detect{ |m| m.id == movie_id }
    end

    movies
  end

end

############################################################
# Loading movies, users and ratings
############################################################

# Read and parse the data from end of this file
MOVIES = DATA.read.split("\n").grep(/^M/) do |p|
  Movie.new *((p.split(' ', 3)[1,2]).map.with_index { |v,i|
    if i == 0; v.to_i; else v; end })
end; DATA.rewind

USERS = DATA.read.split("\n").grep(/^U\s/) do |p|
  User.new *((p.split(' ', 3)[1,2]).map.with_index { |v,i|
    if i == 0; v.to_i; else v; end })
end; DATA.rewind

RATINGS = DATA.read.split("\n").grep(/^\d+\s+/) do |p|
  Rating.new *p.split(' ').map(&:to_i)
end

############################################################
# Usage
############################################################



# Find user "Frank"
frank = USERS.find { |u| u.name == 'Frank' }

recommender = Recommender.new

# Find users who are like Frank.
users = recommender.users_to frank
pp users

# Recommend something that he hasn't watched yet, but other buddies have
movies = recommender.movies_to frank
pp movies



__END__

type  id  name
M     10  Matrix
M     20  Jurassic Park
M     30  Australia
M     40  Forest gump

type  id  name
U     1   Oto
U     2   Jack
U     3   Mike
U     4   Frank
U     5   Luke

id  user_id movie_id rating
1   1       10        5
2   1       20        5
3   1       40        2
4   2       10        4
5   2       20        5
6   2       30        2
7   2       40        2
8   3       20        3
9   3       30        3
10  3       40        4
11  4       30        5
12  5       10        2
13  5       30        5
14  5       40        4
