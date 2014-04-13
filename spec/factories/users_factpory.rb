FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "user#{n}" }
    sequence(:email) {|n| "user#{n}@email.com" }
    password 'aB%1234'
    skill_mean 25.0
    skill_deviation 8.0
  end
end