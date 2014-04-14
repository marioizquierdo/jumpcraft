FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "user#{n}" }
    sequence(:email) {|n| "user#{n}@email.com" }
    password 'aB%1234'
    skill_mean 25.0
    skill_deviation 8.0

    ignore do
      score nil
    end

    after(:build) do |user, evaluator|
      if evaluator.score # if score was set on the factory, do not calculate from skill
        user.skip_calculate_score_callback = true
        user.score = evaluator.score
      end
    end
  end
end