require File.expand_path(Rails.root + 'lib/trueskill/lib/saulabs/trueskill.rb')
include Saulabs::TrueSkill

class RatingSystem

  USER_INITIAL_SKILL_MEAN = 20.0 # asuming it goes from 0 to 50, most new players have a skill below the average
  USER_INITIAL_SKILL_DEVIATION = 4.0 # their skill belief is pretty blur on the first games
  MAP_INITIAL_SKILL_DEVIATION = 5.0 # for maps is even less known, because good players could create trivial maps

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
    winner_team = [Rating.new(loser.skill_mean, loser.skill_deviation)]
    loser_team = [Rating.new(winner.skill_mean, winner.skill_deviation)]

    # Configure Trueskill graph
    opts = {
      beta: 5.0, # The length of the skill-chain, which is the difference of score between players that have an 80%/20% change of winning. Use a low value for games with a small amount of chance (Go, Chess, etc.) and a high value for games with a high amount of chance (Uno, Bridge, etc.)
      draw_probability: 0, # We don't have draws in Infiltration.
    }
    graph = FactorGraph.new({winner_team => 1, loser_team => 2}, opts)

    # update team scores
    graph.update_skills

    # assign new scores to winner and loser
    winner.skill_mean = [winner_team[0].mean, 0].max # ensure loser never gets negative score
    winner.skill_deviation = winner_team[0].deviation
    winner.score = calculate_score(winner.skill_mean, winner.skill_deviation)

    loser.skill_mean = [loser_team[0].mean, 0].max # ensure loser never gets negative score
    loser.skill_deviation = loser_team[0].deviation
    loser.score = calculate_score(loser.skill_mean, loser.skill_deviation)
  end

  # Assign a score based on the skill_mean and skill_deviation.
  # Use the so-called "conservative skill estimate" = mean - k * deviation,
  # using a commong k value of 3 (3 times the deviation to ensure a very conservative score).
  # We also multiply it by a factor of 20, because the mean goes between 0 and 50,
  # and we want to show scores between 0 and 1000.
  def self.calculate_score(skill_mean, skill_deviation)
    k = 3
    score_factor = 20
    score = score_factor * (skill_mean - k * skill_deviation)
    score.to_i # return integer
  end

  # Predict the increase in score for the user if it would win the game
  def self.score_delta_if_win(user, map)
    user2 = user.clone
    map2 = map.clone
    update_skills(user, map)
    user2.score - user.score
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