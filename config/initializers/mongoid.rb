# Serialize "id" as an string instead of "$oid: str"
# convert object key "_id" to "id" and remove "_id" from displayed attributes on mongoid documents when represented as JSON
module Mongoid
  module Document
    def as_json(options={})
      attrs = super(options)
      id = {id: attrs["_id"].to_s}
      attrs.delete("_id")
      id.merge(attrs)
    end
  end
end

# Serialize "id" as an string instead of "$oid: str"
# http://stackoverflow.com/questions/18646223/ruby-model-output-id-as-object-oid/20813109
module BSON
  class ObjectId
    def to_json(*args)
      to_s.to_json
    end

    def as_json(*args)
      to_s.as_json
    end
  end
end