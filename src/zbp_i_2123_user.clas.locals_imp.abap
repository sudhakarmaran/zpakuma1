CLASS lhc_User DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR User RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR User RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR User RESULT result.

    METHODS DownloadExcel FOR MODIFY
      IMPORTING keys FOR ACTION User~DownloadExcel RESULT result.

    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION User~uploadExcelData RESULT result.

    METHODS FillFileStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~FillFileStatus.

    METHODS FillSelectedStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~FillSelectedStatus.

ENDCLASS.

CLASS lhc_User IMPLEMENTATION.

  METHOD get_instance_features.
   READ ENTITIES OF zi_2123_user IN LOCAL MODE ENTITY User
    FIELDS ( EmpId DevId FileStatus TemplateStatus ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_users) FAILED failed.


    result = VALUE #( FOR user IN lt_users
                      LET uploadBtn = COND #( WHEN user-FileStatus = 'File Selected'
                                             THEN if_abap_behv=>fc-o-enabled
                                             ELSE if_abap_behv=>fc-o-disabled )
                         DownloadTemplate = COND #( WHEN user-TemplateStatus = 'Absent'
                                             THEN if_abap_behv=>fc-o-enabled
                                             ELSE if_abap_behv=>fc-o-disabled )
                      IN
                                            ( %tky = user-%tky
                                             %assoc-_UserDev = if_abap_behv=>fc-o-disabled
                                             %action-uploadExcelData = uploadBtn
                                             %action-DownloadExcel = DownloadTemplate
                                            ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD DownloadExcel.
  DATA: lt_template        TYPE STANDARD TABLE OF zbp_i_2123_user=>gty_exl_file.

    DATA(lo_write_access) = xco_cp_xlsx=>document->empty( )->write_access( ).
    DATA(lo_worksheet) = lo_write_access->get_workbook(
        )->worksheet->at_position( 1 ).

    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
                               )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
                               )->to_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'M' )
                               )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( 1 )
                               )->get_pattern( ).

    lt_template = VALUE #( (
    emp_id = 'User Id'
    dev_id = 'Development Id'
    dev_desc = 'Development Description'
    obj_type = 'Object Type'
    obj_name = 'Object Name'
    ) ).

    lo_worksheet->select( lo_selection_pattern
        )->row_stream(
        )->operation->write_from( REF #( lt_template )
        )->execute( ).

    DATA(lv_file_content) = lo_write_access->get_file_content( ).

*  "Modify Root Entity
    MODIFY ENTITIES OF zi_2123_user IN LOCAL MODE
    ENTITY User
    UPDATE FROM VALUE #( FOR ls_key IN keys
       (
       EmpId      = ls_key-EmpId
       DevId      = ls_key-DevId
       Attachment = lv_file_content
       Filename   = 'template.xlsx'
       Mimetype   = 'application/vnd.ms-excel'
       %control-Attachment  = if_abap_behv=>mk-on
       %control-Filename   = if_abap_behv=>mk-on
       %control-Mimetype  = if_abap_behv=>mk-on
       ) )
    MAPPED DATA(ls_mapped_update)
    REPORTED DATA(ls_reported_update)
    FAILED DATA(ls_failed_update).

*    "Read Updated Entry
    READ ENTITIES OF zi_2123_user IN LOCAL MODE
    ENTITY  User
    ALL FIELDS WITH
    CORRESPONDING #( Keys )
    RESULT DATA(lt_User).
