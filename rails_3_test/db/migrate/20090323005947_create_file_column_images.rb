class CreateFileColumnImages < ActiveRecord::Migration
  def self.up
    create_table :file_column_images do |t|
      t.string :image
      t.timestamps
    end
  end

  def self.down
    drop_table :file_column_images
  end
end
