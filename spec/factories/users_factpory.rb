FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "user#{n}" }
    sequence(:email) {|n| "user#{n}@email.com" }
    password 'aB%1234'
  end
end