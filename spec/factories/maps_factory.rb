FactoryGirl.define do
  factory :map do
    sequence(:name) {|n| "map#{n}" }
    skill_mean 25.0
    skill_deviation 2.0
  end
end