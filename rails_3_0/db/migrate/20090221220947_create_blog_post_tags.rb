class CreateBlogPostTags < ActiveRecord::Migration
  def self.up
    create_table :blog_post_tags do |t|
      t.integer :blog_post_id
      t.integer :tag_id

      t.timestamps
    end
  end

  def self.down
    drop_table :blog_post_tags
  end
end
