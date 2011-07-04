---
layout:   default
title:    "API: Search"
subnav:   api
subtitle: Search
---

![index](../img/blog_posts-search.png)

Search restricts the records viewed in [Index] by various criteria. By default, search presents a single text field, and text entered in this field will be compared to all string and text fields in the table. By setting #columns you can have the search form specify which fields are being searched on.

Since search is closely related to [Index], its configuration is reached through the index builder:

    class Admin::BlogPostsController < ApplicationController
      admin_assistant_for BlogPost do |a|
        a.index do |index|
          index.search do |search|
            search.columns :title, :user
          end
        end
      end
    end

You can chain calls to get to the search builder more quickly:

    class Admin::BlogPostsController < ApplicationController
      admin_assistant_for BlogPost do |a|
        a.index.search do |search|
          search.columns :title, :user
        end
      end
    end

### Search config options

#### columns
<a name="builder_columns"> </a>

    search.columns :title, :user

Call this method to set the search to supply one input for each column. When you set multiple search columns, users get the option of searching on all entered columns or any of them.

You can also call this with Index#search:

    index.search :title, :user
    
#### default\_search\_matches\_on

If you don't specify any columns, the search form is simply one field, and whatever text is entered in that field will be compared to every text and string field on the database table. If there are other fields you'd like the default search to compare with, you can add them using `default_search_matches_on`. For example, to give users the ability to search by ID:

      index.search.default_search_matches_on :id

You can also pass in SQL fragments:

      index.search.default_search_matches_on \
            "concat_ws(' ', users.first_name, users.last_name)"

#### include\_params\_in\_form
            
      index.search.include_params_in_form = true
      
This will put any custom page params in the search form to be posted with the search parameters. You might use this if you've got another way of filtering, say, blog posts by user, and you want the search form on that page to only search within blog posts by that user.

      
### Column config options

These are configurations that can be applied to specific columns in the search.

#### comparators

    search[:price].comparators = false
    
By default, integer and datetime fields are presented with a list of options for comparing to the entered value: "greater than", "greater than or equal to", "equal to", "less than or equal to", and "less than". This way the user can do a search like "show me all products that cost more than $100."

To turn this off, set `comparators` to false.

#### compare\_to\_range

    search[:price].compare_to_range = true
    
If you want to offer a ranged search, set `compare_to_range` to true. This will render two fields for greater-than and less-than in the search.
    
#### conditions

    search[:has_short_title].field_type = :boolean
    search[:has_short_title].conditions do |has_short_title|
      if has_short_title
        "length(title) < 10"
      elsif has_short_title == false
        "length(title) >= 10"
      end
    end
    
To be used with a virtual column in search. The block should return a SQL fragment to add to the final query, or nil to not change anything.

#### match\_text\_fields\_for\_association

    search[:user].match_text_fields_for_association

Only applies to belongs-to associations. By default, belongs-to associations will be searchable using a dropdown of the associated records that currently exist. Calling `match_text_fields_for_association` will mean the input for that association will be a text input instead, and that text will be matched against all text or string fields on the associated record.

For example, let's say you have a BlogPost that belongs to a User. With this configuration on Admin::BlogPostsController:

    search.columns :user
    search[:user].match_text_fields_for_association

... the search form will be one field, a text input labeled "User". If the user enters "an" in that field, it will match against all blog posts by the users with the username field of "Andy", "Andrew", and "Frank".


[Index]: ./idx.html
