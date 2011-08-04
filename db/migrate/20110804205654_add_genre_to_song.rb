class AddGenreToSong < ActiveRecord::Migration
  def self.up
    add_column :songs, :genre, :string
  end

  def self.down
    remove_column :songs, :genre
  end
end
