Attribute VB_Name = "DocGen"
'@Folder("Database.Production.Modules")
Option Compare Database
Option Explicit

'============================================================================
'class module cmDocGen

'variables:
'   NONE

'functions:
    'pfGenericExportandMailMerge:  Description:  exports to specified template from T:\Database\Templates and saves in I:\####\
        '                          Arguments:    sQueryName, sExportTopic
    'pfSendWordDocAsEmail:         Description:  sends Word document as an e-mail body
        '                          Arguments:    vCHTopic, vSubject, Optional sAttachment1, sAttachment2, sAttachment3, sAttachment4
    'pfCreateCDLabel:               Description:  makes CD label and prompts for print or no
        '                          Arguments:    NONE
    'pfSelectCoverTemplate:        Description:  parent function to create correct transcript cover/skeleton from template
        '                          Arguments:    NONE
    'pfCreateCover:                Description:  creates transcript cover/skeleton from template
        '                          Arguments:    sTemplatePath
    'fCreatePELLetter:             Description:  creates package enclosed letter
        '                          Arguments:    NONE
    'fFactorInvoicEmailF:          Description:  creates e-mail to submit invoice to factoring
        '                          Arguments:    NONE
    'fInfoNeededEmailF:            Description:  creates info needed e-mail
        '                          Arguments:    NONE
    'pfInvoicesCSV:                Description:  creates CSVs used for invoicing
        '                          Arguments:    NONE
    'fCreateWorkingCopy:           Description:  creates "working copy" sent to client
        '                          Arguments:    NONE
    'fSendShippingTrackingEmail:   Description:  creates shipping confirmation e-mail sent to client
        '                          Arguments:    NONE
        
'============================================================================

Public Sub pfGenericExportandMailMerge(sMerge As String, sExportTopic As String)
'============================================================================
' Name        : pfGenericExportandMailMerge
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfGenericExportandMailMerge(sQueryName, sExportTopic)
' Description:  exports to specified template from T:\Database\Templates and saves in I:\####\
'============================================================================

Dim sExportedTemplatePath As String, sTemplatePath As String, sOutputPDF As String
Dim sExportInfoCSVPath As String, sQueryName As String
Dim iCount As Integer
Dim oWordAppDoc As Object
Dim qdf As QueryDef
Dim rstQuery As DAO.Recordset
Dim xlRange As Excel.Range, oExcelWB As Excel.Workbook, oExcelApp As Excel.Application

sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]

If sMerge = "Case" Then

    sQueryName = qnTRCourtUnionAppAddrQ
    sExportInfoCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-CaseInfo.xls"
    
ElseIf sMerge = "Invoice" Then

    sQueryName = "QInfobyInvoiceNumber"
    sExportInfoCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-InvoiceInfo.xls"
    
End If
iCount = Len(Dir(sExportInfoCSVPath))

If iCount = 0 Then

    DoCmd.OutputTo acOutputQuery, sQueryName, acFormatXLS, sExportInfoCSVPath, False
        
    Set oExcelApp = CreateObject("Excel.Application")
    oExcelApp.Application.Visible = False
    oExcelApp.Application.DisplayAlerts = False
    
    Set oExcelWB = oExcelApp.Workbooks.Open(sExportInfoCSVPath)
    oExcelWB.Application.DisplayAlerts = False
    oExcelWB.Application.Visible = False
    
    With oExcelWB
    
        Set xlRange = .Worksheets(1).Range("A2").CurrentRegion
        .Names.Add Name:="AAAAADataRange", RefersTo:=xlRange
        .SaveAs FileName:=sExportInfoCSVPath
        .Saved = True
        .Close
    End With
    
    oExcelApp.Quit


Else
    'do nothing if it exists
    
End If

