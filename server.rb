require "sinatra"
require "pg"
require 'pry'
set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def list_actors
  @actors =[]
  @actors = db_connection do |conn|
    conn.exec_params("SELECT name,id FROM actors
    ORDER BY name ASC")
  end
  return @actors.to_a
end
def movies_id
  @movies = []
  @movies = db_connection do |conn|
    conn.exec_params("SELECT movies.title, movies.id
    FROM movies")
  end
  return @movies.to_a
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/" do
  redirect "/actors"
end

get "/actors" do
   @actors= list_actors
  erb :'actors/index'
end

get "/actors/:id" do
  @id = params[:id]
  @actors = list_actors
  @actor = @actors.find { |actor| actor["id"] == params["id"] }
  @movies = db_connection do |conn|
    conn.exec_params("SELECT genres.name AS Genre, movies.title,movies.year, movies.id, cast_members.character
     From actors
     JOIN cast_members ON cast_members.actor_id = actors.id
     JOIN movies ON movies.id = cast_members.movie_id
     JOIN genres ON movies.genre_id = genres.id
     WHERE actors.name = '#{@actor["name"]}'
     ")
   end
   @movies
   erb :'actors/show'
end
get '/movies' do
  @id = params[:id] # params isnt there?
  @movies = db_connection do |conn|
    conn.exec_params("SELECT movies.id, movies.title, movies.year, movies.rating, studios.name AS studio, genres.name AS genres
    FROM movies
    LEFT OUTER JOIN genres ON movies.genre_id = genres.id
    LEFT OUTER JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title ASC")
  end
  @movies.to_a
  erb :'movies/index'
end

get '/movies/:id' do
  @movies = movies_id
  @id = params[:id]
  @movie = @movies.find {|movie| movie["id"] == params["id"] }
  @movies = db_connection do |conn|
    conn.exec_params("SELECT movies.id, movies.title, movies.year,movies.rating,studios.name AS studio, genres.name AS genres, cast_members.character AS character
    FROM movies
    LEFT OUTER JOIN genres ON movies.genre_id = genres.id
    LEFT OUTER JOIN studios ON movies.studio_id = studios.id
    LEFT OUTER JOIN cast_members ON movies.id = cast_members.id
    WHERE movies.id = '#{@movie["id"]}'
    ")
  end
  @actors = db_connection do |conn|
    conn.exec_params("SELECT actors.name AS actor, actors.id AS aid, cast_members.character AS character, movies.title
     From actors
     JOIN cast_members ON cast_members.actor_id = actors.id
     JOIN movies ON movies.id = cast_members.movie_id
     JOIN genres ON movies.genre_id = genres.id
     WHERE movies.id = '#{@movie["id"]}'
     ")
   end

  erb :'movies/show'
end
