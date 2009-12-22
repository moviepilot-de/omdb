class Trailer < ActiveRecord::Base
  include Freezable

  belongs_to :movie
  belongs_to :language

  freezable_attribute :key

  depending_objects [ :movie ]

  validates_presence_of :movie, :language, :key
  
  validates_length_of :key, :minimum => 10

  validates_uniqueness_of :language_id, :scope => [ :movie_id ]
  
  validates_inclusion_of :source, :in => [ 'youtube' ]
  
  validates_each [ :key ] do |record, attr, value|
    record.errors.add attr, "invalid #{record.type} video id" unless record.valid_key? 
  end
  
  def to_flash_url
    case source.to_sym
      when :google
        "not supported yet"
      when :youtube
        return "http://www.youtube.com/v/" + key 
    end
  end
  
  def to_url
    "http://www.youtube.com/watch?v=" + key
  end
  
  def valid_key?
    http = Net::HTTP.new("www.youtube.com", 80)
    path = "/watch?v=" + key
    resp, data = http.get(path)
    return (resp.code == "200")
  end
end

