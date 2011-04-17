class Bookmark < ActiveRecord::Base
  belongs_to :user
  belongs_to :bookmarkable, :polymorphic => true
  
  validates_presence_of :user_id, :bookmarkable_id, :bookmarkable_type
end
