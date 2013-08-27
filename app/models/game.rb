class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :map

  field :map_defeated, type: Boolean # true if user won

  field :coins, type: Integer # number of collected coins in this map
  field :user_score, type: Integer # before game
  field :map_score, type: Integer # before game
  field :user_played_games, type: Integer # before game
  field :map_played_games, type: Integer # before game
end