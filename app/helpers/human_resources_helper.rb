module HumanResourcesHelper

  def whatHoliday( current_date )
    holidays = Holiday.all
    what_holiday = false
    holidays.each do |holiday|
      if holiday.date_of_implementation == current_date
        what_holiday = holiday.name
      end
    end
    return what_holiday
  end

  def whatRestDay(employee_id, current_day)
    rest_day = RestDay
                   .where("(employee_id = ?) AND (date_of_implementation <= ?)", "#{employee_id}", "#{current_day}")
                   .order('rest_days.date_of_implementation DESC').first
    what_rest_day = false
    if rest_day.day == current_day.strftime("%A")
      what_rest_day = rest_day.id
    end
    return what_rest_day
  end

  def display_if_rest_day(employee_id, current_day, latest_end_time_for_constant)
    rest_day = RestDay
                   .where("(employee_id = ?) AND (date_of_implementation <= ?)", "#{employee_id}", "#{latest_end_time_for_constant}")
                   .order('rest_days.date_of_implementation ASC').first
    if rest_day.present?
      if rest_day[:day] == current_day
        "( REST DAY )"
      end
    end
  end

  def display_if_holiday(current_day)
    holiday = Holiday
                  .where("(date_of_implementation = ?)", current_day)
                  .order('holidays.date_of_implementation ASC').first
    if holiday.present?
      holiday[:name]
    end
  end

  def get_duration_actual_work_hours(employee_ID, specific_day)
    attendances = Attendance.includes(:employee).joins(:employee).where("(employees.id = ?) AND (attendances.date_of_attendance LIKE ?)", "#{employee_ID}", "#{specific_day.strftime("%Y-%m-%d")}%").order('attendances.created_at DESC')
    total_seconds = 0
    attendances.each do |attendance|
      time_in = attendance[:timein]
      time_out = attendance[:timdeout]
      my_seconds = (time_in - time_out).abs
      total_seconds = my_seconds + total_seconds
    end
    return (total_seconds/3600).round
  end

  def get_current_duty_status( employee_ID )
    currentEmployee = Employee
                          .includes(:duty_status)
                          .joins(:duty_status)
                          .where("(employees.id = ?)", "#{employee_ID}")
                          .order('duty_statuses.date_of_implementation DESC').first
    return currentEmployee.duty_status.first.active
  end

  def get_duration_regular_work_hours(employee_ID, specific_day)
    currentEmployee = Employee
                          .includes(:regular_work_period)
                          .joins(:regular_work_period)
                          .where("(employees.id = ?) AND (regular_work_periods.date_of_implementation <= ?)", "#{employee_ID}", "#{specific_day}")
                          .order("regular_work_periods.date_of_implementation DESC").first
    number_of_seconds = ((currentEmployee.regular_work_period.end_time - currentEmployee.regular_work_period.start_time))
    if number_of_seconds < 0
      number_of_seconds = ((currentEmployee.regular_work_period.end_time - currentEmployee.regular_work_period.start_time)).abs
    end
    return (number_of_seconds/3600).round
  end

  def get_all_employees_from_a_branch(branchId)

    puts '--------------------------------------'
    puts branchId

    emps = Employee.where("(branch_id = ?)", "#{branchId}")

    emps.each do |e|
      puts '--------------------------------------'
      puts e.actor.name
    end

    return emps
  end

  def get_valid_periods(employee_id)

    my_duty_statuses = DutyStatus.where('employee_id = ?', "#{employee_id}")
                            .order('date_of_implementation ASC')

    valid_periods = Array.new
    start_period = ''
    end_period = ''
    searching_for_next = true
    my_duty_statuses.each_with_index do |duty_status, index|
      if duty_status[:active] == searching_for_next
        if duty_status[:active] == true
          start_period = duty_status[:date_of_implementation].strftime("%Y-%m-%d")
          searching_for_next = false
        end
        if duty_status[:active] == false
          end_period = duty_status[:date_of_implementation].strftime("%Y-%m-%d")
          searching_for_next = true
        end
      end
      if start_period.present? && end_period.present?
        valid_periods.push({:start_period => start_period, :end_period => end_period})
        start_period = ''
        end_period = ''
      end
      if start_period.present? && ( index == @my_duty_statuses.size - 1 )
        valid_periods.push({:start_period => start_period, :end_period => DateTime.now.strftime("%Y-%m-%d") })
      end
    end

    valid_periods
  end

  def get_gross_salary_employee(start_date, end_date, employee)
    valid_periods = get_valid_periods(employee[:id])
    base_rates_applied_to_attendance_scheme = BaseRate.where("(employee_id = ?) AND ((rate_type = 'BASE') OR (rate_type = 'ALLOWANCE')) ", "#{employee[:id]}")
    # Extract Attendances
    selected_attendances = ::Attendance
                                .where('(attendances.employee_id = ?) AND ( attendances.date_of_attendance BETWEEN ? AND ? )',
                                       "#{employee[:id]}",
                                       "#{start_date}",
                                       "#{end_date}"
                                )

    # Keep Attendances within the Valid Period
    selected_attendances = selected_attendances.select{ |attendance|
      conditional = ''
      valid_periods.each do |valid_period|
        conditional = attendance[:date_of_attendance].between?(Date.parse( valid_period[:start_period] ),Date.parse( valid_period[:end_period] ) )
        if conditional == true
          break;
        end
      end
      conditional
    }

    total_regular_work_hours = 0
    total_overtime_hours = 0
    total_night_shift_differential_hours = 0
    total_ot_nsd_hours = 0

    total_reg_aggregated_payment = 0
    total_ot_aggregated_payment = 0
    total_nsd_aggregated_payment = 0
    total_ot_nsd_aggregated_payment = 0

    total_for_selection = 0

    start_date = Date.parse(start_date)
    end_date = Date.parse(end_date)
    (start_date..end_date).each do |date_aspect|
      attendance_time_in = 0
      attendance_time_out = 0
      regular_work_hours = 0
      overtime_hours = 0
      night_shift_differential_hours = 0
      ot_nsd_hours = 0
      reg = 0
      ot = 0
      nsd = 0
      ot_nsd = 0
      reg_aggregated_payment = 0
      ot_aggregated_payment = 0
      nsd_aggregated_payment = 0
      ot_nsd_aggregated_payment = 0
      total_aggregated_payment = 0

      attendance_exists_token = false
      current_attendance_date_time = date_aspect.strftime('%Y-%m-%d')
      rest_day_token = display_if_rest_day(@selected_employee.id,date_aspect.strftime('%A'),current_attendance_date_time )
      remark = ''
      link_token = ''
      attendance_id = ''

      @selected_attendances.each do |selected_attendance|
        if selected_attendance[:date_of_attendance] == date_aspect

          attendance_exists_token = true
          link_token = true

          attendance_time_in = selected_attendance[:timein].strftime("%T")
          attendance_time_out = selected_attendance[:timeout].strftime("%T")

          regular_work_hours = categorize_work_hours( attendance_time_in, attendance_time_out, current_attendance_date_time)[:regular_work_hours]
          overtime_hours = categorize_work_hours( attendance_time_in, attendance_time_out, current_attendance_date_time)[:overtime]
          night_shift_differential_hours = categorize_work_hours( attendance_time_in, attendance_time_out, current_attendance_date_time)[:night_shift_differential_hours]
          ot_nsd_hours = categorize_work_hours( attendance_time_in, attendance_time_out, current_attendance_date_time)[:ot_nsd]

          reg = base_rates(@selected_employee.id, current_attendance_date_time,rest_day_token)[:reg]
          ot = base_rates(@selected_employee.id, current_attendance_date_time,rest_day_token)[:ot]
          nsd = base_rates(@selected_employee.id, current_attendance_date_time,rest_day_token)[:nsd]
          ot_nsd = base_rates(@selected_employee.id, current_attendance_date_time,rest_day_token)[:ot_nsd]

          reg_aggregated_payment = (regular_work_hours*reg)
          ot_aggregated_payment = (overtime_hours*ot)
          nsd_aggregated_payment = (night_shift_differential_hours*nsd)
          ot_nsd_aggregated_payment = (ot_nsd_hours*ot_nsd)

          remark = selected_attendance[:remark]
          attendance_id = selected_attendance[:id]

        end
      end

      if attendance_exists_token == false
        if special_non_working_holiday(date_aspect)
          reg = base_rates(@selected_employee.id, current_attendance_date_time,rest_day_token)[:reg]
          reg_aggregated_payment = (8*reg)
        end
      end

      total_aggregated_payment = reg_aggregated_payment + ot_aggregated_payment + nsd_aggregated_payment + ot_nsd_aggregated_payment

      total_regular_work_hours += regular_work_hours
      total_overtime_hours += overtime_hours
      total_night_shift_differential_hours += night_shift_differential_hours
      total_ot_nsd_hours += ot_nsd_hours

      total_reg_aggregated_payment += reg_aggregated_payment
      total_ot_aggregated_payment += ot_aggregated_payment
      total_nsd_aggregated_payment += nsd_aggregated_payment
      total_ot_nsd_aggregated_payment += ot_nsd_aggregated_payment

      total_for_selection += total_aggregated_payment

    end
    total_for_selection
  end

  def vale_payment_in_period(start_date, end_date, vale)

    # get the variables
    start_date = DateTime.parse(start_date)
    end_date = DateTime.parse(end_date)
    current_vale_datetime = DateTime.parse(vale[:date_of_implementation].strftime('%Y-%m-%d %T'))
    iteration = translate_period_of_time_into_seconds(vale[:period_of_time])
    current_balance = vale[:amount]
    total_deduction = 0
    vale_adjustments = ValeAdjustment.where("vale_id = '" + vale[:id] + "'")

    # loop until the vale runs out
    while 0 < current_balance

      # deduction counter
      current_deduction = 0

      # adjustment token
      adjustment_in_period_token = false

      # reset amount of deduction
      amount_of_deduction = vale[:amount_of_deduction]

      # calculate datetime for next iteration
      next_vale_date = (current_vale_datetime + iteration.seconds)

      # check for any adjustments on the period - MANUAL
      vale_adjustments.each do |adjustment|
        adjustment_date_of_implementation = DateTime.parse( adjustment[:date_of_implementation].strftime('%Y-%m-%d') )
        if adjustment_date_of_implementation.between?(current_vale_datetime,next_vale_date)
          adjustment_in_period_token = true
          if adjustment[:signed_type]
            current_balance += adjustment[:amount]
          else
            current_balance -= adjustment[:amount]
            current_deduction += adjustment[:amount]
          end
        end
      end

      # iterate amount - AUTO
      if adjustment_in_period_token == false
        current_balance -= amount_of_deduction
        current_deduction += amount_of_deduction
      end

      # check if about to amount is going to run out on next iteration; if so, prepare for exact sum of amount_of_deduction
      if current_balance < 0
        current_deduction += current_balance
        current_balance = 0
      end

      # capture deductions
      if current_vale_datetime.between?(start_date, end_date)
        total_deduction += current_deduction
      end

      # iterate date
      current_vale_datetime += iteration.seconds
    end

    total_deduction
  end

  def special_non_working_holiday(current_date)
    main_boolean = false
    holidays = Holiday.includes(:holiday_type).joins(:holiday_type)
    holidays.each do |holiday|
      if current_date == holiday[:date_of_implementation]
        holiday_type = holiday.holiday_type.type_name
        if ( holiday_type == 'Regular' || holiday_type == 'Double' )
          main_boolean = true
        end
      end
    end
    main_boolean
  end

  def signed_amount(sign, amount)
    if sign
      amount = amount
    else
      amount = amount*(-1)
    end
    amount
  end

  def convert_base_rate_amount_to_hours(amount,period_of_time)
    if period_of_time == 'HOUR'
      amount_in_hour = amount
    elsif period_of_time == 'DAY'
      amount_in_hour = amount/24
    elsif period_of_time == 'MONTH'
      amount_in_hour = amount/730.484398
    elsif period_of_time == 'WEEK'
      amount_in_hour = amount/168
    elsif period_of_time == 'YEAR'
      amount_in_hour = amount/8765.81277
    else
    end
    amount_in_hour.round(2)
  end

  def remove_lunch_break(start_time, end_time)
    lunch_break_start_constant = get_constant('human_resources.start_lunch_break', time_of_consideration)
    start_lunch_break = Time.strptime((::Constant.find_by_constant_type('human_resources.start_lunch_break'))[:value], '%Y-%m-%d %H:%M:%S')
    end_lunch_break = Time.strptime((::Constant.find_by_constant_type('human_resources.end_lunch_break'))[:value], '%Y-%m-%d %H:%M:%S')
    is_crossed_lunch_break = (start_time..end_time).overlaps?(start_lunch_break..end_lunch_break)
    lunch_break_difference = 0
    if is_crossed_lunch_break
      if ( start_time.between?(start_lunch_break,end_lunch_break) ) && ( end_time.between?(start_lunch_break,end_lunch_break) )
      elsif start_time.between?(start_lunch_break,end_lunch_break)
        lunch_break_difference = end_lunch_break - start_time
      elsif end_time.between?(start_lunch_break,end_lunch_break)
        lunch_break_difference = end_time - start_lunch_break
      else
        lunch_break_difference = 3600
      end
    end
    work_hours_without_lunch_break = (((end_time - start_time) - lunch_break_difference)/3600)
  end

  def categorize_work_hours(start_time, end_time, latest_end_time_for_constant)
    #Initialize Variables
    start_time = Time.parse(start_time)
    end_time = Time.parse(end_time)
    uncutoff_start_time = start_time
    uncutoff_end_time = end_time
    lunch_break_difference = 0
    regular_work_hours = 0
    overtime = 0
    night_shift_differential_hours = 0
    ot_nsd = 0
    nsd_morning_difference = 0
    nsd_night_difference = 0
    night_shift_differential_start = Time.parse(get_constant('human_resources.night_shift_differential_start', latest_end_time_for_constant))
    night_shift_differential_end = Time.parse(get_constant('human_resources.night_shift_differential_end', latest_end_time_for_constant))

    #NSD Cutoff
    if start_time.between?( Time.parse('00:00:01'),night_shift_differential_end)
      nsd_morning_difference = night_shift_differential_end - start_time
      uncutoff_start_time = start_time
      start_time = night_shift_differential_end
    end
    if end_time.between?(night_shift_differential_start, Time.parse('23:59:59'))
      nsd_night_difference = end_time - night_shift_differential_start
      uncutoff_end_time = end_time
      end_time = night_shift_differential_start
    end

    start_lunch_break = Time.parse(get_constant('human_resources.start_lunch_break', latest_end_time_for_constant))
    end_lunch_break = Time.parse(get_constant('human_resources.end_lunch_break', latest_end_time_for_constant))

    #Lunchbreak Deduction
    if (start_time..end_time).overlaps?(start_lunch_break..end_lunch_break)
      if start_time.between?(start_lunch_break,end_lunch_break)
        lunch_break_difference = end_lunch_break - start_time
      elsif end_time.between?(start_lunch_break,end_lunch_break)
        lunch_break_difference = end_time - start_lunch_break
      else
        lunch_break_difference = 3600
      end
    end

    regular_work_hours = ((((end_time - start_time) - lunch_break_difference)/3600) )
    night_shift_differential_hours = ((nsd_morning_difference+nsd_night_difference)/3600)

    #NSD Overlap
    morning_overlap = end_time.between?(Time.parse('00:00:01'), night_shift_differential_end)
    night_overlap = start_time.between?(night_shift_differential_start, Time.parse('23:59:59'))
    if (morning_overlap == true )||( night_overlap == true)
      regular_work_hours = 0
    end

    #exclusively start/end inside NSD's
    total_overlap_nsd_morning = (uncutoff_start_time.between?(Time.parse('00:00:01'),night_shift_differential_end) == true) && (uncutoff_end_time.between?(Time.parse('00:00:01'),night_shift_differential_end) == true)
    total_overlap_nsd_night = (uncutoff_start_time.between?(night_shift_differential_start,Time.parse('23:59:59')) == true) && (uncutoff_end_time.between?(night_shift_differential_start,Time.parse('23:59:59')) == true)
    if (total_overlap_nsd_morning == true )||( total_overlap_nsd_night == true)
      night_shift_differential_hours = ((uncutoff_end_time - uncutoff_start_time)/3600)
      #night_shift_differential_hours = 'H'
    end

    #Limit Regular Work Hours
    if regular_work_hours > 8
      overtime = regular_work_hours - 8
      ot_nsd = night_shift_differential_hours
      night_shift_differential_hours = 0
      regular_work_hours = 8
    end

    work_hours_hash = {:regular_work_hours => regular_work_hours.round(2),
                       :overtime => overtime.round(2),
                       :night_shift_differential_hours => night_shift_differential_hours.round(2),
                       :ot_nsd => ot_nsd.round(2),
    }
    work_hours_hash
  end

  def base_rates(employee_id, current_date_of_attendance, restday_token)

    total_regular_sum = 0
    base_sum = 0
    ot_sum = 0
    nsd_sum = 0
    ot_nsd_sum = 0

    base_rates = BaseRate.where('(employee_id = ?) AND ( ? BETWEEN start_of_effectivity AND end_of_effectivity)', "#{employee_id}","#{current_date_of_attendance}");

    base_rates.each do |base_rate|
      if (base_rate[:rate_type] == 'BASE' || base_rate[:rate_type] == 'ALLOWANCE')
        current_amount = convert_base_rate_amount_to_hours(base_rate[:amount], base_rate[:period_of_time])
        if base_rate[:signed_type]
          total_regular_sum = total_regular_sum + current_amount
        else
          total_regular_sum = total_regular_sum + (current_amount*(-1))
        end
      end
    end

    base_rates.each do |base_rate|
      if base_rate[:rate_type] = 'BASE'
        current_amount = convert_base_rate_amount_to_hours(base_rate[:amount], base_rate[:period_of_time])
        if base_rate[:signed_type]
          base_sum = base_sum + current_amount
        else
          base_sum = base_sum + (current_amount*(-1))
        end
      end
    end

    current_date = Date.strptime(current_date_of_attendance, "%Y-%m-%d")
    holiday_token = false
    non_working_token = false
    double_holiday_token = false
    holiday_type = false
    holidays = Holiday.includes(:holiday_type).joins(:holiday_type)
    holidays.each do |holiday|
      if current_date == holiday[:date_of_implementation]
        holiday_type = holiday.holiday_type.type_name
        if holiday_type == 'Regular'
          holiday_token = true
        elsif holiday_type == 'Special Non-Working'
          non_working_token = true
        elsif holiday_type == 'Double'
          double_holiday_token = true
        end
      end
    end

    original_total_regular_sum = total_regular_sum

    if (holiday_token == true) && (restday_token == true)
      total_regular_sum = (total_regular_sum*2)+((base_sum*2)*0.3)
      ot_sum = base_sum*3.38
      nsd_sum = original_total_regular_sum*2.6*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif (non_working_token == true) && (restday_token == true)
      total_regular_sum = total_regular_sum*1.5
      ot_sum = base_sum*1.95
      nsd_sum = total_regular_sum*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif (double_holiday_token == true) && (restday_token == true)
      total_regular_sum = total_regular_sum*3
      ot_sum = base_sum*5.07
      nsd_sum = original_total_regular_sum*3.9*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif holiday_token
      total_regular_sum = total_regular_sum*2
      ot_sum = base_sum*2.6
      nsd_sum = total_regular_sum*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif non_working_token
      total_regular_sum = total_regular_sum*1.3
      ot_sum = base_sum*1.69
      nsd_sum = total_regular_sum*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif double_holiday_token
      total_regular_sum = total_regular_sum*3
      ot_sum = base_sum*3.9
      nsd_sum = original_total_regular_sum*3.3*1.1
      ot_nsd_sum = ot_sum*1.1
    elsif restday_token
      total_regular_sum = total_regular_sum*1.3
      ot_sum = base_sum*1.69
      nsd_sum = total_regular_sum*1.1
      ot_nsd_sum = ot_sum*1.1
    else
      total_regular_sum = total_regular_sum
      ot_sum = base_sum*1.25
      nsd_sum = total_regular_sum*1.1
      ot_nsd_sum = (ot_sum*1.1)
    end

    rate_array = {:reg => total_regular_sum, :ot => ot_sum,:nsd => nsd_sum,:ot_nsd => ot_nsd_sum, :base => base_sum}
  end

  def remaining_vale_balance(parent_vale_id, time_now = Time.now)

    my_vale = Vale.find(parent_vale_id)
    my_vale_adjustments = ValeAdjustment.where(vale_id: parent_vale_id)
    current_balance = my_vale[:amount]
    iteration = translate_period_of_time_into_seconds(my_vale[:period_of_time])
    current_time = my_vale[:date_of_implementation]
    next_time = current_time + iteration

    while(time_now > current_time)
      adjustment_in_period_token = false
      my_vale_adjustments.each do |my_vale_adjustment|
        if my_vale_adjustment[:date_of_implementation].between?(current_time, next_time)
          adjustment_in_period_token = true
          my_vale_adjustment[:signed_type] ?
              ( current_balance = current_balance + my_vale_adjustment[:amount] ) :
              ( current_balance = current_balance - my_vale_adjustment[:amount] )
        end
      end
      (adjustment_in_period_token == false) ? ( current_balance = current_balance - my_vale[:amount_of_deduction] ):()
      (current_balance < 0) ? (break;) : ()
      current_time = current_time + iteration
      next_time = current_time + iteration
    end

    (current_balance < 0) ? (current_balance = "PAID") : ()
    return current_balance

  end

  def whatHoliday( current_date )
    holidays = Holiday.all
    what_holiday = false
    holidays.each do |holiday|
      if holiday.date_of_implementation == current_date
        what_holiday = holiday.name
      end
    end
    return what_holiday
  end

  def whatRestDay(employee_id, current_day)
    rest_day = RestDay
                   .where("(employee_id = ?) AND (date_of_implementation <= ?)", "#{employee_id}", "#{current_day}")
                   .order('rest_days.date_of_implementation DESC').first
    what_rest_day = false
    if rest_day.day == current_day.strftime("%A")
      what_rest_day = rest_day.id
    end
    return what_rest_day
  end

  def display_if_rest_day(employee_id, current_day, latest_end_time_for_constant)
    rest_day = RestDay
                   .where("(employee_id = ?) AND (date_of_implementation <= ?)", "#{employee_id}", "#{latest_end_time_for_constant}")
                   .order('rest_days.date_of_implementation ASC').first
    if rest_day.present?
      if rest_day[:day] == current_day
        "Rest Day"
      end
    end
  end

  def display_if_holiday(current_day)
    holiday = Holiday
                  .where("(date_of_implementation = ?)", current_day)
                  .order('holidays.date_of_implementation ASC').first
    if holiday.present?
      holiday[:name]
    end
  end

  def get_current_duty_status( employee_ID )
    return_word = "INACTIVE"
    currentEmployee = Employee
                          .includes(:duty_status)
                          .joins(:duty_status)
                          .where("(employees.id = ?)", "#{employee_ID}")
                          .order('duty_statuses.date_of_implementation DESC').first
    if currentEmployee.duty_status.first.active == true
      return_word = "ACTIVE"
    else
      return_word = "INACTIVE"
    end
  end

  def get_duration_regular_work_hours(employee_ID, specific_day)
    currentEmployee = Employee
                          .includes(:regular_work_period)
                          .joins(:regular_work_period)
                          .where("(employees.id = ?) AND (regular_work_periods.date_of_implementation <= ?)", "#{employee_ID}", "#{specific_day}")
                          .order("regular_work_periods.date_of_implementation DESC").first
    number_of_seconds = ((currentEmployee.regular_work_period.end_time - currentEmployee.regular_work_period.start_time))
    if number_of_seconds < 0
      number_of_seconds = ((currentEmployee.regular_work_period.end_time - currentEmployee.regular_work_period.start_time)).abs
    end
    return (number_of_seconds/3600).round
  end

  def get_duration_actual_work_hours(employee_ID, specific_day)
    attendances = Attendance.includes(:employee).joins(:employee).where("(employees.id = ?) AND (attendances.date_of_attendance LIKE ?)", "#{employee_ID}", "#{specific_day.strftime("%Y-%m-%d")}%").order('attendances.created_at DESC')
    total_seconds = 0
    attendances.each do |attendance|
      time_in = attendance[:timein]
      time_out = attendance[:timeout]
      my_seconds = (time_in - time_out).abs
      total_seconds = my_seconds + total_seconds
    end
    return (total_seconds/3600).round
  end

  def generic_employee_profile_link(model_with_employee_association)
    render(:partial => 'human_resoources/profile_link', :locals => {:model_with_employee_association => model_with_employee_association})
  end

end
