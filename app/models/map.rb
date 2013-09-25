class Map
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :data, type: String # tiles map array serialized as String, only the client cares about understanding what this means
  field :score, type: Integer
  field :played_games, type: Integer, default: 0 # number of times this map was played in the ladder
  field :won_games, type: Integer, default: 0 # number of times this map was NOT defeated in the ladder

  belongs_to :creator, class_name: "User"

  def self.create_for_user(user, attrs = {})
    map = Map.new(attrs)
    map.creator = user
    map.score = user.score # map score starts being the same as the user score
    map.save!
    map
  end

  # Find a map which score is within [lower <= score <= upper]
  # If more than one map have that score range, then choose random.
  # If no maps in that score range, then return nil.
  def self.find_random_within_score(lower, upper)
    criteria = self.where(:score.gte => lower, :score.lte => upper)
    n = criteria.count
    if n == 0
      nil # return nil if no result within distance
    else
      map = criteria.skip(rand n).first # get a random map that
    end
  end
end