Dim sArray() As String, sExportTopic1 As String
sArray = Split(sExportTopic, "\")
sExportTopic1 = sArray(1)
sExportedTemplatePath = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-" & sExportTopic1 & ".docx"

sTemplatePath = "T:\Database\Templates\" & sExportTopic & "-Template.docx" 'export topic is folder\subject


Set oWordAppDoc = GetObject(sTemplatePath, "Word.Document")
oWordAppDoc.Application.Visible = False

oWordAppDoc.MailMerge.OpenDataSource _
    Name:=sExportInfoCSVPath, _
    ConfirmConversions:=False, ReadOnly:=True, LinkToSource:=True, _
    AddToRecentFiles:=False, SQLStatement:="SELECT * FROM `AAAAADataRange`" ', Revert:=False, _
    Format:=wdOpenFormatAuto _
    , SQLStatement:="SELECT * FROM `AAAAADataRange`", SQLStatement1:=""
    'SubType:=wdMergeSubTypeAccess
', Connection:= _
        "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & sExportedTemplatePath & ";Mode=Read;Extended Properties=" & Chr(34) & Chr(34) & "HDR=YES;IMEX=1;" _
        & Chr(34) & Chr(34) & ";Jet OLEDB:System database=" & Chr(34) & Chr(34) & Chr(34) & Chr(34) & _
        ";Jet OLEDB:Engine Type=34;Jet OLEDB"
        
oWordAppDoc.MailMerge.Execute

oWordAppDoc.MailMerge.MainDocumentType = wdNotAMergeDocument
sOutputPDF = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-" & sExportTopic1 & ".pdf"
oWordAppDoc.Application.ActiveDocument.ExportAsFixedFormat outputFileName:=sOutputPDF, ExportFormat:=wdExportFormatPDF, CreateBookmarks:=wdExportCreateHeadingBookmarks
oWordAppDoc.Application.ActiveDocument.SaveAs FileName:=sExportedTemplatePath

oWordAppDoc.Application.ActiveDocument.Close
Set oWordAppDoc = Nothing

End Sub

Public Sub pfSendWordDocAsEmail(vCHTopic As String, vSubject As String, _
        Optional sAttachment1 As String, Optional sAttachment2 As String, _
        Optional sAttachment3 As String, Optional sAttachment4 As String)
On Error Resume Next
'============================================================================
' Name        : pfSendWordDocAsEmail
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfSendWordDocAsEmail(vCHTopic, vSubject, sAttachment1, sAttachment2, sAttachment3, sAttachment4)
                'attachments optional
' Description:  sends Word document as an e-mail body
'============================================================================
Dim sTemplateAddress As String, sCourtDatesID As String
Dim oOutlookApp As Outlook.Application, oOutlookMail As Outlook.MailItem, oWordApp As New Word.Application
Dim oWordEditor As Word.editor, oWordDoc As New Word.Document

sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]

sTemplateAddress = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-" & vCHTopic & ".docx"
Set oOutlookApp = CreateObject("Outlook.Application")
Set oOutlookMail = oOutlookApp.CreateItem(0)
Set oWordApp = CreateObject("Word.Application")
Set oWordDoc = oWordApp.Documents.Open(sTemplateAddress)
oWordDoc.Content.Copy
With oOutlookMail
    .To = ""
    .CC = ""
    .BCC = ""
        .Subject = vSubject
        .BodyFormat = olFormatRichText
        Set oWordEditor = .GetInspector.WordEditor
        .GetInspector.WordEditor.Content.Paste
        .Display
        If sAttachment1 = "" And sAttachment2 = "" And sAttachment3 = "" And sAttachment4 = "" Then GoTo LoopExit
        If Not sAttachment1 = "" Then GoTo At1
        If Not sAttachment1 = "" And sAttachment2 = "" Then GoTo At2
        If Not sAttachment1 = "" And sAttachment2 = "" And sAttachment3 = "" Then GoTo At3
        If Not sAttachment1 = "" And sAttachment2 = "" And sAttachment3 = "" And sAttachment4 = "" Then GoTo At4
At4:
        .Attachments.Add (sAttachment4)
At3:
        .Attachments.Add (sAttachment3)
At2:
        .Attachments.Add (sAttachment2)
At1:
        .Attachments.Add (sAttachment1)
LoopExit:
    End With
    
On Error GoTo 0
Set oWordApp = Nothing
oWordDoc.Close
oWordApp.Quit
End Sub

Public Sub pfCreateCDLabel()
'============================================================================
' Name        : pfCreateCDLabel
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfCreateCDLabel
' Description : makes CD label and prompts for print or no
'============================================================================

Dim sPubDocName As String
Dim sCommHistoryHyperlink As String
Dim sCDLExcelExport As String
'Dim sPubDocPDFName As String
Dim sAnswer As String
Dim sQuestion As String
Dim oPubDoc As Publisher.Document
Dim oPubApp As Publisher.Application
Dim dbVideoCollection As DAO.Database
Dim rstVideos As DAO.Recordset

sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]


Call pfCheckFolderExistence 'check for main folders and create if not exists

Call pfCurrentCaseInfo  'refresh transcript info



'DoCmd.OutputTo ObjectType:=acOutputQuery, ObjectName:=qnTRCourtUnionAppAddrQ, OutputFormat:=acFormatXLS, Outputfile:=sCDLExcelExport, AutoStart:=False 'query info for label


