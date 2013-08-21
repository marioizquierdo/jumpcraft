collection @maps
attributes :id, :name, :score, :played_games, :won_games, :description, :data

child :creator => :creator do
  attributes :id, :name
end