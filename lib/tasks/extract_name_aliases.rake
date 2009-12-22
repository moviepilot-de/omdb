task :extract_name_aliases => :environment do
  table_name = 'name_aliases'
  sql = "SELECT * FROM %s"
  ActiveRecord::Base.establish_connection
  i = "000"
  File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", 'w' ) do |file|
    data = ActiveRecord::Base.connection.select_all(sql % table_name)
    file.write data.inject({}) { |hash, record|
      hash["#{table_name}_#{i.succ!}"] = record
      hash
    }.to_yaml
  end
end