sCDLExcelExport = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-CaseInfo.xls"
DoCmd.TransferSpreadsheet TransferType:=acExport, TableName:=qnTRCourtUnionAppAddrQ, FileName:=sCDLExcelExport

Set oPubApp = New Publisher.Application
Set oPubDoc = oPubApp.Open("T:\Database\Templates\Stage1s\CD-Label.pub")

sPubDocName = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-CD-Label" & ".pub" 'set name
'sPubDocPDFName = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-CD-Label" & ".pdf" 'set name
sCommHistoryHyperlink = sCourtDatesID & "-CD-Label" & "#" & sPubDocName


oPubDoc.MailMerge.OpenDataSource bstrDataSource:=sCDLExcelExport, bstrTable:="", fOpenExclusive:=True, fneverprompt:=1 'performs mail merge
oPubDoc.MailMerge.Execute Pause:=True, Destination:=pbMergeToNewPublication
oPubDoc.SaveAs FileName:=sPubDocName 'saves file in job number folder in in progress
oPubDoc.Close
oPubApp.Quit
Set dbVideoCollection = CurrentDb
Set rstVideos = dbVideoCollection.OpenRecordset("CommunicationHistory")

'Adds record to CommHistoryTable and link to document on hard drive
rstVideos.AddNew
rstVideos("FileHyperlink").Value = sCommHistoryHyperlink
rstVideos("DateCreated").Value = Now
rstVideos("CourtDatesID").Value = sCourtDatesID
rstVideos("CustomersID").Value = sCustomerID
rstVideos.Update




'sQuestion = "Want to burn the CD?"
'sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???")

'If sAnswer = vbNo Then 'Code for No
'    MsgBox "No CD will be burned at this time.  You're done!"
    
'Else 'Code for yes

        'Call pfBurnCD
    
'End If



'sQuestion = "Print CD Label? (MAKE SURE PAPER IS CORRECT IN PRINTER)"
'sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???") '

'If sAnswer = vbNo Then 'Code for No

'    MsgBox "CD label will not print."
    
'Else 'Code for yes

'    Call fEmailtoPrint(sPubDocPDFName)
'    Set oPubDoc = Nothing
    
'End If

Call fPrintKCIEnvelope


Call pfClearGlobals
End Sub


Public Sub pfSelectCoverTemplate()
'============================================================================
' Name        : pfSelectCoverTemplate
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfSelectCoverTemplate
' Description : parent function to create correct transcript cover/skeleton from template
'============================================================================

Dim sFDAQuery As String


Call pfCheckFolderExistence 'checks for job folder and creates it if not exists

sFDAQuery = "Food" & "*" & "and" & "*" & "Drug" & "*" & "Administration"

Call pfCurrentCaseInfo  'refresh transcript info

If ((sJurisdiction) Like ("*" & sFDAQuery & "*")) Then
    pfCreateCover ("Stage2s\TR-JEW-FDA.doc")
ElseIf sJurisdiction = "AVT USBC" Then pfCreateCover ("Stage2s\TR-AVT-Bankruptcy.dotm")
ElseIf sJurisdiction = "Weber Oregon" Then pfCreateCover ("Stage2s\TR-WeberOregon-Template.dotm")
ElseIf sJurisdiction = "Weber Nevada" Then pfCreateCover ("Stage2s\TR-WeberNevada-Template.dotm")
ElseIf sJurisdiction = "Weber Bankruptcy" Then pfCreateCover ("Stage2s\TR-WeberBankruptcy-Template.dotm")
ElseIf sJurisdiction = "Non-Court" Then pfCreateCover ("Stage2s\TR-noncourt.docx")
ElseIf sJurisdiction Like "District" & " " & "of" & " " Then pfCreateCover ("Stage2s\TR-Bankruptcy.dotm")
ElseIf sJurisdiction = "JJ BK" Then pfCreateCover ("Stage2s\TR-JJ-Bankruptcy.docx")
ElseIf sJurisdiction = "JJ NJ" Then pfCreateCover ("Stage2s\TR-JJ-NJ.docx")
ElseIf sJurisdiction = "AVT NH" Then pfCreateCover ("Stage2s\TR-AVT-NH.dotm")
ElseIf sJurisdiction = "AVTOC" Then pfCreateCover ("Stage2s\TR-AVT-OC-CA.dotm")
ElseIf sJurisdiction = "eScribers NH" Then pfCreateCover ("Stage2s\TR-AVT-NH.dotm")
ElseIf sJurisdiction = "eScribers AVT NH" Then pfCreateCover ("Stage2s\TR-AVT-NH.dotm") '1.3.2
ElseIf sJurisdiction = "eScribers Bankruptcy" Then pfCreateCover ("Stage2s\TR-AVT-Bankruptcy.dotm")
ElseIf sJurisdiction = "eScribers bankruptcy" Then pfCreateCover ("Stage2s\TR-AVT-Bankruptcy.dotm")
ElseIf sJurisdiction Like "Massachusetts" Then pfCreateCover ("Stage2s\TR-Mass.dotm")
Else: pfCreateCover ("Stage2s\TR-WACounties.dotm")
End If

