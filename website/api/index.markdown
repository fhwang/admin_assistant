---
layout: api
---

### Reference sections

The API reference is broken down into a few sections:

* [Core](./core.html): Settings that apply to an admin controller in general.
* [Destroy](./destroy.html): Settings that apply to destroying records. Note that `destroy` is turned off by default. To turn it on, use the core [actions](./core.html#builder_actions) method.
* [Form](./form.html): Settings that apply to creating or updating records.
* [Index](./idx.html): Settings that apply to the index view, which you use to view records, paginate, and sort.
* [Search](./search.html): Settings that apply to how searches work.
* [Show](./show.html): Settings that apply to how the show view.


### Configuration overview


There are a number of ways to configure admin\_assistant:

#### Through builder objects

`admin_assistant_for` takes a block that yields a core builder object:

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost do |aa|
        aa.model_class_name = 'post'
      end
    end

For the actions `form` and `index`, you can get a nested builder from the core builder, which can be used to configure those individual action types.

    admin_assistant_for BlogPost do |aa|
      aa.index do |index|
        index.sort_by "name asc"
      end
    end

The nesting is intended to help organize your configuration code, but if you're in a hurry, you can also just chain the calls:

    admin_assistant_for BlogPost do |aa|
      aa.index.sort_by "name asc"
    end

Since `search` is really a subset of `index`, its configuration builder is reached through the index builder.

    admin_assistant_for BlogPost do |aa|
      aa.index do |index|
        index.search do |search|
          search.columns :id, :title, :body
        end
      end
    end

#### Columns on builder objects

Columns are specified on the action-types `index`, `form`, or `search`:

    admin_assistant_for BlogPost do |aa|
      aa.index.columns :id, :title, :body
    end
    
There is no global `columns` setting.

These columns can be accessed with `[]`, either globally, or specific to an action-type, depending on what sort of setting is being altered.

    admin_assistant_for BlogPost do |aa|
      # this will apply to the :title column, both on form and index views
      aa[:title].label = "Headline"  
    
      aa.form do |form|
        form.columns :id, :title, :body
        
        # This will only apply to the :title column in the form view
        form[:title].description = "Enter the headline of your blog post here."
      end
    end

If you're dealing with an association, generally speaking, you'll use the column of the association name, not the foreign key ID in the database.

    admin_assistant_for BlogPost do |aa|
      aa.index.columns :id, :title, :user   # as opposed to :user_id
    end

#### Protected controller methods

For certain types of settings, the `form` and `index` action types can be customized through protected methods on the controller.

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost
      
      protected
      
      # The index action only shows unpublished blog posts, unless somebody has
      # clicked the custom "Show All" link
      def conditions_for_index
        "published_at is null" unless params[:all]
      end
    end

Remember to make these methods protected so that Rails won't try to use them as public-facing actions, i.e. `http://www.example.com/admin/blog_posts/conditions_for_index`.

In a number of cases, you can get the same customization by passing a block to the builder object. For example, the code below works the same as the previous example:

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost do |aa|
        aa.index.conditions do |params|
          "published_at is null" unless params[:all]
        end
      end
    end

The trade-off here is that customizing this behavior through a block is probably a little neater---fewer methods scattered all over your controller---but isn't bound to the controller. So if you find yourself needing some convenience methods on, say, `ApplicationController`, you'll be better off using a protected controller method.

#### Helper methods and partials

Other behaviors can be set by creating certain methods on the helper. Usually these behaviors have to do with presentation.

    class Admin::UsersHelper
      def password_input(user)
        password_field_tag("user[password]", user.password, :disabled => true)
      end
    end

Often you can accomplish the same thing with a partial. For example, the functionality in the above example could also be accomplished with the following saved in `app/views/admin/users/_password_input.html.erb`.

    <%= password_field_tag("user[password]", user.password, :disabled => true) %>
    
#### Model methods

admin\_assistant can also look for methods to be defined on models, themselves. This is generally for behaviors that would apply across all admin controllers.

    class ProductCategory < ActiveRecord::Base
      def name_for_admin_assistant
        self.category_name
      end
    end

Generally speaking there won't be many of these hooks, because in practice this can make the admin\_assistant API sort of invasive. Unless your Rails project is 99% the admin interface, it's going to get annoying to keep tripping over admin\_assistant-specific hooks when you're trying to write some front-facing code.

