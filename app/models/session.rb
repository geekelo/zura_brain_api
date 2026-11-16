class Session < ApplicationRecord
  belongs_to :client

  belongs_to :session_creator,
             class_name: "Therapist",
             optional: true

  has_many :session_therapists,
           dependent: :destroy

  has_many :session_activities,
           dependent: :destroy

  has_many :payment_methods,
           -> { where(deleted_at: nil) },
           dependent: :destroy

  has_many :therapists,
           through: :session_therapists

  accepts_nested_attributes_for :session_therapists,
                                allow_destroy: true

  scope :by_cycle, -> { order(:cycle, :cycle_length) }

  def as_json(options = nil)
    options = (options || {}).deep_dup
    included = options[:include].is_a?(Hash) ? options[:include] : {}
    included[:payment_methods] ||= {}
    options[:include] = included
    super(options)
  end

  before_create :generate_session_code
  before_create :initialize_comments

  private

  def generate_session_code
    self.session_code = SecureRandom.uuid if session_code.blank?
  end

  def initialize_comments
    self.comments = [] if comments.blank?
  end
end