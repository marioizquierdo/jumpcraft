object @user
attributes :id, :name, :score, :coins, :played_games, :won_games

child @maps do
  attributes :id, :name, :score, :played_games, :won_games
end