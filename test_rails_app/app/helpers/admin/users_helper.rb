module Admin::UsersHelper
  def after_password_input(user)
    if user.id
      "Reset #{check_box_tag('reset_password')}"
    end
  end
  
  def password_input(user)
    if !user.id
      "(autogenerated)"
    end
  end
  
  def tmp_avatar_exists?(user)
    user.has_avatar?
  end
  
  def tmp_avatar_html_for_index(user)
    image_tag(tmp_avatar_url(user)) if user.has_avatar?
  end
  
  def tmp_avatar_url(user)
    "http://my-image-server.com/users/#{user.id}.jpg?v=#{user.avatar_version}"
  end
end
