---
layout:   default
---

admin\_assistant is a Rails plugin that automates a lot of features typically needed in admin controllers. It is written and maintained by [Francis Hwang][fhwang].

admin\_assistant is in beta, meaning that it is stable, and being used in production sites, but there may be small API changes in the future.

It currently supports Rails 2.1.0, 2.1.2, 2.2.2, 2.3.2, and 2.3.3. There are no plans to support Rails 2.0 or earlier.


## Features

* Built-in model creation, updating, and deletion.
* Live querying of models, which allows incremental development of controllers without the maintenance problems of generated code.
* Paginated indexes with built field-ordering.
* Highly customizable search that allows customization of individual fields, numerical comparators, and boolean operators.
* Built-in Ajax autocompleters for handling belongs-to associations.
* Built-in widgets for handling polymorphic belongs-to associations.
* Built-in support for images with either [Paperclip](http://thoughtbot.com/projects/paperclip) or [FileColumn](http://www.kanthak.net/opensource/file_column/).
* Heavily hookable interface allows customization of columns, search parameters, form inputs, parameter handling, and model creation.


## Still not convinced?

Check out our [screenshots](/screenshots.html), [who's using admin\_assistant](/community.html#whos_using), or our [design principles](/design_principles.html).


## Installation

Installing admin\_assistant is the same as installing any other plugin:

    ./script/plugin install git://github.com/fhwang/admin_assistant.git

It depends on the will\_paginate plugin, so you'll have to install that as well if you don't already have it:

    ./script/plugin install git://github.com/mislav/will_paginate.git


[afarrill]: http://github.com/alexfarrill
[fhwang]: http://fhwang.net/
[mcelona]: http://github.com/mcelona
