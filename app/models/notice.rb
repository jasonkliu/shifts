class Notice < ActiveRecord::Base

  belongs_to :author, :class_name => "User"
  belongs_to :remover, :class_name => "User"

  belongs_to :department

  validates_presence_of :content
  validate_on_create :proper_time
  validate :presence_of_locations_or_viewers

  named_scope :inactive, lambda {{ :conditions => ["end_time < ?", Time.now.utc] }}
  named_scope :active_with_end, lambda {{ :conditions => ["start_time < ? and end_time > ?", Time.now.utc, Time.now.utc]}}
  named_scope :active_without_end, lambda {{ :conditions => ["start_time < ?", Time.now.utc]}}
  named_scope :upcoming, lambda {{ :conditions => ["start_time > ?", Time.now.utc]}}

  def self.active
    (self.active_with_end + self.active_without_end).uniq.sort_by{|n| n.start_time}.reverse
  end

  def display_for
    display_for = []
    display_for.push "for users #{self.viewers.collect{|n| n.name}.to_sentence}" unless self.viewers.empty?
    display_for.push "for locations #{self.display_locations.collect{|l| l.short_name}.to_sentence}" unless self.display_locations.empty?
    display_for.join "<br/>"
  end

  def is_current?
    if self.end_time
      self.start_time < Time.now && self.end_time > Time.now
    else
      self.start_time < Time.now
    end
  end

  def viewers
    self.user_sources.collect{|us| us.users}.flatten.uniq
  end

  def display_locations
    self.location_sources.collect{|ls| ls.locations}.flatten.uniq
  end

  def remove(user)
    self.errors.add_to_base "This notice has already been removed by #{remover.name}" and return if self.remover && self.end_time
    self.end_time = Time.now
    self.remover = user
    true if self.save
  end

  private
  #Validations
  def presence_of_locations_or_viewers
    unless self.new_record?
      errors.add_to_base "Your notice must display somewhere or for someone." if self.location_sources.empty? && self.user_sources.empty?
    end
  end

  def proper_time
    errors.add_to_base "Start/end time combination is invalid." if self.start_time >= self.end_time if self.end_time || Time.now >= self.end_time if self.end_time
  end
end

