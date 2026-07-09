@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RESULT INTERFACE VIEW'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zRESULT_I_UM as select from Zresult_um
association to parent ZSTUDENT_I_UM as _Student on 
$projection.Id = _Student.Id
{
    key id as Id,
    course as Course,
    semester as Semester,
    course_desc as Course_Desc,
    semester_desc as Semester_Desc,
    semresult as Sem_result,
    sem_desc as Sem_Desc,
    _Student
}
