object @user
attributes :id, :name, :score
child :maps do
  attributes :name, :score, :description
end