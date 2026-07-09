@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'INTERFACE VIEW FOR STUDENT'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZSTUDENT_I_UM as select from Zstudent_um
composition[0..*] of ZRESULT_I_UM as _results
{
    key id as Id,
    studentid as Studentid,
    firstname as Firstname,
    lastname as Lastname,
    age as Age,
    course as Course,
    courseduration as Courseduration,
    status as Status,
    gender as Gender,
    dob as Dob,
    lastchangedat as Lastchangedat,
    locallastchangedat as Locallastchangedat,
    genderdesc as Genderdesc,
    _results
}
