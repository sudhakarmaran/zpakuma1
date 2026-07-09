CLASS zstudent_api_class DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  TYPES:
      tt_create_student TYPE TABLE FOR CREATE Zstudent_I_um\\student,
      tt_mapped_early   TYPE RESPONSE FOR MAPPED EARLY Zstudent_I_um,
      tt_failed_early   TYPE RESPONSE FOR FAILED EARLY zstudent_I_um,
      tt_response_early TYPE RESPONSE FOR FAILED EARLY zstudent_I_um,
      tt_reported_early TYPE RESPONSE FOR REPORTED EARLY zstudent_I_um,
      tt_reported_late  TYPE RESPONSE FOR REPORTED LATE zstudent_I_um,
      tt_student_keys   TYPE TABLE FOR READ IMPORT zstudent_I_um\\student,
      tt_student_result TYPE TABLE FOR READ RESULT zstudent_I_um\\student,
      tt_student_update TYPE TABLE FOR UPDATE zstudent_I_um\\student,

      tt_cba_results    TYPE TABLE FOR CREATE zstudent_I_um\\student\_results,
      tt_student_delete TYPE TABLE FOR DELETE zstudent_I_um\\student.



    CLASS-METHODS : get_instance RETURNING VALUE(ro_instance) TYPE REF TO zstudent_api_class.


    METHODS:
      earlynumbering_create
        IMPORTING entities TYPE tt_create_student
        CHANGING  mapped   TYPE tt_mapped_early
                  failed   TYPE tt_response_early
                  reported TYPE tt_reported_early.

    METHODS
      create_student
        IMPORTING entities TYPE tt_create_student
        CHANGING  mapped   TYPE tt_mapped_early
                  failed   TYPE tt_response_early
                  reported TYPE tt_reported_early.

    METHODS
      save_data
        CHANGING reported TYPE tt_reported_late.

    METHODS
      read_data
        IMPORTING keys     TYPE tt_student_keys
        CHANGING  result   TYPE tt_student_result
                  failed   TYPE tt_failed_early
                  reported TYPE tt_reported_early.

    METHODS
      update_student
        IMPORTING entities TYPE tt_student_update
        CHANGING  mapped   TYPE tt_mapped_early
                  failed   TYPE tt_failed_early
                  reported TYPE tt_reported_early.

*    METHODS
*    earlynumbering_cba_results
*            importing  entities type tt_cba_results
*            changing    mapped  type tt_mapped_early
*            failed  type tt_failed_early
*            reported    type tt_reported_early.

    METHODS
      cba_results
        IMPORTING entities_cba TYPE tt_cba_results
        CHANGING  mapped       TYPE tt_mapped_early
                  failed       TYPE tt_failed_early
                  reported     TYPE tt_reported_early.

    METHODS
      delete_data
        IMPORTING keys     TYPE tt_student_delete
        CHANGING  mapped   TYPE tt_mapped_early
                  failed   TYPE tt_failed_early
                  reported TYPE tt_reported_early.
  PROTECTED SECTION.
  CLASS-DATA : mo_instance  TYPE REF TO zstudent_api_class,
                 gt_student   TYPE STANDARD TABLE OF zstudent_um,
                 gs_mapped    TYPE tt_mapped_early,
                 gt_results   TYPE STANDARD TABLE OF zresult_um,
                 gr_student_d TYPE RANGE OF zstudent_um-id.

  PRIVATE SECTION.
ENDCLASS.



CLASS zstudent_api_class IMPLEMENTATION.
 METHOD get_instance.
    mo_instance = ro_instance = COND #( WHEN mo_instance IS BOUND THEN  mo_instance
                                                            ELSE NEW #(  )   ).

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(ls_mapped) = gs_mapped.

    TRY.
        DATA(lv_new_id) = cl_uuid_factory=>create_system_uuid(  )->create_uuid_x16(  ).
      CATCH cx_uuid_error INTO DATA(lv_data).
    ENDTRY.
    READ TABLE gt_student ASSIGNING FIELD-SYMBOL(<lfs_student>) INDEX 1.
    IF <lfs_student> IS ASSIGNED.
      <lfs_student>-id = lv_new_id.
      UNASSIGN <lfs_student>.
    ENDIF.

    mapped-student = VALUE #(
    FOR ls_entities IN entities WHERE ( id IS INITIAL )
    (
        %cid = ls_entities-%cid
        %is_draft = ls_entities-%is_draft
        id = lv_new_id
     )
    ).
  ENDMETHOD.

  METHOD create_student.

    gt_student = CORRESPONDING #( entities MAPPING FROM ENTITY ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>).
      IF gt_student IS NOT INITIAL.

        mapped-student = VALUE #( (
            %cid = <lfs_entities>-%cid
            %key = <lfs_entities>-%key
            %is_draft = <lfs_entities>-%is_draft

        )   ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD save_data.
    IF gt_student IS NOT INITIAL.

      MODIFY zstudent_um FROM TABLE @gt_student.

    ENDIF.

    IF gt_results[] IS NOT INITIAL.
      MODIFY zresult_um FROM TABLE @gt_results.
    ENDIF.

    IF gr_student_d IS NOT INITIAL.
      DELETE FROM zstudent_um WHERE id IN @gr_student_d.
    ENDIF.
  ENDMETHOD.

  METHOD read_data.
    SELECT * FROM zstudent_um FOR ALL ENTRIES IN @keys
        WHERE id = @keys-id
        INTO TABLE @DATA(lt_student_data).

    result = CORRESPONDING #( lt_student_data MAPPING TO ENTITY ).



  ENDMETHOD.

  METHOD update_student.

    DATA : lt_student_update   TYPE STANDARD TABLE OF zstudent_um,
           lt_student_update_x TYPE STANDARD TABLE OF zcs_stud_prop_um.
