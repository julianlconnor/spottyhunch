class Song < ActiveRecord::Base
  validates :track, :uniqueness => {:scope => :artist}
end
