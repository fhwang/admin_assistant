class AddForceTextileToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :force_blog_posts_to_textile, :boolean
  end

  def self.down
    remove_column :users, :force_blog_posts_to_textile
  end
end
