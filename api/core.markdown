---
layout:   default
title:    "API: Core"
subnav:   api
subtitle: Core
---


### Includes

admin\_assistant comes with its own Javascript and CSS. Call `admin_assistant_includes` in your admin layout to use them:

    <html>
      <head>
        <%= admin_assistant_includes %>
      </head>
      ...
    </html>

You also have the option of making admin\_assistant look very similar to activescaffold CSS-wise, which might come in handy if you're in the process of transition from one to the other:

    <%= admin_assistant_includes :theme => 'activescaffold' %>

Submissions of other themes are welcome.

### Configuring the core builder object

<a name="builder_actions"> </a>
#### actions

admin\_assistant uses the old-fashioned seven Rails actions: index, show, new/create, edit/update, and destroy. By default, you get all of them except destroy. To add destroy, you can simply append it to the `actions` method:

    admin_assistant_for User do |aa|
      aa.actions << :destroy
    end

You can also send `actions` a list of actions and it will only allow those:

    # I only want to create or index images, not edit, show or destroy
    admin_assistant_for Image do |aa|
      aa.actions :create, :index
    end

### model\_class\_name

Use this to override what the model is named in the interface, in links like "New blog post" or "50 blog posts found". The string passed in should be lowercase.

    aa.model_class_name = 'post'

    
### Column config options

#### boolean\_labels

    aa[:textile].boolean_labels = %w(Yes No)

For a boolean fields, will change how the values get displayed, instead of simply "true" and "false".

#### label

    aa[:user].label = 'Author'

    
Overrides the default label for that column in index, search, and form views.

#### polymorphic\_types

    aa[:bookmarkable].polymorphic_types = [BlogPost, Comment, Product, User]    

If a column is a polymorphic association, admin\_assistant will offer specific widgets for searching and editing this column. With `polymorphic_types` you can tell it what possible types the association can be set to.

#### strftime\_format

    aa[:published_at].strftime_format = "%b %d, %Y %H:%M:%S"
    
If the column is a date or time, this will use the given strftime format for displaying the column in index and shows views.

### Helper methods

#### \[column\]\_value

Determines what value is passed to form inputs, index views, etc, for the individual column. This is most useful for a virtual column.



### Model methods

#### name\_for\_admin\_assistant

When dealing with associations, admin\_assistant needs a convenient way to display a given record. By default, it will look for a method with the name `name`, `title`, `login`, or `username`. If you'd like to provide custom functionality across all admin\_assistant controllers, define the method `name_for_admin_assistant` on the model.

For example, let's say you have a ProductCategory class with a field `category_name`. With the code below, any time a product category is referred to through an association, admin\_assistant will display the `category_name`, in index views, form selects, etc.

    class ProductCategory < ActiveRecord::Base
      def name_for_admin_assistant
        self.category_name
      end
    end

#### sort\_value\_for\_admin\_assistant

When showing associated records, admin\_assistant will sort by the method `sort_value_for_admin_assistant` if it's defined on the model. This comes in handy if you want to specify sorting on form drop-downs for belongs-to associations.

    class Appointment < ActiveRecord::Base
      def sort_value_for_admin_assistant
        self.time
      end
    end

