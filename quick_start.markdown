---
layout: default
title:  Quick start
---

<div class="note">
This document assumes you are highly familiar with Ruby and Rails; if you are a beginning Rails user you might want to start with our <a href="/admin_assistant/tutorial.html">tutorial</a>.
</div>

### Add the gem to your Gemfile

    gem 'admin_assistant'

### Include admin\_assistant's CSS and Javascript in your layout
    
admin\_assistant comes packaged with standard CSS and Javascript that you should include in whatever layout your admin controllers will be using. You'll also need to make sure to include jquery, if you're not including it already.

    <html>
      <head>
        <%= javascript_include_tag("jquery-1.6.2.min") %>
        <%= admin_assistant_includes %>
      </head>
      ...
    </html>
    
If you're using Sprockets, which is the default in Rails 3.1, you should include the CSS and Javascript assets in the manifest files that you use for your admin layout.

Javascript:

    //= require admin_assistant
    //= require jquery.tokeninput.js

CSS:

    //= require admin_assistant
    //= require token-input


### Setup an admin controller
    
Use the admin layout, and call `admin_assistant_for` with the model class.

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost
    end

That's it for the basic version. You should now be able to go to /admin/blog\_posts in your app and search, paginate, create, and edit blog posts.

![index](/admin_assistant/img/blog_posts-index.png)

Depending on the model you're using, you might notice a few things:

* Boolean values can be toggled on and off in the index view.
* Any belongs-to associations are handled in the form by either a drop-down, or an Ajax autocompleter, depending on how many choices there are for the association.
* There is no `destroy` action out of the box. This is intended as a safe default, but you can add it if you like.
* If you have more than 10 pages of a given model, the pagination at the bottom includes a jump form to let you automatically jump to a page you enter.

For more, check out the [API reference](/admin_assistant/api/).

