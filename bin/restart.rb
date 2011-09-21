while(true)
unless `curl -I http://www.omdb.org/movie`.include?("200 OK")
  puts  `sudo /etc/init.d/mongrel_cluster start`
  puts "restarted at #{ Time.now }"
end
sleep 5
puts "repeating. "
end
