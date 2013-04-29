class Place < ActiveRecord::Base
  attr_accessible :latitude, :longitude, :path
  serialize :geocode, JSON
end
