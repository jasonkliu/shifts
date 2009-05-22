require 'net/ldap'
class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :departments

  validates_presence_of :name
  validates_presence_of :netid
  validates_uniqueness_of :netid
  validate :departments_not_empty

  def self.import_from_ldap(netid, should_save = false)
    # Setup our LDAP connection
    ldap = Net::LDAP.new( :host => "directory.yale.edu", :port => 389 )
    begin
      # We filter results based on netid
      filter = Net::LDAP::Filter.eq("uid", netid)
      new_user = User.new(:netid => netid)
      ldap.open do |ldap|
        # Search, limiting results to yale domain and people
        ldap.search(:base => "ou=People,o=yale.edu", :filter => filter, :return_result => false ) do |entry|
          # Make sure only 1 record is found
          new_user.first_name = entry['givenname'].first
          new_user.last_name  = entry['sn'].first
          new_user.email = entry['mail'].first
          new_user.name = new_user.full_name if new_user.name.blank?
        end
      end
      new_user.save if should_save
    rescue Exception => e
      new_user.errors.add_to_base "LDAP Error #{e.message}" # Will trigger an error, LDAP is probably down
    end
    new_user
  end

  def self.mass_add(netids)
    failed = []

    netids.split(/\W+/).map do |n|
      user = import_from_ldap(n, true)
      #error message, hopefully
      if user.new_record?
        failed << "From netid #{user.netid}: #{user.errors.full_messages.to_sentence}"
      end
    end

    failed
  end

  def full_name
    [first_name, last_name].join(" ")
  end
  private

  def roles_not_empty
    errors.add("User must have at least one role.", "") if roles.empty?
  end

  def departments_not_empty
    errors.add("User must have at least one department.", "") if departments.empty?
  end
end

