object @map
attributes :id, :name, :description, :created_at, :data
child :creator => :creator do
  attributes :id, :name
end