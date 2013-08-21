collection @maps
attributes :id, :name, :score, :played_games, :won_games, :data

child :creator => :creator do
  attributes :id, :name, :score, :coins
end