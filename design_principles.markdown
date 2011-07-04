---
layout:   default
title:    Design principles
---

admin\_assistant is built with a few design principles in mind:

### Relentless full-stack testing

admin\_assistant is tested against a complete, self-contained Rails app. This app serves as the reference implementation of admin\_assistant, so new features can be added with minimal worry of breaking old features.

In addition, this test suite can be run against multiple versions of Rails, making multi-version support possible.


### Deeply customizable API

It's great to be able to do the quick boilerplate CRUD operations, but it doesn't take long before you need a lot of custom functionality. So, while admin\_assistant can be set up in a few lines, its real strength is all the hooks it offers you:

* Labeling of models and columns
* Links at a page level, record level, or field level
* Selection of columns to include in index views and in forms
* Field value display in index views
* Custom inputs, submit buttons, descriptions in forms
* Partials can be rendered before or after forms, or column inputs.
* Custom options for date selects, datetime selects, textarea tags, etc. can be set up on a per-column level and passed through to the underlying Rails method.
* Custom redirecting after successful saves

If you're copying and pasting out of the admin\_assistant source, that's a design flaw.


### Minimally invasive

If you like, you can use admin\_assistant in a very self-contained way, meaning that any admin functionality you add to your application doesn't have to affect any other parts of the code.

For example, standard ActiveRecord callbacks like `after_save` and `before_create` can be mimicked in the admin controller, in case you want to contain that code to one particular controller, instead of having to think about how it might affect other code that's using that model.

In addition, admin\_assistant doesn't override or `alias_method_chain` anything in Rails core, which greatly reduces the possibility that admin\_assistant would conflict with another plugin.


### Safe defaults

admin\_assistant is opinionated in its own way, much of which has to do with picking the most safe default behavior possible.

* The `destroy` action is turned off by default, since the deletion of production data should never be enabled without a careful consideration of what that means for the overall system.
* Date selects and datetime selects in forms are blank by default, not the current date or time. This helps avoid a situation on models with many fields where dates and datetimes can be set by accident, changing the site's behavior in unexpected ways. The current date or time is usually not a useful default, anyway.
