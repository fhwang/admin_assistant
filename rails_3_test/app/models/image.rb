class Image < ActiveRecord::Base
  has_attached_file :image, :url => "/:attachment/:id/original/:basename.:extension"
end
