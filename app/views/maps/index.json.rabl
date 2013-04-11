collection @maps
attributes :id, :name, :description, :data
child :creator => :creator do
  attributes :id, :name
end