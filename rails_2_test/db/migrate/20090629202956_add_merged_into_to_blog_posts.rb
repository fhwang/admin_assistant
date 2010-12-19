class AddMergedIntoToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :merged_into_id, :integer
  end

  def self.down
    remove_column :blog_posts, :merged_into_id
  end
end
