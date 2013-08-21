collection @maps
attributes :id, :name, :score, :description, :data
child :creator => :creator do
  attributes :id, :name
end