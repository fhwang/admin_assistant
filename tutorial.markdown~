---
layout: default
title:  Tutorial
---

<div class="note">
This document assumes you are a beginning Rails user; if you are familiar with Rails you might want to check out our <a href="/admin_assistant/quick_start.html">quick start</a>.
</div>

1) Add the gem to `Gemfile` in the root of your Rails project.

    gem 'admin_assistant'
    
2) Install the gem locally.

    $ bundle install
    
3) admin\_assistant uses jQuery. You may already have jQuery installed for your project, but if not, you can get it like so:

    $ curl http://code.jquery.com/jquery-1.6.2.min.js > \
        public/javascripts/jquery-1.6.2.min.js

4) If you don't have any admin controllers in your Rails project yet, you probably need to create a separate admin layout. Create a file called `app/views/layouts/admin.html.erb` like this:

    <html>
      <head>
        <%= javascript_include_tag("jquery-1.6.2.min") %>
        <%= admin_assistant_includes %>
      </head>
      <body>
        <%= yield %>
      </body>
    </html>
    
If you've already created an admin layout, you should add the javascript references, and the call to `admin_assistant_includes`. This includes the standard CSS and Javascript that are packed with admin\_assistant.
    
5) Create your new admin controller for a pre-existing model. We'll be using a BlogPost as an example but you should be able to use any model in your Rails app.

    ./script/generate controller admin/blog_posts
    
6) Open `app/controllers/admin/blog_posts_controller.rb` and set it up to use the admin layout and to use admin\_assistant for the BlogPost model:

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost
    end

7) If you were already running your Rails app with `./script/server` etc, you should restart it.

8) Visit `/admin/blog_posts` in your browser and you'll see something like this:

![index](/admin_assistant/img/blog_posts-index.png)

You can now search, paginate, create, and edit blog posts.

Depending on the model you're using, you might notice a few things:

* Boolean values can be toggled on and off in the index view.
* Any belongs-to associations are handled in the form by either a drop-down, or an Ajax autocompleter, depending on how many choices there are for the association.
* There is no `destroy` action out of the box. This is intended as a safe default, but you can add it if you like.
* If you have more than 10 pages of a given model, the pagination at the bottom includes a jump form to let you automatically jump to a page you enter.

For more, check out the [API reference](/admin_assistant/api/).

