require File.expand_path(Rails.root + 'lib/trueskill/lib/saulabs/trueskill.rb')
include Saulabs::TrueSkill

class RatingSystem

  SCORE_FACTOR = 20 # Xbox Live uses a scale of 0-50 for the score. We want to use a scale of 0-1000 (then we just apply a factor of x20 to the calculated score)
  SCORE_MEAN_DEVIATION_K = 3 # Same as in Xbox Live, to calculate the score, we use the so-called "conservative skill estimate", that is mean - 3 * deviation

  USER_INITIAL_SKILL_MEAN = 25.0 # in Xbox Live the initial mean is 25, but here we start playing agains trivial maps where users always win
  USER_INITIAL_SKILL_DEVIATION = 25.0/SCORE_MEAN_DEVIATION_K # use same as Xbox Live initial deviation
  MAP_INITIAL_SKILL_DEVIATION = 1.5*USER_INITIAL_SKILL_DEVIATION # for maps the initial deviation is higher, because good players could easily make trivial maps

  # Assign new skill properties (skill_mean and skill_deviation) to the winner and loser,
  # using the TrueSkill algorithm (delegates to trueskill gem).
  # After the skill calculation, assigsn a new score (score).
  def self.update_skills(winner, loser)
    # Ensure not nil using default values
    winner.skill_mean ||= USER_INITIAL_SKILL_MEAN
    winner.skill_deviation ||= USER_INITIAL_SKILL_DEVIATION
    loser.skill_mean ||= USER_INITIAL_SKILL_MEAN
    loser.skill_deviation ||= USER_INITIAL_SKILL_DEVIATION

    # Create teams
    winner_team = [Rating.new(winner.skill_mean, winner.skill_deviation)]
    loser_team = [Rating.new(loser.skill_mean, loser.skill_deviation)]

    # Configure Trueskill graph
    opts = {
      beta: 5.0, # The length of the skill-chain, which is the difference of score between players that have an 80%/20% change of winning. Use a low value for games with a small amount of chance (Go, Chess, etc.) and a high value for games with a high amount of chance (Uno, Bridge, etc.)
      draw_probability: 0, # We don't have draws in Infiltration.
    }
    graph = FactorGraph.new({winner_team => 1, loser_team => 2}, opts)

    # update team scores
    graph.update_skills

    # assign new skills to winner and loser
    unless winner.is_a?(Map) && winner.trial?
      winner.skill_mean = winner_team[0].mean
      winner.skill_deviation = winner_team[0].deviation
      winner.score = winner.calculate_score # recalculate right away
    end
    unless loser.is_a?(Map) && loser.trial? # trial maps don't update
      loser.skill_mean = loser_team[0].mean
      loser.skill_deviation = loser_team[0].deviation
      loser.score = loser.calculate_score # recalculate right away
    end
  end

  # Predict the increase in score for the user if it would win the game
  def self.score_delta_if_win(user, map)
    user_after = user.clone
    map_after = map.clone
    update_skills(user_after, map_after)
    user_after.score - user.score
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