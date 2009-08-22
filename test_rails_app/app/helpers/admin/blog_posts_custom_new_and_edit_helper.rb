module Admin::BlogPostsCustomNewAndEditHelper
  def link_to_new_in_index?
    param_triggering_link_suppression_present?
  end

  def link_to_edit_in_index?(record)
    param_triggering_link_suppression_present?
  end

  def link_to_delete_in_index?(record)
    param_triggering_link_suppression_present?
  end

  def link_to_show_in_index?(record)
    param_triggering_link_suppression_present?
  end
  
  def param_triggering_link_suppression_present?
    if params[:flag_to_trigger_helper_methods]
      false
    else
      true
    end
  end
end
