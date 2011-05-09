class ChangeBlogPostsTextile < ActiveRecord::Migration
  def self.up
    change_column :blog_posts, :textile, :boolean, :default => false
  end

  def self.down
    change_column :blog_posts, :textile, :boolean
  end
end
