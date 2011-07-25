class Song < ActiveRecord::Base
  validates :title, :uniqueness => {:scope => :artist}
end
