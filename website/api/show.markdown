---
layout: api
title:  Show
---

Show configuration affects what is displayed in a show page, e.g. `/admin/blog_posts/show/5`.

### Show config options

#### columns

    admin_assistant_for BlogPost do |aa|
      aa.show.columns :user, :title, :body
    end

Shows only these columns in the show page..

