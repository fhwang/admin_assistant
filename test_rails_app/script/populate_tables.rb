#!/usr/bin/env ruby

require 'config/boot'
require 'config/environment'

def random_word
  @chars ||= 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.
             split(//)
  (1..25).to_a.map { @chars[rand(@chars.size)] }.join
end

belongs_to_associations = {
  BlogPost => [User], Comment => [User, BlogPost]
}
has_many_associations = {BlogPost => [Tag]}
[Tag, User, Product, BlogPost, Comment].each do |model_class|
  string_text_columns = model_class.columns.select { |c|
    [:string, :text].include?(c.type)
  }
  count = model_class.count
  max = model_class == BlogPost ? 251 : 100
  count.upto(max) do
    saved = false
    until saved
      atts = {}
      string_text_columns.each do |c|
        atts[c.name] = random_word
      end
      if belongs_to_associations[model_class]
        belongs_to_associations[model_class].each do |assoc_model|
          atts[assoc_model.name.underscore] = assoc_model.find(
            :first, :order => 'rand()'
          )
        end
      end
      if has_many_associations[model_class]
        has_many_associations[model_class].each do |assoc_model|
          atts[assoc_model.name.underscore.pluralize] = (1..5).to_a.map {
            assoc_model.find :first, :order => 'rand()'
          }.uniq
        end
      end
      model = model_class.new atts
      saved = model.save
    end
  end
end