*    "Update File Status
    LOOP AT lt_User INTO DATA(ls_user).
      MODIFY ENTITIES OF ZI_2123_user IN LOCAL MODE
      ENTITY User
      UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( (
          %tky                  = ls_user-%tky
          %data-FileStatus      = 'File not Selected'
          %data-TemplateStatus      = 'Present'
          %control-FileStatus   = if_abap_behv=>mk-on
          %control-TemplateStatus   = if_abap_behv=>mk-on
          ) )
          MAPPED DATA(ls_mapped_status)
    REPORTED DATA(ls_reported_status)
    FAILED DATA(ls_failed_status).
    ENDLOOP.


    "Send Status back to front end
    result = VALUE #( FOR ls_upd_user IN lt_User
                      ( %tky   = ls_upd_user-%tky
                        %param = ls_upd_user
                        ) ).

    IF ls_failed_update IS INITIAL.
   reported = VALUE #( BASE reported user = VALUE #( ( %tky = keys[ 1 ]-%tky
    %msg = new_message_with_text( severity =                                                   if_abap_behv_message=>severity-success
                     text = 'Template Available.' )

                                                                    ) )  ).
    ENDIF.
  ENDMETHOD.

  METHOD uploadExcelData.
   DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lv_content      TYPE string,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lt_excel        TYPE STANDARD TABLE OF zbp_i_2123_user=>gty_exl_file,
          lt_excel_temp   TYPE STANDARD TABLE OF zbp_i_2123_user=>gty_exl_file,
          lt_excel_filter TYPE SORTED TABLE OF zbp_i_2123_user=>gty_exl_file WITH UNIQUE KEY emp_id dev_id,
          lt_data         TYPE TABLE FOR CREATE zi_2123_user\_UserDev,
          lv_index        TYPE sy-index.


    FIELD-SYMBOLS: <lfs_col_header> TYPE string.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    READ ENTITIES OF zi_2123_user IN LOCAL MODE
    ENTITY User
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-attachment.
    CHECK lv_attachment IS NOT INITIAL.

    "Move Excel Data to Internal Table
    DATA(lo_xlsx)      = xco_cp_xlsx=>document->for_file_content( iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select( lo_selection_pattern )->row_stream( )->operation->write_to(
                                                                                   REF #( lt_excel_temp ) ).
    lo_execute->set_value_transformation(
        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    " Get number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel_temp ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        "Implement error handling
    ENDTRY.

    "Validate Header record
    DATA(ls_excel) = VALUE #( lt_excel_temp[ 1 ] OPTIONAL ).
    IF ls_excel IS NOT INITIAL.
      DO lv_no_of_cols TIMES.
        lv_index = sy-index.
        ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
        CHECK <lfs_col_header> IS ASSIGNED.
        DATA(lv_value) =  to_upper(  <lfs_col_header> ) .
        DATA(lv_has_error) = abap_false.
        CASE lv_index.
          WHEN 1.
            lv_has_error = COND #( WHEN lv_value <> 'USER ID' THEN abap_true ELSE lv_has_error ).
          WHEN 2.
            lv_has_error = COND #( WHEN lv_value <> 'DEVELOPMENT ID' THEN abap_true ELSE lv_has_error ).
          WHEN 3.
            lv_has_error = COND #( WHEN lv_value <> 'DEVELOPMENT DESCRIPTION' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'OBJECT TYPE' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'OBJECT NAME' THEN abap_true ELSE lv_has_error ).
          WHEN 9. "More than 7 columns (error)
            lv_has_error = abap_true.
        ENDCASE.
        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-user.
          APPEND VALUE #(
            %tky = lt_file_entity[ 1 ]-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'One or more heading is incorrect !!' )
          ) TO reported-user.
          UNASSIGN <lfs_col_header>.
          EXIT.
        ENDIF.
        UNASSIGN <lfs_col_header>.
      ENDDO.
    ENDIF.
    CHECK lv_has_error = abap_false.

    DELETE lt_excel_temp INDEX 1.
    DELETE lt_excel_temp WHERE emp_id  IS INITIAL AND dev_id IS INITIAL.
    " Filter with current dev id details
    lt_excel_filter = VALUE #( ( emp_id = keys[ 1 ]-EmpId dev_id = keys[ 1 ]-DevId ) ).
    " excel data with  current dev id details
    lt_excel = FILTER #( lt_excel_temp IN lt_excel_filter WHERE emp_id = emp_id AND dev_id = dev_id ).
    IF lt_excel IS  INITIAL.

      reported = VALUE #( BASE reported user = VALUE #( ( %tky = keys[ 1 ]-%tky
                                                                        %msg = new_message_with_text( severity =
                                                                        if_abap_behv_message=>severity-error
                                                                        text = 'Trying to insert Invalid /Blank Values.' )
                                                                      ) )  ).
    ELSE.
      "Fill serial number
      LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
        <lfs_excel>-serial_no = sy-tabix.
      ENDLOOP.

      "Prepare Data for  Child Entity (UserDev)
      lt_data = VALUE #(
          (   %cid_ref  = keys[ 1 ]-%cid_ref
              EmpId   = keys[ 1 ]-EmpId
              DevId    = keys[ 1 ]-DevId
              %target   = VALUE #(
                               FOR lwa_excel IN lt_excel (
                                    %cid         = keys[ 1 ]-%cid_ref
                                    %data = VALUE #(
                                                     EmpId = keys[ 1 ]-EmpId
                                                     DevId = keys[ 1 ]-DevId
                                                     SerialNo = lwa_excel-serial_no
                                                     ObjectType = lwa_excel-obj_type
                                                     ObjectName = lwa_excel-obj_name
                                                  )
                                     %control = VALUE #(
                                                     EmpId = if_abap_behv=>mk-on
                                                     DevId = if_abap_behv=>mk-on
                                                     SerialNo = if_abap_behv=>mk-on
                                                     ObjectType = if_abap_behv=>mk-on
                                                     ObjectName = if_abap_behv=>mk-on

                                        )
                      ) ) ) ).

      "Delete Existing entry for user if any
      READ ENTITIES OF zi_2123_user IN LOCAL MODE
      ENTITY User BY \_UserDev
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_UserDev).

      IF lt_existing_UserDev IS NOT INITIAL.
        MODIFY ENTITIES OF zi_2123_user IN LOCAL MODE
        ENTITY UserDev DELETE FROM VALUE #(
          FOR lwa_data IN lt_existing_UserDev (
            %key        = lwa_data-%key
          )
        )
        MAPPED DATA(lt_del_mapped)
        REPORTED DATA(lt_del_reported)
        FAILED DATA(lt_del_failed).
      ENDIF.

      "Add New Entry for XLData (association)
      MODIFY ENTITIES OF ZI_2123_User IN LOCAL MODE
      ENTITY User CREATE BY \_UserDev
      AUTO FILL CID WITH lt_data.

