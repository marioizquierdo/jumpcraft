object @map
attributes :id, :name, :score, :played_games, :won_games, :created_at, :data
child :creator => :creator do
  attributes :id, :name
end