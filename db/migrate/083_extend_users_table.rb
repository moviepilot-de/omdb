require 'digest/sha1'
class OldPrincipal < ActiveRecord::Base
  set_table_name 'principals'
  class <<self
    def group(name)
      find(:first, :conditions => [ "type='Group' and name=?", name ])
    end
    def users
      find(:all, :conditions => [ "type='User'" ], :order => 'created_at desc, id desc')
    end
    def usernames_for_group(group_name)
      connection.select_values "select name from principals, groups_users where type='User' and id=user_id and group_id=#{group(group_name).id}"
    end
  end
end

class Group < OldPrincipal
end

class NewUser <  ActiveRecord::Base
  set_table_name 'users'
  before_save :encrypt_password
  attr_accessor :password

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = self.class.encrypt(password,salt)
  end
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

end

class ExtendUsersTable < ActiveRecord::Migration
  def self.password
    Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )[0..7]
  end
  def self.up
    remove_column :users, :password
    add_column :users, :email,                     :string
    add_column :users, :name,                      :string
    add_column :users, :crypted_password,          :string, :limit => 40
    add_column :users, :salt,                      :string, :limit => 40
    add_column :users, :is_editor,                 :boolean
    add_column :users, :is_admin,                  :boolean
    add_column :users, :updated_at,                :datetime
    add_column :users, :created_at,                :datetime
    add_column :users, :remember_token,            :string
    add_column :users, :remember_token_expires_at, :datetime
    add_column :users, :activation_code,           :string, :limit => 40
    add_column :users, :activated_at,              :datetime
    add_column :users, :password_reset_code,       :string, :limit => 40
    add_column :users, :date_of_birth,             :date
    add_column :users, :country_id,                :integer

    OldPrincipal.users.each do |old_u|
      begin
        puts "migrating #{old_u.name}"
        new_u = NewUser.new(:id => old_u.id, # preserve ids 
                            :login => old_u.name,
                            :email => old_u.email,
                            :name  => old_u.description,
                            :date_of_birth  => old_u.date_of_birth,
                            :country_id  => old_u.country_id,
                            :password => password)
        new_u.save!
      rescue
        puts "couldnt migrate user #{old_u.name}: #{$!}"
      end

    end
    # recreate anonymous user
    execute "delete from users where login='anonymous'"
    execute "insert into users(login, email, name) values ('anonymous', 'anonymous@omdb.org', 'Anonymous user')"

    # migrate groups to editor/admin flags
    OldPrincipal.usernames_for_group('editors').each do |login|
      begin
        NewUser.find_by_login(login).update_attribute(:is_editor, true)
      rescue
        puts "couldnt set editor flag for user #{login}: #{$!}"
      end
    end
    OldPrincipal.usernames_for_group('admins').each do |login|
      begin
        NewUser.find_by_login(login).update_attribute(:is_admin, true)
      rescue
        puts "couldnt set editor flag for user #{login}: #{$!}"
      end
    end

    # activate users
    execute "update users set activated_at=NOW(), activation_code=null where login != 'anonymous'"
  end

  def self.down
    NewUser.delete_all
    add_column :users, :password, :string
    remove_column :users, :email
    remove_column :users, :name
    remove_column :users, :is_editor
    remove_column :users, :is_admin
    remove_column :users, :crypted_password
    remove_column :users, :salt
    remove_column :users, :created_at
    remove_column :users, :updated_at
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
    remove_column :users, :activation_code
    remove_column :users, :activated_at
    remove_column :users, :password_reset_code
    remove_column :users, :date_of_birth
    remove_column :users, :country_id
  end
end