Call pfCommunicationHistoryAdd("CourtCover")
Call pfClearGlobals
End Sub

Public Sub pfCreateCover(sTemplatePath As String)
'============================================================================
' Name        : pfCreateCover
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfCreateCover(sTemplatePath)
' Description : creates transcript cover/skeleton from template
'============================================================================

Dim sCourtCoverYesExt As String, sCourtCoverNoExt As String, sCommHistoryAddSQL As String
'Dim sExportInfoCSVPath As String
Dim sFullTemplatePath As String
Dim oExcelApp As New Excel.Application, oExcelWB As New Excel.Workbook
Dim oWordApp As New Word.Application, oWordDoc As New Word.Document
Dim xlRange As Excel.Range
Dim oDocuments As Object, sSource As String, sQueryName As String
Dim x As Integer, iCount As Integer
Dim rstCommHistory As DAO.Recordset
Call pfCurrentCaseInfo  'refresh transcript info

'sExportInfoCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-CaseInfo.xls"
sCourtCoverYesExt = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-CourtCover.docx"
sCourtCoverNoExt = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-CourtCover"
sFullTemplatePath = "T:\Database\Templates\" & sTemplatePath 'sTemplatePath is folder\subject


'If sMerge = "Case" Then

    sQueryName = qnTRCourtUnionAppAddrQ
    sExportInfoCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-CaseInfo.xls"
    
'ElseIf sMerge = "Invoice" Then

 '   sQueryName = "QInfobyInvoiceNumber"
  '  sExportInfoCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-InvoiceInfo.xls"
    
'End If

iCount = Len(Dir(sExportInfoCSVPath))

If iCount = 0 Then

    DoCmd.OutputTo acOutputQuery, sQueryName, acFormatXLS, sExportInfoCSVPath, False
    
    Set oExcelApp = CreateObject("Excel.Application")
    oExcelApp.Application.Visible = False
    oExcelApp.Application.DisplayAlerts = False
    
    Set oExcelWB = oExcelApp.Application.Workbooks.Open(sExportInfoCSVPath)
    oExcelWB.Application.DisplayAlerts = False
    oExcelWB.Application.Visible = False
    
    With oExcelWB
        Set xlRange = .Worksheets(1).Range("A2").CurrentRegion
        .Names.Add Name:="AAAAADataRange", RefersTo:=xlRange
        .SaveAs FileName:=sExportInfoCSVPath
        .Saved = True
        .Close
    End With
    
    oExcelApp.Application.Quit


Else
    'do nothing if it exists
    
End If

On Error Resume Next
Set oWordApp = GetObject(, "Word.Application")

If Err <> 0 Then
    Set oWordApp = CreateObject("Word.Application")
End If

With oWordApp
    .Application.DisplayAlerts = False
    .Application.Visible = True
End With

Set oWordDoc = GetObject(sFullTemplatePath, "Word.Document")

On Error GoTo 0

With oWordDoc
    .MailMerge.OpenDataSource _
          Name:=sExportInfoCSVPath, ReadOnly:=False, _
        ConfirmConversions:=False, LinkToSource:=True, _
        AddToRecentFiles:=False, PasswordDocument:="", PasswordTemplate:="", _
        WritePasswordDocument:="", WritePasswordTemplate:="", Revert:=False, _
        Format:=wdOpenFormatAuto, Connection:= _
            "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & sCourtCoverYesExt & ";Mode=Read;Extended Properties=" & Chr(34) & Chr(34) & "HDR=YES;IMEX=1;" _
            & Chr(34) & Chr(34) & ";Jet OLEDB:System database=" & Chr(34) & Chr(34) & Chr(34) & Chr(34) & ";Jet OLEDB:Registry Path=" & Chr(34) & Chr(34) & Chr(34) & Chr(34) & _
            ";Jet OLEDB:Engine Type=34;Jet OLEDB;" _
        , SQLStatement:="SELECT * FROM `AAAAADataRange`", SQLStatement1:="", _
        SubType:=wdMergeSubTypeAccess
          
    .MailMerge.DataSource.FirstRecord = wdDefaultFirstRecord
    .MailMerge.DataSource.LastRecord = wdDefaultLastRecord
    .MailMerge.Execute
    .MailMerge.MainDocumentType = wdNotAMergeDocument
    
