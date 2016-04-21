module GenericFormHelper

  def generic_form_edit_id_indicator(selected_model_id)
    render(:partial => 'common_partials/generic_form/generic_form_edit_id_indicator', :locals => {:selected_model_id => selected_model_id})
  end

  def generic_form_footer(selected_model_id)
    render(:partial => 'common_partials/generic_form/generic_form_footer', :locals => {:selected_model_id => selected_model_id})
  end

  def generic_remarks_remark_field(model_name, default_remark)
    render(:partial => 'common_partials/generic_remark_remark_field', :locals => {:model_name => model_name, :default_remark => default_remark})
  end

  def generic_form_method_switch(selected_model)
    render(:partial => 'common_partials/generic_form/generic_form_method_switch', :locals => {:selected_model => selected_model})
  end

  def generic_employee_select_field(model_name, model_employee_id)
    render(:partial => 'human_resources/generic_employee_select_field', :locals => {:model_name => model_name,:model_employee_id => model_employee_id})
  end

  def generic_form_remark_field(field_variable, selected_model)
    render(:partial => 'common_partials/generic_form/remark_field', :locals => {:field_variable => field_variable,:selected_model => selected_model})
  end

end