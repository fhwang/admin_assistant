---
layout:   default
title:    "API: Destroy"
subnav:   api
subtitle: Destroy
---

Note that the `destroy` action is turned off by default. To turn it on, use the core [actions](./core.html#builder_actions) method.

By default, `destroy` simply retrieves the model instance, and calls `ActiveRecord::Base#destroy`. If you'd like to define your own custom deletion semantics, you can set a block that will be called instead of the model's built-in `destroy` method:

    admin_assistant_for Product do |a|
      a.actions << :destroy
      a.destroy do |product|
        product.update_attribute :deleted, true
        product.notify_admins_of_deletion
      end
    end
    
You may also find plugins such as [as\_paranoid] or [acts\_as\_paranoid] useful here. If you're using a plugin such as that, which changes the behavior of `ActiveRecord::Base#destroy`, it means that you will probably not need to customize admin\_assistant in this way.




[acts_as_paranoid]: http://ar-paranoid.rubyforge.org/
[as_paranoid]: http://github.com/semanticart/is_paranoid/tree/master

