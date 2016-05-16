class GeneralAdministration::AssociatedFiles::ImageSetsController < GeneralAdministration::AssociatedFilesController

  def index
    initialize_generic_index(ImageSet, 'Related Image Sets of Different Entities')
  end

  def search_suggestions
    generic_index_search_suggestions(ImageSet)
  end

  def new
    set_new_edit(ImageSet)
  end

  def edit
    set_new_edit(ImageSet)
  end

  def show
    edit
  end

  def delete
    ImageSet.find(params[:id]).remove_picture
    generic_delete(ImageSet)
  end

  def process_image_form(myImage)
    begin
      myImage[:remark] = params[controller_path][:remark]
      if action_name == 'edit'
        myImage.remove_picture
      end
      myImage.picture = params[controller_path][:picture]
      myImage[:priority] = params[controller_path][:priority]
      myImage[:imagesetable_type] = params[controller_path][:imagesetable_type]
      myImage[:imagesetable_id] = params[controller_path][:imagesetable_id]
      myImage.save!
      set_process_notification
    rescue => ex
      index_error(ex)
    end
    redirect_to_index
  end

  def create
    process_image_form(ImageSet.new())
  end

  def update
    process_image_form(ImageSet.find(params[controller_path][:id]))
  end

end