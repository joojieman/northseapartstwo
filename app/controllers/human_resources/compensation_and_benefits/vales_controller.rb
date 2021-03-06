class HumanResources::CompensationAndBenefits::ValesController < HumanResources::CompensationAndBenefitsController

  def index
    query = generic_index_aggregated_queries('vales','vales.created_at')
    begin
      @vales = ::Vale
                   .includes(employee: [:system_account])
                   .joins(employee: [:system_accounts])
                              .where("actors.name LIKE ? OR " +
                                         "vales.id LIKE ? OR " +
                                         "vales.amount LIKE ? OR " +
                                         "vales.amount_of_deduction LIKE ? OR " +
                                         "vales.period_of_time LIKE ? OR " +
                                         "vales.remark LIKE ? OR " +
                                         "vales.date_of_implementation LIKE ? OR " +
                                         "vales.created_at LIKE ? OR " +
                                         "vales.updated_at LIKE ?",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%",
                                     "%#{query[:search_field]}%")
                              .order(query[:order_parameter] + ' ' + query[:order_orientation])
      @vales = Kaminari.paginate_array(@vales).page(params[:page]).per(query[:current_limit])
    rescue => ex
      flash[:general_flash_notification] = "Error has Occured" + ex.to_s
    end
    render 'human_resources/compensation_and_benefits/vales/index'
  end

  def search_suggestions
    adjustments = Vale.includes(employee: :system_account).where("actors.name LIKE (?)", "%#{ params[:query] }%").pluck("actors.name")
    direct = "{\"query\": \"Unit\",\"suggestions\":" + adjustments.uniq.to_s + "}"
    respond_to do |format|
      format.all { render :text => direct}
    end
  end

  def initialize_form
    initialize_form_variables('VALES',
                              'human_resources/compensation_and_benefits/vales/vales_form',
                              'vale')
    initialize_employee_selection
  end


  def delete
    generic_delete_model(Vale, controller_name)
  end

  def new
    initialize_form
    @selected_vale = Vale.new
    generic_bicolumn_form_with_employee_selection(@selected_vale)
  end

  def edit
    initialize_form
    @selected_vale = Vale.find(params[:id])
    generic_bicolumn_form_with_employee_selection(@selected_vale)
  end

  def process_lump_adjustment_form(vale)
    begin
      vale.id = params[:vale][:id]
      vale.approval_status = params[:vale][:approval_status]
      vale.amount = params[:vale][:amount]
      vale.amount_of_deduction = params[:vale][:amount_of_deduction]
      vale.period_of_time = params[:vale][:period_of_time]
      vale.remark = params[:vale][:remark]
      vale.employee_id = params[:vale][:employee_id]
      vale.date_of_implementation = params[:vale][:date_of_implementation]
      vale.save!
      flash[:general_flash_notification_type] = 'affirmative'
    rescue => ex
      flash[:general_flash_notification] = 'Error Occurred. Please contact Administrator.'
    end
    redirect_to :action => 'index'
  end

  def create
    vale = Vale.new()
    flash[:general_flash_notification] = 'Vale Added!'
    process_lump_adjustment_form(vale)
  end

  def update
    vale = Vale.find(params[:vale][:id])
    flash[:general_flash_notification] = 'Vale Updated!'
    process_lump_adjustment_form(vale)
  end

  def show
    @selected_vale = Vale.find(params[:id])
    @selected_vale_adjustments = ValeAdjustment.where("vale_id = ?", @selected_vale[:id] )
    @current_duration = Time.now - @selected_vale[:date_of_implementation]
    render 'human_resources/compensation_and_benefits/vales/show'
  end

end
