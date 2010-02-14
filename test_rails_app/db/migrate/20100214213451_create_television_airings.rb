class CreateTelevisionAirings < ActiveRecord::Migration
  def self.up
    create_table :television_airings do |t|
      t.integer :television_time_slot_id
      t.string :title
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :television_airings
  end
end
