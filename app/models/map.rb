class Map
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :data, type: String # tiles map array serialized as String, only the client cares about understanding what this means
  field :score, type: Integer

  belongs_to :creator, class_name: "User"

  def self.create_for_user(user, attrs = {})
    map = Map.new(attrs)
    map.creator = user
    map.score = user.score # map score starts being the same as the user score
    map.save!
    map
  end
end