FactoryGirl.define do
  factory :map do
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