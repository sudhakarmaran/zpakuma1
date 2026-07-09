@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zi_sheader as select from zsheader
composition[ 1..* ] of zi_sitem as _ITEM
{
    key docnum as Docnum,
    createdby as createdby,
    
    @Semantics.largeObject: {
        mimeType: 'Mimetype',
        fileName: 'Filename',
        acceptableMimeTypes: [ 'application/vnd.ms-excel',
                       'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
        contentDispositionPreference: #ATTACHMENT

    }
    attachment as Attachment,
    mimetype as Mimetype,
    filename as Filename,
    lastchangedat as lastchangedat,
    _ITEM
}
