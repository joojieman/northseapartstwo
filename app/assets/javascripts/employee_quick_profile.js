function update_quick_profile(){

    $('.employee_quick_profile').hide();
    var employee_ID = $('.employee_select_field').val();
    $.post( "/human_resources/employee_overview_profile", { employee_ID: employee_ID})
        .done(function( employee_overview_profile ) {
            var obj = jQuery.parseJSON( employee_overview_profile );
            $('#employee_quick_SystemActor_link').html( obj['SystemActors']['name'] );
            $('#employee_quick_SystemActor_link').attr('href', '/human_resources/employee_accounts_management/employee_profile?SystemActor_id=' + obj['SystemActors']['id'] );
            $('#employee_quick_employee_id').html( obj['id'] );
            $('#employee_quick_remark').html( obj['SystemActors']['remark'] );
            $('#employee_quick_picture').attr( 'src', obj['SystemActors']['logo']['url'] );
            $('.employee_quick_profile').fadeIn(500);
        });

    $.post( "/human_resources/employee_overview_duty_status", { employee_ID: employee_ID})
        .done(function( duty_status ) {
            $('.employee_quick_current_duty_status').html( duty_status );
        });
}