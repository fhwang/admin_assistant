---
layout: api
title:  Index
---

![index](../img/blog_posts-index.png)

The index is the action that lets you view all records, with pagination and sorting. To customize it by getting the index builder inside of your admin\_assistant config:

    class Admin::BlogPostsController < ApplicationController
      admin_assistant_for BlogPost do |a|
        a.index do |index|
          index.columns :user, :title
          index.sort_by 'published_at desc'
        end
      end
    end

### Index config options

#### actions

    index.actions['All'] = {:all => '1'}

Adds more links to the upper-right hand-corner. By default there are two links there: "Search", and "New \[model name\]". If you have any other specific links to add, you can add them with index.actions, and they will be added to the right of those default two links.

#### conditions

Specifies additional SQL that can restrict the records shown in the index view. This can be a simple string:

    index.conditions "deleted_at is null"

It can also be a block that will be passed the params hash:

    index.conditions do |params|
      "deleted_at is null" unless params[:all]
    end

This can also be accomplished with a protected controller method `conditions_for_index`; see below.

#### per\_page

    index.per_page 100

By default, 25 rows per page will be shown. Set per\_page to set it to another number.

#### columns

    index.columns :user, :title

If called, restricts which columns are shown. By default admin\_assistant will try to show all columns on the DB table, which will probably be too much if your table has a lot of columns.

Can also be used to add model methods that aren't database fields.

#### header

    index.header do |params|
      if params[:all]
        "Blog posts (all)"
      else
        "Blog posts (unpublished)"
      end
    end

For customization the text at the top of the page; takes a block with params as its argument

#### include

    index.include :users
    
Accepts one or more association names to be eagerly loaded by ActiveRecord.

<a name="builder_right_column_links"></a>
#### right\_column\_links

By default, there are two links on the right-hand side of the row for each model: "Edit" and "Show". You can add new ones by appending to `right_column_links`:

    index.right_column_links << lambda { |blog_post|
      [
        "New comment for this blog post",
        {:controller => '/admin/comments', :action => 'new',
         :comment => {:blog_post_id => blog_post.id }}
      ]
    }

The lambda should receive the model and return a two-element array: The first element should be the text of the link and the second should be the URL parameters for that link.

See also the helper method [extra\_right\_column\_links\_for\_index](#helper_extra_right_column_links_for_index).

#### search

    index.search :id, :title

Shortcut to Search [`columns`](/api/search.html#builder_columns) .

#### sort\_by

Sets the default sorting of records, which will be used unless the user has specified sorting by clicking any of the sort headers. This can be a SQL string:

    index.sort_by 'published_at desc, id asc'

It can also just be a belongs-to association:

    index.sort_by :user

In the case of a belongs-to association, by default it will search for fields called `name`, `title`, `login`, or `username` on the associated model and use that.

#### total\_entries

    index.total_entries = do
      BlogPost.cached_count
    end

This block will be called during pagination to provide the total number of records. This can come in handy if you have a huge number of records and are finding the count(\*) SQL statement too expensive.

### Column config options

There are also configurations that can be applied to specific columns in the index view.

#### image\_size

    index[:image].image_size = '300x500'

By default, [Paperclip] and [FileColumn] image files are rendered at full-size in the index. To restrict their size, pass a size string to `image_size`.


#### link\_to\_args

    
    class Admin::BlogPostsController < ApplicationController
      layout 'admin'

      admin_assistant_for BlogPost do |aa|
        aa.index[:user].link_to_args do |blog_post|
          {:controller => 'admin/users', :action => 'edit',
           :id => blog_post.user_id }
        end
      end
    end
    

If you'd like this column to link somewhere from the index view, set this with a block that returns a hash for `url_for` when called.

Note that this block takes the base record as its argument, not the value of the specific column or association. In the example above, the base model is BlogPost, so the block is receiving a blog post, not the associated user.

### Controller methods

#### conditions\_for\_index

    def conditions_for_index
      "deleted_at is null" unless params[:all]
    end

Specifies additional SQL that can restrict the records shown in the index view.

Can also be set via `index.conditions`; see `conditions` above.

### Helper methods

#### \[column\]\_html\_for\_index

    def title_html_for_index(blog_post)
      "TITLE #{blog_post.title.capitalize}"
    end

If this method exists on the helper, it will be used to render the HTML shown in each row for the column in question. It takes the model as its only argument.

<a name="helper_extra_right_column_links_for_index"></a>
#### extra\_right\_column\_links\_for\_index

By default, there are two links on the right-hand side of the row for each model: "Edit" and "Show". You can add new ones by returning them from `extra_right_column_links_for_index`:

    def extra_right_column_links_for_index(blog_post)
      link_to(
        'New comment',
        {
          :controller => 'admin/comments', :action => 'new',
          :comment => {:blog_post_id => blog_post.id}
        }
      )
    end

Also see the builder method [right\_column\_links](#builder_right_column_links).
    
### Partials

#### \_after\_index.html.erb

If this partial is present, it will be rendered after the entire index HTML.

#### \_before\_index.html.erb

If this partial is present, it will be rendered before the entire index HTML.



[FileColumn]: http://www.kanthak.net/opensource/file_column/
[Paperclip]: http://thoughtbot.com/projects/paperclip