*           lt_student_update_old TYPE STANDARD TABLE OF zcs_stud_prop_um.
*           ls_student_old TYPE zstudent_um.


    lt_student_update = CORRESPONDING #(  entities MAPPING FROM ENTITY  ).
    lt_student_update_x = CORRESPONDING #( entities MAPPING FROM ENTITY USING CONTROL ).

    IF lt_student_update IS NOT INITIAL.

      SELECT * FROM zstudent_um
      FOR ALL ENTRIES IN @lt_student_update
      WHERE id = @lt_student_update-id
      INTO TABLE @DATA(lt_student_update_old).
    ENDIF.

    gt_student = VALUE #(

    FOR x = 1 WHILE x <= lines( lt_student_update )

    LET
     ls_control_flag = VALUE #( lt_student_update_x[ x ] OPTIONAL )
     ls_student_new = VALUE #( lt_student_update[ x ] OPTIONAL )
     ls_student_old = VALUE #( lt_student_update_old[ id = ls_student_new-id ] OPTIONAL )

     IN
     (
      id = ls_student_new-id
*             studentid = cond #(  when ls_control_flag-studentid is not initial
*                                THEN ls_student_new-studentid ELSE ls_student_old-studentid )

      firstname = COND #(  WHEN ls_control_flag-firstname IS NOT INITIAL
                         THEN ls_student_new-firstname ELSE ls_student_old-firstname )

      lastname = COND #(  WHEN ls_control_flag-lastname IS NOT INITIAL
                         THEN ls_student_new-lastname ELSE ls_student_old-lastname )

         age = COND #(  WHEN ls_control_flag-age IS NOT INITIAL
                         THEN ls_student_new-age ELSE ls_student_old-age )

     course = COND #(  WHEN ls_control_flag-course IS NOT INITIAL
                         THEN ls_student_new-course ELSE ls_student_old-course )

     courseduration = COND #(  WHEN ls_control_flag-courseduration IS NOT INITIAL
                         THEN ls_student_new-courseduration ELSE ls_student_old-courseduration )

*            studentstatus = cond #(  when ls_control_flag-studentstatus is not initial
*                                THEN ls_student_new-sudentstatus ELSE ls_student_old-studentstatus )
*
     gender = COND #(  WHEN ls_control_flag-gender IS NOT INITIAL
                         THEN ls_student_new-gender ELSE ls_student_old-gender )

     dob = COND #(  WHEN ls_control_flag-dob IS NOT INITIAL
                         THEN ls_student_new-dob ELSE ls_student_old-dob )
     )



     ).



  ENDMETHOD.



  METHOD cba_results.

    gt_results = VALUE #(

        FOR ls_entities_cba IN entities_cba
            FOR ls_results_cba IN ls_entities_cba-%target
            LET
            ls_rap_results = CORRESPONDING zresult_um(
            ls_results_cba MAPPING FROM ENTITY
              )

            IN
            (
            ls_rap_results
            )
    ).

    mapped = VALUE #(
        results = VALUE #(
            FOR i = 1 WHILE i <= lines( entities_cba )

            LET
            lt_results = VALUE #( entities_cba[ i ]-%target OPTIONAL )
        IN
        FOR j = i WHILE j <= lines( lt_results )

        LET
        ls_curr_results = VALUE #(  lt_results[ j ] OPTIONAL )
        IN
        (
        %cid = ls_curr_results-%cid
        %key = ls_curr_results-%key
        id = ls_curr_results-id


         )



        )



     ).



  ENDMETHOD.

  METHOD delete_data.
    DATA : lt_student TYPE STANDARD TABLE OF zstudent_um.
    lt_student = CORRESPONDING #(  keys MAPPING FROM ENTITY ).

    gr_student_d = VALUE #(


    FOR ls_student_d IN lt_student
        sign = 'I'
        option = 'EQ'
      (   low = ls_student_d-id ) ).



  ENDMETHOD.
ENDCLASS.
