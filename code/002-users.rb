#!/usr/bin/env ruby -w

require 'pp'

class Movie < Struct.new(:id, :name); end

class User < Struct.new(:id, :name); end

class Rating < Struct.new(:id, :user_id, :movie_id, :rating); end

class Similarity < Struct.new(:a, :b, :score); end


class Recommender

  def similarities
    @similarity ||= USERS.combination(2).map do |a, b|

      pairs = MOVIES.map do |movie|
        rating_from_a = rating_for(a, movie)
        rating_from_b = rating_for(b, movie)

        (rating_from_b - rating_from_a) ** 2
      end

      score = 1/(1+Math.sqrt(pairs.inject(&:+)))

      Similarity.new a.id, b.id, score.round(3)
    end
  end

  def users_to user
    similarities
      .select { |s| s.a == user.id or s.b == user.id }
      .sort { |b,a| a.score <=> b.score }
  end

  def movies_to user
    ids_of_movies_user_has_seen = RATINGS
      .select {|r| r.user_id == user.id }
      .map(&:movie_id)

    first_similar_user = users_to(user).first

    first_similar_user_id = first_similar_user.a == user.id ? first_similar_user.b : first_similar_user.a

    id_of_movies_similar_has_seen = RATINGS
      .select { |r| r.user_id == first_similar_user_id }
      .sort { |b,a| a.rating <=> b.rating }
      .map(&:movie_id)

    movies_to_recommend = id_of_movies_similar_has_seen - ids_of_movies_user_has_seen

    movies = []
    movies_to_recommend.each do |movie_id|
      movies << MOVIES.find{ |m| m.id == movie_id }
    end

    movies
  end

  def rating_for(user, movie)
    RATINGS.find {|r| r.user_id == user.id and r.movie_id == movie.id }[:rating] rescue 0.0
  end

end

############################################################
# Loading movies, users and ratings
############################################################

MOVIES = []
MOVIES << Movie.new(10, 'Matrix')
MOVIES << Movie.new(20, 'Jurassic Park')
MOVIES << Movie.new(30, 'Australia')
MOVIES << Movie.new(40, 'Forest gump')

USERS = []
USERS << User.new(1, 'Oto')
USERS << User.new(2, 'Jack')
USERS << User.new(3, 'Mike')
USERS << User.new(4, 'Frank')
USERS << User.new(5, 'Luke')

RATINGS = []
RATINGS << Rating.new( 1, 1, 10, 5)
RATINGS << Rating.new( 2, 1, 20, 5)
RATINGS << Rating.new( 3, 1, 40, 2)
RATINGS << Rating.new( 4, 2, 10, 4)
RATINGS << Rating.new( 5, 2, 20, 5)
RATINGS << Rating.new( 6, 2, 30, 2)
RATINGS << Rating.new( 7, 2, 40, 2)
RATINGS << Rating.new( 8, 3, 20, 3)
RATINGS << Rating.new( 9, 3, 30, 3)
RATINGS << Rating.new(10, 3, 40, 4)
RATINGS << Rating.new(11, 4, 30, 5)
RATINGS << Rating.new(12, 5, 10, 2)
RATINGS << Rating.new(13, 5, 30, 5)
RATINGS << Rating.new(14, 5, 40, 4)

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
