@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_2123_USER_DEV
  as projection on ZI_2123_user_dev
{
  key EmpId,
  key DevId,
  key SerialNo,
      ObjectType,
      ObjectName,
      _User : redirected to parent ZC_2123_USER
}
