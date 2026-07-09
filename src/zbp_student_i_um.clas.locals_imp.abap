CLASS lhc_student DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR student RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE student.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE student.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE student.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE student.

    METHODS read FOR READ
      IMPORTING keys FOR READ student RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK student.

    METHODS rba_Results FOR READ
      IMPORTING keys_rba FOR READ student\_Results FULL result_requested RESULT result LINK association_links.

    METHODS cba_Results FOR MODIFY
      IMPORTING entities_cba FOR CREATE student\_Results.

ENDCLASS.

CLASS lhc_student IMPLEMENTATION.

    METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.
      zstudent_api_class=>get_instance(  )->create_student(
    EXPORTING
    entities = entities
    CHANGING
      mapped = mapped
      failed = failed
      reported = reported

    ).
  ENDMETHOD.

  METHOD earlynumbering_create.
    TRY.
        zstudent_api_class=>get_instance(  )->earlynumbering_create(
        EXPORTING
        entities = entities
        CHANGING
        mapped = mapped
        failed = failed
        reported = reported
        ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD update.
      zstudent_api_class=>get_instance(  )->update_student(
EXPORTING
  entities = entities
CHANGING
  mapped = mapped
  failed = failed
  reported = reported
).
  ENDMETHOD.

  METHOD delete.
    zstudent_api_class=>get_instance(  )->delete_data(
  EXPORTING
    keys = keys
  CHANGING
    mapped = mapped
    failed = failed
    reported = reported

  ).
  ENDMETHOD.

  METHOD read.
    zstudent_api_class=>get_instance(  )->read_data(
  EXPORTING
    keys = keys
  CHANGING
    result = result
    failed = failed
    reported = reported

  ).
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_results.
  ENDMETHOD.

  METHOD cba_results.
    zstudent_api_class=>get_instance(  )->cba_results(
  EXPORTING
    entities_cba = entities_cba
  CHANGING
    mapped = mapped
    failed = failed
    reported = reported
  ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_results DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE results.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE results.

    METHODS read FOR READ
      IMPORTING keys FOR READ results RESULT result.

    METHODS rba_Student FOR READ
      IMPORTING keys_rba FOR READ results\_Student FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_results IMPLEMENTATION.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Student.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZSTUDENT_I_UM DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZSTUDENT_I_UM IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

   zstudent_api_class=>get_instance(  )->save_data(
    CHANGING
    reported = reported
    ).
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
