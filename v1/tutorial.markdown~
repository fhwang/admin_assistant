---
layout: default
title:  "Tutorial: admin_assistant 1"
---

<div class="note">
This document assumes you are a beginning Rails user; if you are very familiar with Rails you might want to check out our <a href="/admin_assistant/v1/quick_start.html">quick start</a>.
</div>

1) First, install the plugin from Github.

    ./script/plugin install git://github.com/fhwang/admin_assistant.git

2) If you don't have the popular will\_paginate gem, you'll need that too. See [http://wiki.github.com/mislav/will_paginate/installation](http://wiki.github.com/mislav/will_paginate/installation) for more info.

3) If you don't have any admin controllers in your Rails project yet, you probably need to create a separate admin layout. Create a file called `app/views/layouts/admin.html.erb` like this:

    <html>
      <head>
        <%= javascript_include_tag("prototype", "effects", "controls") %>
        <%= admin_assistant_includes %>
      </head>
      <body>
        <%=yield %>
      </body>
    </html>
    
If you've already created an admin layout, you should add the javascript references, and the call to `admin_assistant_includes`. This includes the standard CSS and Javascript that are packed with admin\_assistant.
    
4) Create your new admin controller for a pre-existing model. We'll be using a BlogPost as an example but you should be able to use any model in your Rails app.

    ./script/generate controller admin/blog_posts
    
5) Open `app/controllers/admin/blog_posts_controller.rb` and set it up to use the admin layout and to use admin\_assistant for the BlogPost model:

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost
    end

6) If you were already running your Rails app with `./script/server` etc, you should restart it.

7) Visit `/admin/blog_posts` in your browser and you'll see something like this:

![index](/admin_assistant/img/blog_posts-index.png)

You can now search, paginate, create, and edit blog posts.

Depending on the model you're using, you might notice a few things:

* Boolean values can be toggled on and off in the index view.
* Any belongs-to associations are handled in the form by either a drop-down, or an Ajax autocompleter, depending on how many choices there are for the association.
* There is no `destroy` action out of the box. This is intended as a safe default, but you can add it if you like.
* If you have more than 10 pages of a given model, the pagination at the bottom includes a jump form to let you automatically jump to a page you enter.

For more, check out the [API reference](./api/).

