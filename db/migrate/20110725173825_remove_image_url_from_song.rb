class RemoveImageUrlFromSong < ActiveRecord::Migration
  def self.up
    remove_column :songs, :image
  end

  def self.down
    add_column :songs, :image, :string
  end
end
