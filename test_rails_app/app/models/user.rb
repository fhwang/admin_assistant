class User < ActiveRecord::Base
  has_many :blog_posts
  
  def reset_password
    letters = 'abcdefghijklmnopqrstuvwxyz'.split //
    random_passwd = (1..10).to_a.map { letters[rand(letters.size)] }.join('')
    self.password = random_passwd
  end
end
