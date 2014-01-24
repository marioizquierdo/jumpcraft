class SimpleElo


  # Assign new scores to the winner and loser.
  def self.assign_new_scores(winner, loser)
    # Ensure not nil
    loser.score ||= 1000
    winner.score ||= 1000

    diff = self.calculate_score_diff(winner.score, loser.score)

    # update scores
    loser.score = [loser.score - diff, 0].max # ensure loser never gets negative score
    winner.score = winner.score + diff

    diff
  end

  # Given a winner and a loser,
  # calculate the new score using a simplification of the ELO rating algoritmh,
  # based on http://aoe3.jpcommunity.com/rating2
  # and return the diff of score.
  #
  # We calculate rating (score) as follows (based on http://aoe3.jpcommunity.com/rating2/):
  # Example:
  #  GIVEN winner.score = 1700; loser.score = 1600
  #  diff = 16 + (1600 - 1700) x (16 / 400) = 12
  #  THEN winner.score = 1712, loser.score = 1588
  #
  def self.calculate_score_diff(winner_score, loser_score)

    # Calculate new score diff
    diff = 16.0 + (loser_score - winner_score) * (16.0 / 400)
    diff = diff.to_i
    diff = [[diff, 32].min, 0].max # keep between 1 and 31
    diff
  end

end