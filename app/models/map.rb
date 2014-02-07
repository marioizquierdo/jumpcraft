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

  DIFFICULTY_RANGE = 32 # how many points separate each difficulty category
  HALF_RANGE = DIFFICULTY_RANGE / 2 # half of a difficulty range, used to compute difficulty ranges.

  DIFFICULTY_TRESHOLDS = [
    [:trivial,    -999999],
    [:very_easy,  -7*HALF_RANGE],
    [:easy,       -3*HALF_RANGE],
    [:medium,     -HALF_RANGE],
    [:hard,       HALF_RANGE],
    [:very_hard,  3*HALF_RANGE],
    [:impossible, 7*HALF_RANGE],
    [:infinite,   999999]
  ]

  # Return the label for the difficulty of the map score in relation to the user_score.
  # that is one of DIFFICULTY_TRESHOLDS: very_easy, easy, medium, etc..
  def dificulty_relative_to(user_score)
    return nil unless self.score
    score_diff = self.score - user_score
    difficulty = :trivial
    DIFFICULTY_TRESHOLDS.each do |treshold|
      if score_diff > treshold[1]
        difficulty = treshold[0]
      else
        break
      end
    end
    difficulty
  end

  # Find a map based on the difficulty relative to the given score.
  # It will look for that difficulty first (i.e. :easy),
  # but if it can not find any map in that score range then will extend the range and try again,
  # so, it could return a map of that difficutly or not.
  # Return nil if there are no maps in the whole extended range of difficulties.
  def self.find_near_dificulty(score, difficulty = :medium, options = {})
    lower_index = DIFFICULTY_TRESHOLDS.index{|tr| tr[0] == difficulty}

    # Get lower/upper scores range for the given difficulty (:easy, :medium, :hard)
    lower = score + DIFFICULTY_TRESHOLDS[lower_index][1]
    upper = score + DIFFICULTY_TRESHOLDS[lower_index + 1][1]

    # Start searching in the given range and increase the range up to three times.
    self.find_random_within_score(lower, upper, options) or
    self.find_random_within_score(lower - DIFFICULTY_RANGE, upper + DIFFICULTY_RANGE, options) or
    self.find_random_within_score(lower - 2*DIFFICULTY_RANGE, upper + 2*DIFFICULTY_RANGE, options) or
    self.find_random_within_score(lower - 6*DIFFICULTY_RANGE, upper + 6*DIFFICULTY_RANGE, options)
  end

  # Find a map which score is within [lower <= score <= upper]
  # If more than one map have that score range, then choose random.
  # If no maps in that score range, then return nil.
  # Use option :exclude => [map1.id, map2.id] to ensure that those maps are not returned in the search.
  # Use option :scope => ->(criteria){ ... } to filter the results
  def self.find_random_within_score(lower, upper, options = {})
    criteria = self.where(:score.gte => lower, :score.lte => upper)
    if options[:exclude]
      exclude_ids = options[:exclude].compact.map{|x| x.is_a?(Map) ? x.id : x } # remove nil and get only ids
      criteria = criteria.nin(_id: exclude_ids)
    end
    if options[:scope]
      criteria = options[:scope].call(criteria)
    end

    n = criteria.count
    if n == 0
      nil # return nil if no result within distance
    else
      map = criteria.skip(rand n).first # get a random map that matches the criteria
    end
  end


  # Find the page number to be loaded in order to get maps around the given score.
  # Useful to set the default page to send the user when going to the maps ladder, so the user sees maps that are around her level.
  # Implemented using binary search on the score of the maps page by page
  def self.ladder_page_for_score(score, page_size = 100)
    count = Map.count
    return 1 if count == 0 # no maps, no pages
    pmin = 1 # first page
    pmax = (count.to_f / page_size).ceil # last page = number of pages
    pmid = 1

    while pmax >= pmin # continue searching while the min and max pages did not cross yet
      # calculate the midpoint for roughly equal partition
      pmid = (pmin + pmax) / 2

      offset = (pmid - 1) * page_size # offset of the first map of the pmid page
      map = Map.only(:score).desc(:score).skip(offset).first # get the first map in the page

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