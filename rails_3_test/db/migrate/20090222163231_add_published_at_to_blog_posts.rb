class AddPublishedAtToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :published_at, :datetime
  end

  def self.down
    remove_column :blog_posts, :published_at
  end
end
