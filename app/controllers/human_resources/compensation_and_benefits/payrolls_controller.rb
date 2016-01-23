class HumanResources::CompensationAndBenefits::PayrollsController < HumanResources::CompensationAndBenefitsController

  def index
    query = generic_table_aggregated_queries('payrolls','payrolls.created_at')
    begin
      @payrolls = Payroll.includes(employee: [:actor])
                      .joins(employee: [:actor])
                      .where("actors.name LIKE ? OR " +
                                 "payrolls.id LIKE ? OR " +
                                 "payrolls.article LIKE ? OR " +
                                 "payrolls.applicability LIKE ? OR " +
                                 "payrolls.date_of_effectivity LIKE ? OR " +
                                 "payrolls.remark LIKE ? OR " +
                                 "payrolls.created_at LIKE ? OR " +
                                 "payrolls.updated_at LIKE ?",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%",
                             "%#{query[:search_field]}%")
                      .order(query[:order_parameter] + ' ' + query[:order_orientation])
      @payrolls = Kaminari.paginate_array(@payrolls).page(params[:page]).per(query[:current_limit])
    rescue
      flash[:general_flash_notification] = "Error has Occured"
    end
    render 'human_resources/compensation_and_benefits/payrolls/index'
  end

  def search_suggestions
    generic_employee_name_search_suggestions(Payroll)
  end

  def new
    initialize_employee_selection
    @selected_payroll = Payroll.new
    render 'human_resources/compensation_and_benefits/payrolls/payroll_form'
  end

  def edit
    initialize_employee_selection
    @selected_payroll = Payroll.find(params[:id])
    render 'human_resources/compensation_and_benefits/payrolls/payroll_form'
  end

  def process_payroll_form(payroll)
    begin
      employee = Employee.find(params[:payroll][:employee_id])
      payroll.employee = employee
      payroll.article = params[:payroll][:article]
      payroll.applicability = params[:payroll][:applicability]
      payroll.date_of_effectivity = params[:payroll][:date_of_effectivity]
      payroll.remark = params[:payroll][:remark]
      payroll.save!
      flash[:general_flash_notification_type] = 'affirmative'
    rescue => ex
      puts ex
      flash[:general_flash_notification] = 'Error Occurred. Please contact Administrator.'
    end
    redirect_to :action => 'index'
  end

  def delete
    generic_delete_model(Payroll, controller_name)
  end

  def update
    payroll = Payroll.find(params[:payroll][:id])
    flash[:general_flash_notification] = 'Payroll Updated'
    process_payroll_form(payroll)
  end

  def create
    payroll = Payroll.new()
    flash[:general_flash_notification] = 'Payroll Created'
    process_payroll_form(payroll)
  end

  def employee
    @employees = Employee.all
    params[:id].present? ?
      (@selected_employee = Employee.find(params[:id])) :
      (@selected_employee = Employee.new())
    @start_date = params[:start_date]
    @end_date = params[:end_date]

    @my_duty_statuses = DutyStatus.where('employee_id = ?', "#{params[:id]}")
                                  .order('date_of_effectivity ASC')

    @valid_periods = Array.new
    first_true_taken = false
    start_period = ''
    @my_duty_statuses.each_with_index do |duty_status, index|
      next_element = duty_status[index+1]
      if (duty_status[:active] == true && next_element.active == false)
      end
    end


    @selected_attendances = ::Attendance
                               .where('(attendances.employee_id = ?) AND ( attendances.date_of_attendance BETWEEN ? AND ? )',
                                      "#{params[:id]}",
                                      "#{@start_date}",
                                      "#{@end_date}"
                               )

    @selected_base_rates = BaseRate.where('employee_id = ?', "#{params[:id]}")

    render 'human_resources/compensation_and_benefits/payrolls/show_employee'
  end

  def branch

  end

end