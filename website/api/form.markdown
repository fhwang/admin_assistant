---
layout: api
title:  Form
---

![form](../img/user-form.png)

Form configuration affects both creating new records and updating existing records. Most of its customization happens through the form builder object:


    class Admin::BlogPostsController < ApplicationController
      admin_assistant_for BlogPost do |a|
        a.form do |form|
          form.columns :user, :title, :body
        end
      end
    end

### Form config options

#### columns

    form.columns :user, :title, :body

Shows only these columns in the form.

#### columns\_for\_edit

    form.columns_for_edit :title, :user, :published_at, :body, :merged_into

Shows only these columns in the edit action.


#### columns\_for\_new

    form.columns_for_new  :title, :user, :published_at

Shows only these columns in the new action.


#### submit\_buttons

    form.submit_buttons << 'Preview'

    
By default, there is one button at the bottom of the form, saying either "Create" or "Update". By appending to this array you can specify other buttons, and then check if those buttons were clicked in `destination_after_save`, below.

### Column config options

#### datetime\_select\_options

    form[:published_at].datetime_select_options =
        {:include_blank => false, :start_year => 2009}

Passes through these options to the datetime select for this column. By default this is set to `{:include_blank => true}`.

#### default

    form[:published_at].default do |controller|
      controller.default_published_at
    end

Sets a default value for the column when rendering the new form.

        
#### description

    form[:publish].description = "Click this check box to publish this blog post."

Sets descriptive text that will appear next to the column's input.

#### image\_size

    form[:image].image_size = '300x500'

By default, [Paperclip] and [FileColumn] image files are rendered at full-size in the form. To restrict their size, pass a size string to `image_size`.

#### input

    form[:publish].input = :check_box

Currently only supports `:check_box` and `:us_state`. `:check_box` is most useful for virtual columns right now. `:us_state` will render a drop-down with U.S. states.

#### nilify\_link

Date and datetime fields come with a javascript link the clears the value in the date or datetime selects. The text of this link is "Set \[column name\] to nil" by default, but you may want to customize this text:

    form[:sale_starts_at].nilify_link = 'Not on sale'


#### read\_only

    a.form[:comment].read_only

If this is set, the given column will only be displayed, and not editable.


#### select\_options

    form[:user].select_options = {:include_blank => false}

Use this with belongs-to associations to tell admin\_assistant how to configure the `select` dropdown for the associated field. By default, this is set to `{:include_blank => true}`.

#### text\_area\_options

    form[:body].text_area_options = {:cols => 20, :rows => 40}

Sets options to pass through to the text area that will be rendered for this column.

#### write\_once

    form[:body].write_once
    
If this is set, the given column will only be editable on the new page, not on the edit page.


### Controller methods

#### after\_save

Runs after the record is saved.

#### before\_create

Runs before the record is created.

#### before\_save

    def before_save(blog_post)
      if params[:blog_post][:publish] && blog_post.published_at.nil?
        blog_post.published_at = Time.now.utc
      end
    end

Runs before the record is saved.

#### before\_update

Runs before the record is updated.

#### \[column\]\_exists?

Used for image fields in generating form pages. If this method exists on the controller, it will be called to see if the image exists. You'll probably use this in conjunction with `[column]_url` and `destroy_[column]_in_attributes`.

    def tmp_avatar_exists?(user)
      user.has_avatar?
    end

#### \[column\]\_url

Used for image fields in generating form pages. If the existing record has an image, and this method exists on the controller, it will be called to get the URL that should be rendered. You'll probably use this in conjunction with `[column]_exists?` and `destroy_[column]_in_attributes`.

    def tmp_avatar_url(user)
      "http://my-image-server.com/users/#{user.id}.jpg?v=#{user.avatar_version}"
    end



#### \[column\]\_from\_form

    def tags_from_form(tags_strings)
      tags_strings.split(/\s+/).map { |tag_str|
        Tag.find_by_tag(tag_str) || Tag.create(:tag => tag_str)
      }
    end

Should return a value suitable for assignment. In the above example, a BlogPost has-many tags, and the method tags\_from\_form will turn the string `"funny, video, lolcat"` into an array of three Tag model records, so admin\_assistant can set BlogPost#tags to that array.

#### destination\_after\_save

    def destination_after_save(blog_post, params)
      if params[:commit] == 'Preview'
        {:action => 'edit', :id => blog_post.id, :preview => '1'}
      end
    end

This method should return a hash to redirect to after a successful save. If it returns nil, the default is to return to the index page.

#### destroy\_\[column\]\_in\_attributes

Used for image fields. If a file field already exists, and the user clicks on the checkbox to delete this file, this method will be called if it's defined. You'll probably use this in conjunction with `[column]_exists?` and `[column]_exists?`.

    def destroy_tmp_avatar_in_attributes(attributes)
      attributes[:has_avatar] = false
    end


### Helper methods

#### after\_\[column\]\_input

If this helper method is present, whatever text it returns will be rendered after the default input for the column in the form. Takes the record as its only argument. You can also create a partial named `_after_[column]_input.html.erb`.

    def after_password_input(user)
      if user.id
        "Reset #{check_box_tag('reset_password')}"
      end
    end

#### \[column\]\_input

If this helper method is present, whatever text it returns will be rendered instead of the default input for the column in the form. If it returns nil, the default input will be rendered instead. Takes the record as its only argument.

    def password_html_for_form(user)
      if !user.id
        "(autogenerated)"
      end
    end

You can also create a partial named `_[column]_input.html.erb`.

#### \[column\]\_string

If this helper method is present, its returned string will be rendered within a text field. Odds are you'll use this with the controller method `[column]_from_form`, above.

    def tags_string(blog_post)
      blog_post.tags.map { |tag| tag.tag }.join ' '
    end


### Partials

#### \_\[column\]\_input.html.erb

If this partial is present, it will be rendered instead of the default input for the column. 

#### \_after\_\[column\]\_input.html.erb


If this partial is present, it will be rendered after the default input for the column. You can also use the helper method `after_[column]_input`.

#### \_after\_form.html.erb

If this partial is present in the controller's views directory, it will be rendered after the normal form.


[FileColumn]: http://www.kanthak.net/opensource/file_column/
[Paperclip]: http://thoughtbot.com/projects/paperclip