End With
'EndTime

Set oDocuments = Documents
For x = oDocuments.Count To 1 Step -1
    Debug.Print x
    sSource = ActiveWindow.Caption
    
    If sSource <> "Form Letters1" Then
    
    If sSource <> sCourtDatesID & "-CourtCover.docx" Then
        sSource = Left(sSource, Len(sSource) - 22)
        sSource = Trim(sSource)
    End If
    End If
    
    Debug.Print sSource
    If sSource = "Form Letters1" Then
        Documents("Form Letters1").Activate
        Documents("Form Letters1").SaveAs FileName:=sCourtCoverYesExt
    Else
        Documents(sSource).Activate
        Documents(sSource).Close SaveChanges:=wdDoNotSaveChanges
    End If
    
Next x

'ActiveDocument.Close
Set oExcelWB = Nothing
Set oWordApp = Nothing
Set oExcelApp = Nothing


Call pfCreateBookmarks

Call pfCreateIndexesTOAs

'sCommHistoryAddSQL = "Update CommunicationHistory Set [CommunicationHistory].[Hyperlink]=" & Chr(34) & "[TR-Court-Union-AppAddr]![CourtDatesID]#" & sCourtCoverYesExt & Chr(34) & ";"
'CurrentDb.Execute sCommHistoryAddSQL


Set rstCommHistory = CurrentDb.OpenRecordset("CommunicationHistory")
rstCommHistory.AddNew
rstCommHistory.Fields("FileHyperlink").Value = sCourtDatesID & "#" & sCourtCoverYesExt
rstCommHistory.Fields("CourtDatesID").Value = sCourtDatesID
rstCommHistory.Fields("DateCreated").Value = Now
rstCommHistory.Update
rstCommHistory.Close
Set rstCommHistory = Nothing
Call pfClearGlobals
End Sub


Sub fCreatePELLetter()
'============================================================================
' Name        : fCreatePELLetter
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call fCreatePELLetter
' Description : creates package enclosed letter
'============================================================================

Dim sPELtrPDFPath As String, sPELtrWordPath As String, sQuestion As String, sAnswer As String


Call pfCurrentCaseInfo  'refresh transcript info

sPELtrWordPath = "T:\Database\Templates\Stage1s\PackageEnclosedLetter.docx"
sPELtrPDFPath = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-PackageEnclosedLetter" & ".pdf"

Call pfCheckFolderExistence 'checks for job folder and creates it if not exists
Call pfGenericExportandMailMerge("Case", "Stage1s\PackageEnclosedLetter")

sQuestion = "Print letter to enclose with transcript?"
sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???")

If sAnswer = vbNo Then 'Code for No
    MsgBox "Package-enclosed letter will not print."
Else 'Code for yes
    Call fEmailtoPrint(sPELtrPDFPath)
End If

Call pfCommunicationHistoryAdd("PackageEnclosedLetter")
Call pfClearGlobals
End Sub
Sub fFactorInvoicEmailF()
'============================================================================
' Name        : fFactorInvoicEmailF
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call fFactorInvoicEmailF
' Description : creates e-mail to submit invoice to factoring
'============================================================================

Dim sQuestion As String, sAnswer As String, sFactoringXLS As String, sUnitPrice As String
Dim sGenerateXeroCSVSQL As String, sGeneratedFactoringXLS As String, sInvoicePDFPath As String
Dim sContactName As String, sPONumber As String, sFactoringURL As String, sUnitPriceSQL As String
Dim sInvoiceAmount As String, sInvoiceNumber As String
Dim rstUPCourtDates As DAO.Recordset, rstUnitPrice As DAO.Recordset, rstFactoringCSV As DAO.Recordset
Dim dInvoiceDate As Date
Dim qdf As QueryDef
Dim db As DAO.Database
Dim oExcelApp As New Excel.Application, oExcelWB As New Excel.Workbook
Dim iNetTerm As Integer

Call pfCurrentCaseInfo  'refresh transcript info
Call pfCheckFolderExistence

Call pfGenericExportandMailMerge("Case", "Stage4s\FactorInvoiceEmail")

MsgBox "Factoring Invoice Email Created!"

Call pfCommunicationHistoryAdd("FactorInvoiceEmail")

