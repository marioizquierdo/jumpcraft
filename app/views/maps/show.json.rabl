object @map
attributes :id, :name, :score, :played_games, :won_games, :created_at, :data
node(:difficulty, if: ->(m) { current_user }) { |map| map.dificulty_relative_to(current_user.score) }
node(:played_by_current_user, if: ->(m) { current_user && @plays_count }) { |map| @plays_count[map.id] || 0 }
child :creator => :creator do
  attributes :id, :name
end