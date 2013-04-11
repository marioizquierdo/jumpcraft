object @user
attributes :id, :email, :name
child :maps do
  attributes :name, :description
end