'@Ignore AssignmentNotUsed
sFactoringXLS = "T:\Database\Templates\Stage4s\Client_Basic_Schedule.xls" 'make factoring csv
sGeneratedFactoringXLS = "I:\" & sCourtDatesID & "\WorkingFiles\" & "Client_Basic_Schedule.xls"

'TODO: fFactorInvoicEmailF can delete following lines when known safe come back
'sUnitPriceSQL = "SELECT UnitPrice from CourtDates where ID = " & sCourtDatesID & ";" 'get unitprice id
'Set db = CurrentDb
'Set rstUPCourtDates = CurrentDb.OpenRecordset(sUnitPriceSQL)
'sUnitPrice = rstUPCourtDates.Fields("UnitPrice").Value
'rstUPCourtDates.Close
'Set rstUPCourtDates = Nothing

sUnitPriceSQL = "SELECT Rate from UnitPrice where ID = " & sUnitPrice & ";" 'get proper rate
Set rstUnitPrice = CurrentDb.OpenRecordset(sUnitPriceSQL)
sUnitPrice = rstUnitPrice.Fields("Rate").Value
rstUnitPrice.Close
Set rstUnitPrice = Nothing

sGenerateXeroCSVSQL = "SELECT XeroInvoiceCSV.ContactName, XeroInvoiceCSV.InvoiceNumber, XeroInvoiceCSV.Reference, XeroInvoiceCSV.InvoiceDate, 28 From XeroInvoiceCSV WHERE XeroInvoiceCSV.Reference= " & sCourtDatesID & ";"
Set db = CurrentDb
Set qdf = CurrentDb.QueryDefs("FactoringCSVQuery")
Set qdf.Parameters(0) = sActualQuantity
Set qdf.Parameters(1) = sCourtDatesID
Set rstFactoringCSV = qdf.OpenRecordset
rstFactoringCSV.MoveFirst
sInvoiceAmount = (sActualQuantity * sUnitPrice)
iNetTerm = 28
sContactName = rstFactoringCSV.Fields("ContactName").Value
sInvoiceNumber = rstFactoringCSV.Fields("InvoiceNumber").Value
sPONumber = rstFactoringCSV.Fields("PO Number").Value
dInvoiceDate = rstFactoringCSV.Fields("Invoice Date").Value
sFactoringXLS = "T:\Database\Templates\Stage4s\Client_Basic_Schedule.xls"

DoCmd.OpenQuery "FactoringCSVQuery", acViewNormal, acReadOnly

Set oExcelApp = CreateObject("Excel.Application")
Set oExcelWB = oExcelApp.Workbooks.Open(sFactoringXLS)

With oExcelWB
    .Application.DisplayAlerts = False
    .Application.Visible = False
    .Activate
    .Application.ActiveCell.Select
    MsgBox .Application.ActiveCell.Address
    .Application.ActiveCell.Offset(1, 2).Value = sContactName
    .Application.ActiveCell.Offset(2, 2).Value = sInvoiceNumber
    .Application.ActiveCell.Offset(3, 2).Value = sPONumber
    .Application.ActiveCell.Offset(4, 2).Value = dInvoiceDate
    .Application.ActiveCell.Offset(5, 2).Value = iNetTerm
    .Application.ActiveCell.Offset(6, 2).Value = sInvoiceAmount
    .SaveAs FileName:=sGeneratedFactoringXLS, FileFormat:=xlExcel8
    .Close
End With

Set oExcelApp = Nothing
rstFactoringCSV.Close

sInvoicePDFPath = "I:\" & sCourtDatesID & "\Generated\" & sInvoiceNumber & ".PDF"
sQuestion = "Click yes after you have created your final invoice at " & sInvoicePDFPath
sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???")

If sAnswer = vbNo Then 'IF NO THEN THIS HAPPENS
    MsgBox "No invoice will be sent to factoring."
Else 'if yes then this happens
    Call pfSendWordDocAsEmail("FactorInvoiceEmail", "Invoice to Factor", sInvoicePDFPath) 'send email and add attachment yourself (from xero)
End If

sFactoringURL = "https://cirrus.factorfox.net/"


Application.FollowHyperlink (sFactoringURL)
Call pfUpdateCheckboxStatus("InvoicetoFactorEmail")

