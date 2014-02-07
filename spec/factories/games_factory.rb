FactoryGirl.define do
  factory :game do
    user
    map
    finished true
    map_defeated true

    coins 10
    user_score 1000
    map_score 1000
    user_played_games 1
    map_played_games 1
  end
end