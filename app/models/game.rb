class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :map

  field :finished, type: Boolean # false while playing, true after the match ends
  field :map_defeated, type: Boolean # true if user won

  field :coins, type: Integer, default: 0 # number of collected coins in this map
  field :user_score, type: Integer # before game
  field :map_score, type: Integer # before game
  field :user_played_games, type: Integer # before game
  field :map_played_games, type: Integer # before game

  scope :user, ->(user){ where user_id: user.id }
  scope :map, ->(map){ where map_id: map.id }
  scope :unfinished, ne( finished: true )

  def finish_and_save!
    self.finish
    user.save!
    map.save!
    self.save!
  end

  # Finish current game,
  # update user and map scored using the Elo rating system,
  # update map and user stats.
  def finish
    self.finished = true

    # Assign new scores (updates user and map scored)
    winner, loser = map_defeated ? [user, map] : [map, user]
    SimpleElo.assign_new_scores!(winner, loser)

    # Update user
    user.coins += self.coins
    user.played_games += 1
    user.won_games += 1 if map_defeated

    # Update map
    map.played_games += 1
    map.won_games += 1 unless map_defeated

    # Update game
    user_score = user.score
    map_score = map.score
    user_played_games = user.played_games
    map_played_games = map.played_games
  end
end