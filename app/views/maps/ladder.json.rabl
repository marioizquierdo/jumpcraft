collection @maps
attributes :id, :name, :score

child :creator => :creator do
  attributes :id, :name, :score
end