*    "Modify Status
      MODIFY ENTITIES OF ZI_2123_User IN LOCAL MODE
      ENTITY User
      UPDATE FROM VALUE #(  (
          %tky        = lt_file_entity[ 1 ]-%tky "keys[ 1 ]-%tky
          FileStatus  = 'Excel Uploaded'
          %control-FileStatus = if_abap_behv=>mk-on ) )
      MAPPED DATA(lt_upd_mapped)
      FAILED DATA(lt_upd_failed)
      REPORTED DATA(lt_upd_reported).

      "Read Updated Entry
      READ ENTITIES OF ZI_2123_User IN LOCAL MODE
      ENTITY User ALL FIELDS WITH CORRESPONDING #( Keys )
      RESULT DATA(lt_updated_User).

      "Send Status back to front end
      result = VALUE #(
        FOR lwa_upd_head IN lt_updated_User (
          %tky    = lwa_upd_head-%tky
          %param  = lwa_upd_head
        )
      ).
      IF lt_upd_failed IS INITIAL.
   reported = VALUE #( BASE reported user = VALUE #( ( %tky = keys[ 1 ]-%tky
 %msg = new_message_with_text( severity =                                                                 if_abap_behv_message=>severity-success
                       text = 'Excel Uploaded Successfully.' )
  ) )  ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD FillFileStatus.
   "Read the data to be modified
    READ ENTITIES OF ZI_2123_User IN LOCAL MODE
    ENTITY User FIELDS ( EmpId DevId FileStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_user).

    "Update File Status
    LOOP AT lt_user INTO DATA(ls_user).
      MODIFY ENTITIES OF ZI_2123_User IN LOCAL MODE
      ENTITY User
      UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( (
          %tky                  = ls_user-%tky
          %data-FileStatus      = 'File not Selected'
          %data-TemplateStatus      = 'Absent'
          %control-FileStatus   = if_abap_behv=>mk-on
           %control-TemplateStatus   = if_abap_behv=>mk-on
          ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD FillSelectedStatus.
  "Read XL_Head Entities and change file status
    READ ENTITIES OF ZI_2123_user IN LOCAL MODE
    ENTITY User ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_User).

    "Update File Status
    LOOP AT lt_User INTO DATA(ls_user).
      MODIFY ENTITIES OF ZI_2123_user IN LOCAL MODE
      ENTITY User
      UPDATE FIELDS ( FileStatus TemplateStatus  )
      WITH VALUE #( (
          %tky                  = ls_user-%tky
          %data-FileStatus      = COND #(
                                    WHEN ls_user-Attachment IS INITIAL
                                    THEN 'File not Selected'
                                    ELSE 'File Selected' )
          %control-FileStatus   = if_abap_behv=>mk-on
          ) ).
    ENDLOOP.

    READ ENTITIES OF ZI_2123_user IN LOCAL MODE
  ENTITY User ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_User_updated).
    "Update template Status
    LOOP AT lt_User_updated INTO DATA(ls_user_updated).
      MODIFY ENTITIES OF ZI_2123_user IN LOCAL MODE
      ENTITY User
      UPDATE FIELDS ( TemplateStatus  )
      WITH VALUE #( (
                    %tky                = ls_user-%tky
                    %data-TemplateStatus = COND #(
                                    WHEN ls_user-Attachment IS NOT INITIAL
                                    THEN COND #( WHEN ls_user-FileStatus = 'File Selected' THEN ' ' )
                                    ELSE 'Absent'

                                     )
          %control-TemplateStatus   = if_abap_behv=>mk-on

          ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
