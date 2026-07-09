@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user devlopment details'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_2123_USER_DEV as select from ZT2123_USER_DEV
association to parent zi_2123_user as _User on  $projection.EmpId = _User.EmpId
                                              and $projection.DevId = _User.DevId
{
  key emp_id      as EmpId,
  key dev_id      as DevId,
  key serial_no   as SerialNo,
      object_type as ObjectType,
      object_name as ObjectName,
      _User 
}
