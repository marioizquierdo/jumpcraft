class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Id of the "Jumpcraft" user. It is a constant, because is used to find trial maps.
  JUMPCRAFT_USER_ID = "5340a9730482933613000001"

  # Devise config
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  ## -------------------

  field :name, type: String
  validates_presence_of :name

  field :tutorial, type: Integer, default: 0 # increments after playing each tutorial
  field :score, type: Integer, default: 500 # score is adjusted during the placement matches and then playing ladder maps
  field :skill_mean, type: Float, default: RatingSystem::USER_INITIAL_SKILL_MEAN # from TrueSkill, assumed to be between 0 and 50
  field :skill_deviation, type: Float, default: RatingSystem::USER_INITIAL_SKILL_DEVIATION  # from TrueSkill, standard deviation of the mean, in order to define the Gaussian Distribution
  field :coins, type: Integer, default: 0
  field :played_games, type: Integer, default: 0 # number of games played in the ladder
  field :won_games, type: Integer, default: 0 # number of defeated maps in the ladder
  field :suggested_map_ids, type: Array # memory for last suggested maps, invalidated after playing one of them

  has_many :maps, inverse_of: :creator, dependent: :destroy
  has_many :games, dependent: :delete

  index score: -1, coins: -1 # for ladder
  index email: 1 # for login

  after_build :calculate_score, unless: :skip_calculate_score_callback
  before_save :calculate_score, unless: :skip_calculate_score_callback
  attr_accessor :skip_calculate_score_callback # set to true on tests to skip calculate_score callback

  ## -------------------

  ## Database authenticatable
  field :email,              type: String, default: ''
  field :encrypted_password, type: String, default: ''

  validates_presence_of :email
  validates_presence_of :encrypted_password

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  # run 'rake db:mongoid:create_indexes' to create indexes
  index({ email: 1 }, { unique: true, background: true })
  index({ authentication_token: 1 }, { unique: true, background: true })

  # Rebuild the "Jumpcraft" user in the DB
  def self.recreate_jumpcraft_user
    u = self.get_jumpcraft_user
    u.destroy if u
    self.create_jumpcraft_user!
  end

  # Factory method to create the jumpcraft user
  def self.create_jumpcraft_user!
    u = self.new(
      name: 'Jumpcraft',
      email: 'jumpcraft@jumpcraft.com',
      password: 'none'
    )
    u.id = JUMPCRAFT_USER_ID # ensure id is known, so Map.trial scope works as expected
    u.save!
    u
  end

  def self.get_jumpcraft_user
    self.where(_id: JUMPCRAFT_USER_ID).first
  end

  # Given a map, return the difficutly: :easy, :medium, :hard, etc.
  # If there is not enough confidence about it (high user or map skill_deviation), then return :unknown
  def difficulty_of_playing(map)
    return :unknown unless map # ensure map is not nil
    return map.trial_difficulty if map.trial_difficulty && map.trial? # trial map suggestions have fixed difficulty
    return :unknown unless self.skill_mean # ensure not nil value errors
    return :unknown if self.skill_deviation > 4 # more deviation means that we really don't know yet if the skill_mean is accurate
    return map.dificulty_relative_to(self.skill_mean)
  end

  # Reassign the score value, based on the skill mean and deviation
  # For users, use the same method as in Xbox Live: mean - 3 * deviation
  def calculate_score
    self.score = RatingSystem::SCORE_FACTOR * (skill_mean - RatingSystem::SCORE_MEAN_DEVIATION_K * skill_deviation)
    self.score = [self.score.to_i, 0].max # ensure not negative
  end

  # Attributes to be serialized as JSON for the flash player
  def attrs_for_flash
    {
      _id:                  self._id.to_s,
      name:                 self.name,
      authentication_token: self.authentication_token, # unsafe, but this is what we are using for the prototype
      coins:                self.coins,
      played_games:         self.played_games,
      won_games:            self.won_games,
      tutorial:             self.tutorial,
      score:                self.score,
      skill_mean:           self.skill_mean,
      skill_deviation:      self.skill_deviation,
      suggested_map_ids:    (self.suggested_map_ids || []).map{|_id| _id.to_s},
    }
  end



  ## Token authenticatable
  ## Devise 3.2.0 removed support for (insecure) :token_authenticatable,
  ## this is a pollifyl for that functionality after updating to Rails 4 and latest Devise

  field :authentication_token, type: String
  before_save :ensure_authentication_token
  
  def self.find_by_authentication_token(authentication_token = nil)
    if authentication_token
      where(authentication_token: authentication_token).first
    end
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def reset_authentication_token!
    self.authentication_token = generate_authentication_token
    self.save
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless self.class.unscoped.where(authentication_token: token).first
    end
  end

end
