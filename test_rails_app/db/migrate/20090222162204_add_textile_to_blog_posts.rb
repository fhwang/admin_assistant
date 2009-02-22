class AddTextileToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :textile, :boolean
  end

  def self.down
    remove_column :blog_posts, :textile
  end
end
