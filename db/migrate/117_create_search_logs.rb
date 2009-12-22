class CreateSearchLogs < ActiveRecord::Migration
  def self.up
    create_table :search_logs do |t|
      t.column 'query', :string
      t.column 'results', :integer
      t.column 'method', :string
      t.column 'created_at', :datetime
    end
  end

  def self.down
    drop_table :search_logs
  end
end
