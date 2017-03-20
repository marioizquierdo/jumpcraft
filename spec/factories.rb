FactoryGirl.define do

  # User
	factory :user, aliases: [:creator] do
    sequence(:name) {|n| "user#{n}" }
    sequence(:email) {|n| "user#{n}@email.com" }
    password 'aB%1234'
    skill_mean 25.0
    skill_deviation 3.0 # make it so it doesnt show "unknown" maps all the time

    transient do
      score nil
    end

    after(:build) do |user, evaluator|
      if evaluator.score # if score was set on the factory, do not calculate from skill
        user.skip_calculate_score_callback = true
        user.score = evaluator.score
      end
    end
  end

  # Game
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

  # Map
  factory :map do
    creator

    sequence(:name) {|n| "map#{n}" }
    skill_mean 25.0
    skill_deviation 2.0

    transient do
      score nil
    end

    after(:build) do |map, evaluator|
      if evaluator.score # if score was set on the factory, do not calculate from skill
        map.skip_calculate_score_callback = true
        map.score = evaluator.score
      end
    end
  end

end