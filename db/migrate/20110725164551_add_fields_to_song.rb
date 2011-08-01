class AddFieldsToSong < ActiveRecord::Migration
  def self.up
    add_column :songs, :trackUrl, :string
    add_column :songs, :artistUrl, :string
    add_column :songs, :image, :string
    rename_column :songs, :title, :track
  end

  def self.down
    remove_column :songs, :trackUrl
    remove_column :songs, :artistUrl
    remove_column :songs, :image
    rename_column :songs, :track, :title
  end
end
