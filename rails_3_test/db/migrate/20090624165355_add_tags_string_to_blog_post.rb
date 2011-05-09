class AddTagsStringToBlogPost < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :tags_string, :string
  end

  def self.down
    remove_column :blog_posts, :tags_string
  end
end
