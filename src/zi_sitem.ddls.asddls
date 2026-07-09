@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zi_sitem as select from zsitem
association to parent zi_sheader as _HEADER
on $projection.Docnum = _HEADER.Docnum
{
    key docnum as Docnum,
    itemno as Itemno,
    material as Material,
    _HEADER
}
