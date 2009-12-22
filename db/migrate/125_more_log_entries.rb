class MoreLogEntries < ActiveRecord::Migration
  def self.up
    [ Person, Category, Country, Character, Company, Image, Job ].each do |klass|
      klass.find_all.each do |o|
        puts klass.to_s
        o.log_entries.create( :attribute => "self", :ip_address => 'unknown', :user => User.anonymous ) if o.log_entries.empty?
      end
    end
  end

  def self.down
  end
end
