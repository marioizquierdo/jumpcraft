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

  # Find the page number to be loaded in order to get maps around the given score.
  # Useful to set the default page to send the user when going to the maps ladder, so the user sees maps that are around her level.
  # Implemented using binary search on the score of the maps page by page
  def self.ladder_page_for_score(model_sope, score, page_size = 100)
    count = model_sope.count
    return 1 if count == 0 # no maps, no pages
    pmin = 1 # first page
    pmax = (count.to_f / page_size).ceil # last page = number of pages
    pmid = 1

    while pmax >= pmin # continue searching while the min and max pages did not cross yet
      # calculate the midpoint for roughly equal partition
      pmid = (pmin + pmax) / 2

      offset = (pmid - 1) * page_size # offset of the first map of the pmid page
      map = model_sope.only(:score).desc(:score).skip(offset).first # get the first map in the page

      if pmax == pmin # end of search, we just need to know if the page is the one before or after.
        if score <= map.score
          return pmid
        elsif score > map.score
          return pmid - 1 # the page was the previous one
        end

      else # pmax > pmin, keep searching
        if score < map.score # the page is in the right
          pmin = pmid + 1 # change min index to search upper subarray
        elsif score > map.score
          pmax = pmid - 1 # change max index to search lower subarray
        else # map.score == score
          return pmid # exact match, we found the page
        end
      end
    end

    return [1, pmid - 1].max # search is over, the page that has scores around the score has to be pmid (ensure minimun page is 1, not 0)
  end

end