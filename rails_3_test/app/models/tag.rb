class Tag < ActiveRecord::Base
  validates_format_of :tag, :with => /^\w+$/
  validates_uniqueness_of :tag
end
