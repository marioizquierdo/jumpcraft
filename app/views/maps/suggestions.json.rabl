object false

node :maps do
  @maps.map do |map|
    partial('maps/show', object: map)
  end
end