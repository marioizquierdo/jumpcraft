class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Id of the "infiltration" user. It is a constant, because is used to find trial maps.
  INFILTRATION_USER_ID = "5340a9730482933613000001"
  TRIAL_GAMES_BEFORE_REGULAR_SUGGESTIONS = 5 # number of trial maps that the user needs to play before going against other user's maps

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :token_authenticatable,
    :registerable, :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :created_at, :updated_at, :authentication_token

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

  has_many :maps, inverse_of: :creator

  after_build :calculate_score
  before_save :calculate_score

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

  ## Token authenticatable
  field :authentication_token, type: String
  before_save :ensure_authentication_token

  # run 'rake db:mongoid:create_indexes' to create indexes
  index({ email: 1 }, { unique: true, background: true })
  index({ authentication_token: 1 }, { unique: true, background: true })

  # Rebuild the infiltration user in the DB
  def self.recreate_infiltration_user
    u = self.get_infiltration_user
    u.destroy if u
    self.create_infiltration_user!
  end

  # Factory method to create the infiltration user
  def self.create_infiltration_user!
    u = self.new(
      name: 'infiltration',
      score: 1000,
      email: 'infiltration@infiltration.com',
      password: 'none'
    )
    u.id = INFILTRATION_USER_ID # ensure id is known, so Map.trial scope works as expected
    u.save!
    u
  end

  def self.get_infiltration_user
    self.where(_id: INFILTRATION_USER_ID).first
  end

  # Reassign the score value, based on the skill mean and deviation
  def calculate_score
    self.score = RatingSystem.calculate_score(self.skill_mean, self.skill_deviation)
  end
end
