object @map

attributes :id, :name, :score, :played_games, :won_games, :created_at
attributes :data unless params[:no_data]

if current_user
  node(:difficulty) { |map| map.dificulty_relative_to(current_user.score) }
  if @plays_count
    node(:played_by_current_user) { |map| @plays_count[map.id] || 0 }
  end

  # Amount that is added to the user's score if the user wins against this map.
  # The same amount is substracted if the user loses.
  node(:score_delta_if_win) { |map| SimpleElo.calculate_score_diff(current_user.score, map.score) }
end

child :creator => :creator do
  attributes :id, :name
end