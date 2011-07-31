class AddBodyToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :body, :text
  end

  def self.down
    remove_column :blog_posts, :body
  end
end