qdf.Close
db.Close
Call pfClearGlobals
End Sub
Sub fInfoNeededEmailF()
'============================================================================
' Name        : fInfoNeededEmailF
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call fInfoNeededEmailF
' Description : creates info needed e-mail
'============================================================================
'TODO: fInfoNeededEmailF not used anymore come back
Call pfCheckFolderExistence 'checks for job folder and creates it if not exists
Call pfSendWordDocAsEmail("InfoNeeded", "Spellings/Information Needed")
Call pfCommunicationHistoryAdd("InfoNeeded") 'save in commhistory

End Sub

Public Sub pfInvoicesCSV()
'============================================================================
' Name        : pfInvoicesCSV
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfInvoicesCSV
' Description : creates CSVs used for invoicing
'============================================================================

Dim sCSVPath As String, sXeroImportURL As String


Call pfCurrentCaseInfo  'refresh transcript info
Call pfGetOrderingAttorneyInfo

sCSVPath = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-" & "-XeroInvoiceCSV" & ".csv"

DoCmd.OpenQuery "XeroCSVQuery", acViewNormal, acAdd
DoCmd.TransferText acExportDelim, , "SelectXero", sCSVPath, True


'real factoring csv plus invoice generated FactoringCSVQuery

If sFactoringApproved = True Then

    DoCmd.OpenQuery "FactoringCSVQuery", acViewNormal, acAdd
    DoCmd.TransferText acExportDelim, , "FactoringCSVQuery", sCSVPath, True
    
Else

    
End If

sXeroImportURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"

Application.FollowHyperlink (sXeroImportURL)

Call pfUpdateCheckboxStatus("InvoiceCompleted")
Call pfClearGlobals
End Sub

Sub fCreateWorkingCopy()
'============================================================================
' Name        : fCreateWorkingCopy
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call fCreateWorkingCopy
' Description : creates "working copy" sent to client
'============================================================================

Dim sWCTranscriptsPath As String, sWCMainPath As String
Dim sTranscriptsFPathDocX As String, sTranscriptsPathDocX As String, sTranscriptsPathNoExt As String
Dim sAnswer As String, sQuestion As String, sCourtCoverPath As String
Dim oWordApp As New Word.Application, oWordDoc As New Word.Document, vbComp As Object
Dim wsSections As Word.Sections, wsSection As Word.Section
Dim x As Variant
Dim oRng As Range

sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]
sWCTranscriptsPath = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Transcript-WorkingCopy.docx"
sTranscriptsFPathDocX = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Transcript.docx"
sTranscriptsPathDocX = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Transcript-FINAL.docx"
sTranscriptsPathNoExt = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Transcript-FINAL"
sWCMainPath = "I:\" & sCourtDatesID & "\Backups\" & sCourtDatesID & "-Transcript-WorkingCopy.docx"

Call pfWordIndexer

sQuestion = "Next we will make a working copy.  Click yes when ready."
sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???")

If sAnswer = vbNo Then 'Code for No
    MsgBox "No working copy will be made."
    
Else 'Code for yes
    sCourtCoverPath = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-CourtCover.docx"
On Error Resume Next
Set oWordApp = GetObject(, "Word.Application")


If Err <> 0 Then
    Set oWordApp = CreateObject("Word.Application")
End If
On Error GoTo 0
oWordApp.Application.DisplayAlerts = False
oWordApp.Application.Visible = False

Set oWordDoc = oWordApp.Documents.Open(sCourtCoverPath)


SendKeys "+{Home}"
    With oWordDoc
    
        'add continuous section break at top
        .Paragraphs(1).Range.InsertBreak Type:=wdSectionBreakContinuous
        
        If .ProtectionType <> wdNoProtection Then .Unprotect password:="wrts0419"
        'removes doc info and macro code within document
        .RemoveDocumentInformation (wdRDIAll)
        For Each vbComp In .VBProject.VBComponents
            With vbComp
                If .Type = 100 Then
                    .CodeModule.DeleteLines 1, .CodeModule.CountOfLines
                Else
                    .VBProject.VBComponents.Remove vbComp
                End If
            End With
        Next vbComp
        SendKeys "+{Home}"
        
        'delete cert section
        Set wsSections = .Sections
        Set oRng = .Range(Start:=.bookmarks("CertBMK").Range.End, End:=.bookmarks("ToABMK").Range.Start)
        oRng.delete
        
        For x = wsSections.Last.Index To 1 Step -1
            Set wsSection = wsSections.item(x)
            If x = 1 Then
                wsSection.ProtectedForForms = True
            Else
                wsSection.ProtectedForForms = False
            End If
            
        Next x
        
        'lock up header, leave all other sections unlocked
        .Protect Type:=wdAllowOnlyFormFields, noReset:=True, password:="wrts0419"
        .SaveAs FileName:=sWCTranscriptsPath, FileFormat:=wdFormatXMLDocument 'save as file
        
    End With
