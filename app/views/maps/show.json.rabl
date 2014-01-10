object @map

attributes :id, :name, :score, :played_games, :won_games, :created_at
puts params[:no_data]
attributes :data unless params[:no_data]

if current_user
  node(:difficulty) { |map| map.dificulty_relative_to(current_user.score) }
  if @plays_count
    node(:played_by_current_user) { |map| @plays_count[map.id] || 0 }
  end
end

child :creator => :creator do
  attributes :id, :name
end