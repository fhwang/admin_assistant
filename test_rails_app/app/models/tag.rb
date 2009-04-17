class Tag < ActiveRecord::Base
  validates_uniqueness_of :tag
end