End If

oWordDoc.Close
oWordApp.Quit
Set oWordDoc = Nothing
Set oWordApp = Nothing

FileCopy sWCTranscriptsPath, sWCMainPath

End Sub

Sub fSendShippingTrackingEmail()
'============================================================================
' Name        : fSendShippingTrackingEmail
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call fSendShippingTrackingEmail
' Description : creates shipping confirmation e-mail sent to client
'============================================================================
'TODO: fSendShippingTrackingEmail not used come back
Call pfGenericExportandMailMerge(qnTRCourtUnionAppAddrQ, "Stage4s\Shipped")
Call pfSendWordDocAsEmail("Shipped", "Shipping Confirmation") 'shipped email
Call pfCommunicationHistoryAdd("Shipped")

End Sub


Sub pfPrepareCover()
'============================================================================
' Name        : pfPrepareCover
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call pfPrepareCover
' Description : prepares volume cover for transcript compendium
'============================================================================
Dim cJob As New Job

Dim rstJobsByCase As DAO.Recordset
Dim sCasesID As String, sCurrentJobID As String, sVolumesCoverPath As String
Dim dHearingDate As Date
Dim x As Integer, y As Integer
Dim sOriginalCurrentTranscriptPath As String, sNewCurrentTranscriptPath As String
Dim sVolumeText As String, sBookmarkName As String, sVolumesCoverPDFPath As String
Dim oWordApp As Word.Application, oWordDoc As Word.Document

sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]
'TODO:  pfPrepareCover can delete following lines when known safe
'Dim rstCasesID As DAO.Recordset
'Set rstCasesID = CurrentDb.OpenRecordset("SELECT * FROM Courtdates WHERE ID = " & sCourtDatesID & ";")
'sCasesID = rstCasesID.Fields("CasesID").Value
'rstCasesID.Close

'query for all dates & job numbers for a case
Set rstJobsByCase = CurrentDb.OpenRecordset("SELECT * FROM Courtdates WHERE CasesID = " & cJob.CaseInfo.ID & ";")
x = rstJobsByCase.RecordCount
rstJobsByCase.MoveFirst
y = 1
'loop through each one

Do While rstJobsByCase.EOF = False

    sCurrentJobID = rstJobsByCase.Fields("ID").Value
    dHearingDate = rstJobsByCase.Fields("HearingDate").Value

    'copy other transcript pdfs for same volume into \transcripts\ folder
    sOriginalCurrentTranscriptPath = "I:\" & sCurrentJobID & "\Transcripts\" & sCurrentJobID & "-Transcript-FINAL.pdf"
    sNewCurrentTranscriptPath = "I:\" & sCourtDatesID & "\Transcripts\" & sCurrentJobID & "-Transcript-FINAL.pdf"
    
    If Not sOriginalCurrentTranscriptPath = sNewCurrentTranscriptPath Then
            FileCopy sOriginalCurrentTranscriptPath, sNewCurrentTranscriptPath
    End If
    'list current date on volumes cover
    sVolumesCoverPath = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Cover.docx"
    sVolumeText = "Volume " & y & ":  " & Format(dHearingDate, "dddd, mmmm d, yyyy")
    Debug.Print sVolumeText
    On Error Resume Next
    Set oWordApp = GetObject(, "Word.Application")
    
    If Err <> 0 Then
        Set oWordApp = CreateObject("Word.Application")
    End If
    
    Set oWordDoc = GetObject(sVolumesCoverPath, "Word.Document")
    
    
    Set oWordDoc = oWordApp.Documents.Open(sVolumesCoverPath)
    On Error GoTo 0
    
    oWordDoc.Application.Visible = True
    oWordDoc.Application.DisplayAlerts = False
    
    sBookmarkName = "VolumeBMK0" & y
        
    With oWordDoc
        .bookmarks(sBookmarkName).Select
        .Application.Selection.TypeText Text:=sVolumeText
    End With
        y = y + 1
    rstJobsByCase.MoveNext
    
Loop

oWordDoc.Save

'make volume cover pdf
sVolumesCoverPDFPath = "I:\" & sCourtDatesID & "\Transcripts\" & sCourtDatesID & "-Cover.pdf"
oWordDoc.ExportAsFixedFormat outputFileName:=sVolumesCoverPDFPath, ExportFormat:=wdExportFormatPDF

oWordDoc.Close
'oWordApp.Quit
rstJobsByCase.Close
    
End Sub
