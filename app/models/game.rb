class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :map

  field :finished, type: Boolean # false while playing, true after the match ends
  field :map_defeated, type: Boolean # true if user won

  field :coins, type: Integer, default: 0 # number of collected coins in this map
  field :user_score, type: Integer # before game
  field :user_score_delta, type: Integer, default: 0 # diff of user score after playing the game
  field :map_score, type: Integer # before game
  field :user_played_games, type: Integer # before game
  field :map_played_games, type: Integer # before game

  scope :user, ->(user){ where user_id: user.id }
  scope :map, ->(map){ where map_id: map.id }
  scope :maps, ->(maps){ where :map_id.in => maps.collect(&:id) }
  scope :unfinished, ne( finished: true )

  # Return a list of ids from already played maps by the user, starting by the most recent game.
  def self.last_played_map_ids(user, limit)
    last_games = self.user(user).desc(:_id).limit(limit) # order by id works ok to get the last inserted ones
    last_games.only(:map_id).map(&:map_id)
  end

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
    score_diff = SimpleElo.assign_new_scores(winner, loser)

    # Update user
    user.coins += self.coins
    user.played_games += 1
    user.won_games += 1 if map_defeated

    # Update map
    map.played_games += 1
    map.won_games += 1 unless map_defeated

    # Update game
    self.user_score = user.score
    self.user_score_delta = user == winner ? score_diff : -score_diff
    self.map_score = map.score
    self.user_played_games = user.played_games
    self.map_played_games = map.played_games
  end
end