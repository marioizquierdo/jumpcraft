object @map
attributes :id, :name, :score, :played_games, :won_games, :created_at, :data
node(:difficulty, if: ->{ current_user }) { |map| map.dificulty_relative_to(current_user.score) }
child :creator => :creator do
  attributes :id, :name
end