class Map
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :data, type: String # tiles map array serialized as String, only the client cares about understanding what this means
  belongs_to :creator, class_name: "User"
end