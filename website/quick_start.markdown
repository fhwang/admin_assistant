---
layout: default
title:  Quick start
---

*This document assumes you are highly familiar with Ruby and Rails; if you are a beginning Rails user you might want to start with our [tutorial](./tutorial.html).*

1) First, install the plugin from Github.

    ./script/plugin install git://github.com/fhwang/admin_assistant.git

2) If you don't have the popular will\_paginate plugin, you'll need that too.

    ./script/plugin install git://github.com/mislav/will_paginate.git

3) admin\_assistant comes packaged with standard CSS and Javascript that you should include in whatever layout your admin controllers will be using. You'll also need to make sure to include prototype.js, effects.js, and controls.js, if you're not including them already.

    <html>
      <head>
        <%= javascript_include_tag("prototype", "effects", "controls") %>
        <%= admin_assistant_includes %>
      </head>
      ...
    </html>

4) Setup an admin controller by attaching it to a model and using the admin layout:

    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost
    end

That's it for the basic version. You should now be able to go to /admin/blog\_posts in your app and search, paginate, create, and edit blog posts.

![index](./img/blog_posts-index.png)

Depending on the model you're using, you might notice a few things:

* Boolean values can be toggled on and off in the index view.
* Any belongs-to associations are handled in the form by either a drop-down, or an Ajax autocompleter, depending on how many choices there are for the association.
* There is no `destroy` action out of the box. This is intended as a safe default, but you can add it if you like.
* If you have more than 10 pages of a given model, the pagination at the bottom includes a jump form to let you automatically jump to a page you enter.

For more, check out the [API reference](./api/).

