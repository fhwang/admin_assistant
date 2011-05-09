class Admin::TelevisionAiringsController < ApplicationController
  layout 'admin'

  admin_assistant_for TelevisionAiring
end
