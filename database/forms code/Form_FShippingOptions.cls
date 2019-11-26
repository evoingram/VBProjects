VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_FShippingOptions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Command78_Click()
On Error Resume Next
'============================================================================
' Name        : Command78_Click
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call Command78_Click
' Description : exports to XML for standard shipping label and added entry to CommHistory table
'============================================================================

Dim sXMLLinkforCH As String, sSavedXMLFileName As String, sNewXMLFileName As String
Dim sQueryName As String
Dim sMacroName As String, sTSQExcelFileName As String, sTSO As String
Dim sTSOCourtDatesID As String, sUpdateShipOpt As String, sOutputXMLSQL As String
Dim rstCommHistory As DAO.Recordset, rstTempShippingOptionsQ As DAO.Recordset
Dim qdf As DAO.QueryDef, qdf1 As QueryDef
Dim oExcelApp As New Excel.Application, oExcelWorkbk As New Excel.Workbook, oExcelWksht As New Excel.Worksheet
Dim oExcelWorkbk2 As New Excel.Workbook
Dim rstOutputFieldXML As DAO.Recordset
Dim SQLString As String, sMailClassNo As String, sPackageTypeNo As String
Dim sMailClass As String, sPackageType As String, sTrackingNumber As String
Dim rs1 As DAO.Recordset, rstMailC As DAO.Recordset, rstPkgType As DAO.Recordset
Dim prm As DAO.Parameter

Call pfCurrentCaseInfo  'refresh transcript info
        
sQueryName = "TempShippingOptionsQ"
sTSQExcelFileName = "T:\Database\Scripts\InProgressExcels\TempShippingOptionsQ1.xlsm"

SQLString = "SELECT * FROM [ShippingOptions] WHERE [ShippingOptions].[CourtDatesID] = " & sCourtDatesID & ";"
Set rs1 = CurrentDb.OpenRecordset(SQLString)
sMailClassNo = rs1.Fields("MailClass").Value
sPackageTypeNo = rs1.Fields("PackageType").Value
rs1.Close

'(SELECT MailClass FROM MailClass WHERE [ID] = " & sMailClassNo & ") as MailClass
Set rstMailC = CurrentDb.OpenRecordset("SELECT MailClass FROM MailClass WHERE [ID] = " & sMailClassNo)
sMailClass = rstMailC.Fields("MailClass").Value
rstMailC.Close

'(SELECT PackageType FROM PackageType WHERE [ID] = " & sPackageTypeNo & ") as PackageType
Set rstPkgType = CurrentDb.OpenRecordset("SELECT PackageType FROM PackageType WHERE [ID] = " & sPackageTypeNo)
sPackageType = rstPkgType.Fields("PackageType").Value
rstPkgType.Close

sNewSQL = "SELECT " & Chr(34) & sMailClass & Chr(34) & " as MailClass, " & Chr(34) & sPackageType & Chr(34) & " as PackageType, Width, Length, Depth, PriorityMailExpress1030, HolidayDelivery, SundayDelivery, SaturdayDelivery, SignatureRequired, Stealth, ReplyPostage, InsuredMail, COD, RestrictedDelivery, AdultSignatureRestricted, AdultSignatureRequired, ReturnReceipt, CertifiedMail, SignatureConfirmation, USPSTracking, CourtDatesIDLK as ReferenceID, ToName, ToAddress1, ToAddress2, ToCity, ToState, ToPostalCode, Value, Description, WeightOz, ActualWeight, ActualWeightText, ToEmail, ToPhone FROM [ShippingOptions] WHERE [ShippingOptions].[CourtDatesID] = " & sCourtDatesID & ";"

Debug.Print (sNewSQL)


Set rstTempShippingOptionsQ = CurrentDb.OpenRecordset(sNewSQL)


sTSOCourtDatesID = rstTempShippingOptionsQ("CourtDatesID").Value
sOutputXMLSQL = "\\HUBCLOUD\evoingram\Production\4ShippingXMLs\Output\" & sCourtDatesID & "-Output.xml"
Set rstOutputFieldXML = CurrentDb.OpenRecordset("SELECT * FROM ShippingOptions WHERE [ShippingOptions].[CourtDatesID] = " & sCourtDatesID & ";")
rstOutputFieldXML.Edit
    rstOutputFieldXML.Fields("Output") = sOutputXMLSQL
rstOutputFieldXML.Update

Set oExcelApp = CreateObject("Excel.Application")
Set oExcelWorkbk = oExcelApp.Workbooks.Open(sTSQExcelFileName)
sTSO = "TempShippingOptionsQ"
Set oExcelWksht = oExcelWorkbk.Sheets(sTSO)
oExcelWksht.Cells(2, 1).Value = sOutputXMLSQL
oExcelWksht.Range("S2").CopyFromRecordset rstTempShippingOptionsQ
       
'For Each oExcelWorkbk2 In oExcelApp.Workbooks
   


 oExcelWorkbk.Save
     oExcelWorkbk.Close SaveChanges:=True
'Next oExcelWorkbk2

rstTempShippingOptionsQ.Close
Set rstTempShippingOptionsQ = Nothing
Set qdf1 = Nothing
 sMacroName = "ExportXML"

Call fRunXLSMacro(sTSQExcelFileName, sMacroName)

sSavedXMLFileName = "T:\Production\4ShippingXMLs\" & sCourtDatesID & "-shipping.xml"
sNewXMLFileName = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-shipping.xml"

FileCopy sSavedXMLFileName, sNewXMLFileName

'add shipping xml entry to comm history table
Set dbVideoCollection = CurrentDb
sXMLLinkforCH = sCourtDatesID & "-ShippingXML" & "#" & sSavedXMLFileName & "#"
Set rstCommHistory = CurrentDb.OpenRecordset("CommunicationHistory")
rstCommHistory.AddNew
rstCommHistory("FileHyperlink").Value = sXMLLinkforCH
rstCommHistory("DateCreated").Value = Now
rstCommHistory("CourtDatesID").Value = sCourtDatesID
rstCommHistory.Update

Set rstShippingOptions = CurrentDb.OpenRecordset("SELECT * FROM ShippingOptions WHERE CourtDatesID = " & sCourtDatesID & ";")
rstShippingOptions.MoveFirst
sTrackingNumber = rstShippingOptions.Fields("TrackingNumber").Value
rstShippingOptions.Close

MsgBox "Finished Exporting to XML for standard shipping label and added entry to CommHistory table."

Call fShippingExpenseEntry(sTrackingNumber)


If ((sJurisdiction) Like ("*" & "SUPERIOR COURT" & "*")) Then
    Call fCourtofAppealsIXML
End If

Call pfClearGlobals

End Sub

