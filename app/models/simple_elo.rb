class SimpleElo


  # Given a winner and a loser,
  # calculate the new score using a simplification of the ELO rating algoritmh,
  # based on http://aoe3.jpcommunity.com/rating2
  # We calculate rating (score) as follows (based on http://aoe3.jpcommunity.com/rating2/):
  # Example:
  #  GIVEN winner.score = 1700; loser.score = 1600
  #  diff = 16 + (1600 - 1700) x (16 / 400) = 12
  #  THEN winner.scpre = 1712, loser.score = 1588
  def self.assign_new_scores!(winner, loser)
    loser_score = loser.score || 1000
    winner_score = winner.score || 1000

    # Calculate new score diff
    diff = 16.0 + (loser_score - winner_score) * (16.0 / 400)
    diff = diff.to_i
    diff = [[diff, 32].min, 0].max # keep between 1 and 31

    # update scores
    loser.score = [loser_score - diff, 0].max # ensure it doesnt go below 0 points
    winner.score = winner_score + diff

    return diff
  end

end