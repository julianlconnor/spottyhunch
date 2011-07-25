class AddFieldsToSong < ActiveRecord::Migration
  def self.up
    add_column :songs, :trackUrl, :string
    add_column :songs, :artistUrl, :string
    add_column :songs, :image, :string
    rename_column :songs, :title, :track
  end

  def self.down
  end
end
