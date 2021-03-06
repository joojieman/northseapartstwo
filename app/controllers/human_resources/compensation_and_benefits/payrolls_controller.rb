class HumanResources::CompensationAndBenefits::PayrollsController < HumanResources::CompensationAndBenefitsController

  include HumanResourcesHelper

  def index
  end

  def employee

    # Initial Variables
    current_employee_id = params[:id]
    @employees = Employee.all
    current_employee_id.present? ?
        (@selected_employee = Employee.find(current_employee_id)) :
        (@selected_employee = Employee.new())
    @start_date = params[:start_date]
    @end_date = params[:end_date]

    # Convert Duty Status to Valid Periods
    @my_duty_statuses = DutyStatus.where('employee_id = ?', "#{current_employee_id}")
                            .order('date_of_implementation ASC')

    @valid_periods = get_valid_periods(current_employee_id)

    # Extract Attendances
    @selected_attendances = ::Attendance
                                .where('(attendances.employee_id = ?) AND ( attendances.date_of_attendance BETWEEN ? AND ? )',
                                       "#{current_employee_id}",
                                       "#{@start_date}",
                                       "#{@end_date}"
                                )

    # Keep Attendances within the Valid Period
    @selected_attendances = @selected_attendances.select{ |attendance|
      conditional = ''
      @valid_periods.each do |valid_period|
        conditional = attendance[:date_of_attendance].between?(Date.parse( valid_period[:start_period] ),Date.parse( valid_period[:end_period] ) )
        if conditional == true
          break;
        end
      end
      conditional
    }

    # Count Valid Periods
    @total_hours_valid_period = 0
    @valid_periods.each do |valid_period|
      start_period = DateTime.strptime(valid_period[:start_period], '%Y-%m-%d')
      end_period = DateTime.strptime(valid_period[:end_period], '%Y-%m-%d')
      hours_valid_period = end_period - start_period
      @total_hours_valid_period = hours_valid_period + @total_hours_valid_period
    end
    @total_hours_valid_period = @total_hours_valid_period*24

    # Categorize Base Rates
    @base_rates_applied_to_attendance_scheme = BaseRate.where("(employee_id = ?) AND ((rate_type = 'BASE') OR (rate_type = 'ALLOWANCE')) ", "#{current_employee_id}")
    @base_rates_applied_to_valid_period = BaseRate.where("(employee_id = ?) AND (rate_type = 'OTHER') ", "#{current_employee_id}")
    @base_rates_applied_to_valid_period = @base_rates_applied_to_valid_period.select{ |base_rate|
      conditional = false
      base_start_period = Date.parse(base_rate[:start_of_effectivity].strftime("%Y-%m-%d"))
      base_end_period = Date.parse(base_rate[:end_of_effectivity].strftime("%Y-%m-%d"))
      @valid_periods.each do |valid_period|
        valid_start_period = Date.parse(valid_period[:start_period])
        valid_end_period = Date.parse(valid_period[:end_period])
        conditional = ( (valid_start_period..valid_end_period).cover?(base_start_period) && (valid_start_period..valid_end_period).cover?(base_end_period) )
        if conditional
          break;
        end
      end
      conditional
    }

    #Lump Adjustments
    @selected_lump_adjustments = LumpAdjustment.where("employee_id = ? AND (date_of_implementation BETWEEN ? AND ?)",
                                                      "#{current_employee_id}","#{@start_date}", "#{@end_date}")
    @selected_lump_adjustments = date_of_implementation_in_valid_period(@selected_lump_adjustments,@valid_periods)

    #Vales
    @selected_vales = Vale.where("employee_id = ? AND approval_status = 1", "#{current_employee_id}")
    @selected_vales = @selected_vales.select{ |my_vale|
      conditional = false
      balance = remaining_vale_balance(my_vale[:id], @start_date)
      (balance != "PAID") ? (conditional = true) : (conditional = false)
      conditional
    }
    render 'human_resources/compensation_and_benefits/payrolls/employee'
  end

  def date_of_implementation_in_valid_period(my_model, valid_periods)
    current_model = my_model.select{ |model|
      puts 'cdsfadfore'
      conditional = false
      current_date = Date.parse(model[:date_of_implementation].strftime("%Y-%m-%d"))
      valid_periods.each do |valid_period|
        valid_start_period = Date.parse(valid_period[:start_period])
        valid_end_period = Date.parse(valid_period[:end_period])
        conditional = current_date.between?(valid_start_period,valid_end_period)
      end
      conditional
    }
    current_model
  end

  def branch

    @branches = Branch.all()
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @id = params[:id]
    @branch_employees = get_all_employees_from_a_branch(params[:id])

    render 'human_resources/compensation_and_benefits/payrolls/branch'

  end

  def open_all_branch_employee_payroll
    branch_employees = get_all_employees_from_a_branch(params[:id])
  end

  def remittance_report
    @remittance_type = ''
    @branch = ''
  end

end
