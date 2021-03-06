module GenericRenderHelper

  def generic_title(title, subtitle)
    if title == nil
      title = controller_name.gsub('_',' ')
    end
    render(:partial => 'common_partials/generic_title', :locals => {:title => title, :subtitle => subtitle})
  end

  def renderItemListerButtons(remark,add,minus)
    renderCorePartial("itemlisterbuttons",{ :remark => remark, :add => add, :minus => minus})
  end

  def renderCorePartial(partialname,partialinks={})
    render(:partial => "common_partials/"+partialname, :locals => partialinks)
  end

  def renderSuccessPartial(headerMessage, bodyMessage, nextLinks)
    render(:partial => "common_partials/acknowledgement_success", :locals => { :headerMessage => headerMessage, :bodyMessage => bodyMessage, :nextLinks => nextLinks})
  end

  def renderFormPartial(partialname,partialinks={})
    render(:partial => "form_partials/"+partialname, :locals => partialinks)
  end
end