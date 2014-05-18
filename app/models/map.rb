class Map
  include Mongoid::Document
  include Mongoid::Timestamps

  AVERAGE_SKILL_PROPORTION_TO_CREATOR = 0.8 # estimate that the map difficulty will be a little less than the user skill, because we know it will not be better (users can not validate maps that are too hard for them), and we know that they could be trivial maps.

  field :name, type: String
  field :data, type: String # tiles map array serialized as String, only the client cares about understanding what this means
  field :score, type: Integer, default: 0
  field :skill_mean, type: Float, default: RatingSystem::USER_INITIAL_SKILL_MEAN # from TrueSkill, assumed to be between 0 and 50
  field :skill_deviation, type: Float, default: RatingSystem::MAP_INITIAL_SKILL_DEVIATION  # from TrueSkill, standard deviation of the mean, in order to define the Gaussian Distribution
  field :played_games, type: Integer, default: 0 # number of times this map was played in the ladder
  field :won_games, type: Integer, default: 0 # number of times this map was NOT defeated in the ladder

  belongs_to :creator, class_name: "User", index: true
  has_many :games, dependent: :delete

  index score: -1 # for ladder
  index skill_mean: -1 # for suggestions
  index({trial: 1}, {sparse: true}) # to get trial maps on first suggestions

  after_build :calculate_score, unless: :skip_calculate_score_callback
  before_save :calculate_score, unless: :skip_calculate_score_callback
  attr_accessor :skip_calculate_score_callback # set to true on tests to skip calculate_score callback
  attr_accessor :trial_difficulty # used to manually override dificulty_relative_to(user_skill) on trial maps

  scope :trial, where(creator_id: User::JUMPCRAFT_USER_ID) # get only trial maps

  def trial? # check if this map is a trial map
    self.creator_id.to_s == User::JUMPCRAFT_USER_ID
  end

  def self.create_for_user(user, attrs = {})
    map = Map.new(attrs)
    map.creator = user
    map.skill_mean = AVERAGE_SKILL_PROPORTION_TO_CREATOR * user.skill_mean
    map.skill_deviation = RatingSystem::MAP_INITIAL_SKILL_DEVIATION
    map.save!
    map
  end

  DIFFICULTY_RANGE = 4 # how many points separate each difficulty category
  HALF_RANGE = DIFFICULTY_RANGE / 2 # half of a difficulty range, used to compute difficulty ranges.

  DIFFICULTY_TRESHOLDS = [
    [:trivial,    -99*HALF_RANGE],
    [:very_easy,  -6*HALF_RANGE],
    [:easy,       -2*HALF_RANGE],
    [:medium,     -HALF_RANGE],
    [:hard,       HALF_RANGE],
    [:very_hard,  2*HALF_RANGE],
    [:impossible, 6*HALF_RANGE],
    [:infinite,   99*HALF_RANGE]
  ]

  # Map.lower_skill_treshold_for(:very_hard) => 4
  def self.lower_skill_treshold_for(difficulty = :medium)
    tr_idx = DIFFICULTY_TRESHOLDS.index{|tr| tr[0] == difficulty}
    treshold = DIFFICULTY_TRESHOLDS[tr_idx][1]
  end

  # Return the label for the difficulty of the map score in relation to the user.
  # that is one of DIFFICULTY_TRESHOLDS: very_easy, easy, medium, etc..
  def dificulty_relative_to(user_skill)
    return :unknown unless self.skill_mean # ensure not nil value errors
    return :unknown if self.skill_deviation > 4 # more deviation means that we really don't know yet if the skill_mean is accurate
    skill_diff = self.skill_mean - user_skill
    difficulty = :trivial
    DIFFICULTY_TRESHOLDS.each do |treshold|
      if skill_diff > treshold[1]
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
  def self.find_near_dificulty(skill, difficulty = :medium, options = {})
    lower_index = DIFFICULTY_TRESHOLDS.index{|tr| tr[0] == difficulty}

    # Get lower/upper scores range for the given difficulty (:easy, :medium, :hard)
    lower = skill + DIFFICULTY_TRESHOLDS[lower_index][1]
    upper = skill + DIFFICULTY_TRESHOLDS[lower_index + 1][1]

    # Start searching in the given range and increase the range up to three times.
    self.find_random_within_skill(lower, upper, options) or
    self.find_random_within_skill(lower - DIFFICULTY_RANGE, upper + DIFFICULTY_RANGE, options) or
    self.find_random_within_skill(lower - 5*DIFFICULTY_RANGE, upper + 5*DIFFICULTY_RANGE, options) or
    self.find_random_within_skill(lower - 10*DIFFICULTY_RANGE, upper + 10*DIFFICULTY_RANGE, options)
  end

  # Find a map which score is within [lower <= score <= upper]
  # If more than one map have that score range, then choose random.
  # If no maps in that score range, then return nil.
  # Use option :exclude => [map1.id, map2.id] to ensure that those maps are not returned in the search.
  # Use option :scope => ->(criteria){ ... } to filter the results
  def self.find_random_within_skill(lower, upper, options = {})
    criteria = self.where(:skill_mean.gte => lower, :skill_mean.lte => upper)
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

  # Reassign the score value, based on the skill mean and deviation
  # For maps, the k is 2 instead of 3, because we don't want to make them look easy and be hard at the end.
  # For maps we don't need to be 99% sure that they are better, because they don't really compete for the top positions in the ladder,
  # and we don't want users to challenge maps that seem easy but are not.
  def calculate_score
    self.score = RatingSystem::SCORE_FACTOR * (skill_mean - 2 * skill_deviation)
    self.score = [self.score.to_i, 0].max # ensure not negative
  end

end