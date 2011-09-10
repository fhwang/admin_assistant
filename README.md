# admin_assistant

admin_assistant is a Rails plugin for automating features typically needed in admin interfaces.

## Documentation
http://fhwang.github.com/admin_assistant/

## Overview

Rails admins can be put into 2 categories- generators, and frameworks.
Generators give you ultimate control to change anything that was generated.
However, a generator works for only what you have at the time you run the generator, and take a lot of work to adapt to changes and additions.
Frameworks adapt well to changes but limit your flexibility. They have their own special API you have to learn, and the API will always be limited.

* Generators - padrino admin, the many rails generators, ?
* Framewokrs - rails_admin, ActiveAdmin, ?

admin_assistant is in the framework category. All admins work with fairly well with your existing models. The flexibility issue comes in changing how the controller and views behaved. The advantage of admin_assistant in comparison to rails_admin and ActiveAdmin is that you still create the controllers. Your controller inherits default behavior from admin_assistant. The default works well. But when you need customization that admin_assistant does not provide you can use normal Rails mechanisms to have complete control over how an individual controller action behaves. You can also achieve something similar to to this with one of the CRUD gems like inheritable_resource and some other techniques for automating the views. But an admin like admin_assistant comes with all that setup, plus some extra goodies like searching built in.

## Community

Google Group: http://groups.google.com/group/admin_assistant

## Features

Current features include:

* Your basic CReate / Update / Delete
* Index with pagination and field ordering
* Search, either by all text fields or by specific fields
* Live querying of models to generate forms and indexes, meaning that adding
  new columns to your admin controllers is easy
* Simple handling of belongs_to association via drop-down selects
* Built-in support for Paperclip and FileColumn

Copyright (c) 2009 Francis Hwang, released under the MIT license

## Development

### Testing

Testing is done by running integration tests against example rails applications using admin_assistant. This ensures that tests are always working against a real application and a brittle mocked up situation.

    cd rails_3_1
    rake db:migrate
    rake test
