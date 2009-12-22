class RatingHistory < ActiveRecord::Base
  belongs_to :related_object, :polymorphic => true

  
end
