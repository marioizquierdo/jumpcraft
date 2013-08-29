FactoryGirl.define do
  factory :map do
    sequence(:name) {|n| "map#{n}" }
  end
end