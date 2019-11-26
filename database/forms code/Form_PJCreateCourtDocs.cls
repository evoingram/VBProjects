VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_PJCreateCourtDocs"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Public Sub cmdStage1Paperwork_Click()
Call pfStage1Ppwk
End Sub
Private Sub cmdStage2Paperwork_Click()
Call pfStage2Ppwk
End Sub
Private Sub cmdStage3Paperwork_Click()
Call pfStage3Ppwk
End Sub

Private Sub cmdStage4Paperwork_Click()
Call pfStage4Ppwk
End Sub
Private Sub cmdViewPaperworkHistory_Click()
    DoCmd.OpenForm FormName:="PJViewDocHistory"
End Sub

Private Sub Command68_Click()
'============================================================================
' Name        : Command68_Click
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call Command68_Click
' Description : generates document specified from combo box selection
'============================================================================

'need other docs in list:
    'paypal invoice
    'word index
    'pp-draft
    '

Dim sCourtCoverPath As String, sAnswer As String, sQuestion As String
Dim qdf As QueryDef
Dim rstTRCUnionAA As DAO.Recordset


Call pfCurrentCaseInfo  'refresh transcript info

sLinkToCSV = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-" & "-XeroInvoiceCSV" & ".csv"

If Me.cmbListAllDocuments = "Stage 1:  Deposit Received paperwork" Then
    
    Call fDepositPaymentReceived
ElseIf Me.cmbListAllDocuments = "Stage 1:  Order Confirmation" Then

    Call pfGenericExportandMailMerge("Case", "Stage1s\OrderConfirmation")
    Call pfSendWordDocAsEmail("OrderConfirmation", "Transcript Order Confirmation") 'Order Confrmation Email

    
ElseIf Me.cmbListAllDocuments = "Stage 1:  Cover Page" Then
    
    Call pfSelectCoverTemplate 'Cover Page
    Call pfUpdateCheckboxStatus("CoverPage")

ElseIf Me.cmbListAllDocuments = "Stage 1:  Create Tasks" Then
    
    Call pfGenerateJobTasks
    Call pfUpdateCheckboxStatus("Schedule")
    
ElseIf Me.cmbListAllDocuments = "Stage 1:  CD Label" Then

    'Call pfCreateCDLabel
    Call pfUpdateCheckboxStatus("CDLabel")
    
ElseIf Me.cmbListAllDocuments = "Stage 1:  package-enclosed letter" Then

    'Call fCreatePELLetter
    Call pfUpdateCheckboxStatus("PackageEnclosedLetter")
    
ElseIf Me.cmbListAllDocuments = "Stage 1:  transcripts-ready email" Then

    Call fTranscriptDeliveryF
    Call pfUpdateCheckboxStatus("TranscriptsReady")
    
ElseIf Me.cmbListAllDocuments = "Stage 1:  Price Quote/Deposit Invoice" Then

    'export xero csv
    DoCmd.OpenQuery "XeroCSVQuery", acViewNormal, acAdd
    
    DoCmd.TransferText acExportDelim, , "SelectXero", sLinkToCSV, True
    'DoCmd.Close ("XeroCSVQuery")
    
    'open xero website
    svURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"
    Application.FollowHyperlink (svURL)
    Call fIsFactoringApproved
    Call pfUpdateCheckboxStatus("InvoiceCompleted")
  
ElseIf Me.cmbListAllDocuments = "Stage 1:  KCI Invoice" Then
  
    Call fAcrobatKCIInvoice
    
    
ElseIf Me.cmbListAllDocuments = "Stage 2:  Type rough draft" Then

    Call pfRoughDraftToCoverF
    
ElseIf Me.cmbListAllDocuments = "Stage 3:  Find/replace" Then

    Call pfTypeRoughDraftF
    Call pfUpdateCheckboxStatus("AddRDtoCover")
    
ElseIf Me.cmbListAllDocuments = "Stage 3:  Audio proof" Then

    sCourtCoverPath = "I:\" & sCourtDatesID & "\Generated\" & sCourtDatesID & "-CourtCover.docx"
    Application.FollowHyperlink sCourtCoverPath

ElseIf Me.cmbListAllDocuments = "Stage 3:  Volumes Cover" Then
    
    Call pfCreateCover("Stage3s\TR-AllCover.dotm")  'cover for all volumes in one pdf
    Call pfPrepareCover
    
ElseIf Me.cmbListAllDocuments = "Stage 4:  Shipping XMLs" Then

    DoCmd.OpenForm FormName:="FShippingOptions"
    Call pfUpdateCheckboxStatus("ShippingXMLs")
    
ElseIf Me.cmbListAllDocuments = "Stage 4:  Xero invoice CSV" Then

    'export xero csv
    DoCmd.OpenQuery "XeroCSVQuery", acViewNormal, acAdd
    'DoCmd.TransferText acExportDelim, , "XeroInvoiceQuery1Select", sLinkToCSV, True
    DoCmd.TransferText acExportDelim, , "SelectXero", sLinkToCSV, True

    'open xero website
    svURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"
    Application.FollowHyperlink (svURL)
    Call pfUpdateCheckboxStatus("InvoiceCompleted")
    
ElseIf Me.cmbListAllDocuments = "Stage 4:  PayPal invoice CSV" Then

    sLinkToCSV = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-PayPalInvoiceCSV" & ".csv"
    
    'real factoring csv plus invoice generated FactoringCSVQuery
    'paypal csv PayPalDepositInvoiceCSVQ & PayPalFactoringInvoiceCSVQ
    
        
    Call pfGetOrderingAttorneyInfo
    
    If sFactoringApproved = True Then
    
        DoCmd.OpenQuery "FactoringCSVQuery", acViewNormal, acAdd
        DoCmd.TransferText acExportDelim, , "FactoringCSVQuery", sLinkToCSV, True
        DoCmd.Close ("FactoringCSVQuery")
        DoCmd.OpenQuery "PayPalFactoringInvoiceCSVQ", acViewNormal, acAdd
        DoCmd.TransferText acExportDelim, , "PayPalFactoringInvoiceCSVQ", sLinkToCSV, True
        DoCmd.Close ("PayPalFactoringInvoiceCSVQ")
        
    Else
    
        DoCmd.OpenQuery "PayPalDepositInvoiceCSVQ", acViewNormal, acAdd
        DoCmd.TransferText acExportDelim, , "PayPalDepositInvoiceCSVQ", sLinkToCSV, True
        DoCmd.Close ("PayPalDepositInvoiceCSVQ")
        
    End If
    
    qdf.Close
    rstTRCUnionAA.Close
    Set qdf = Nothing
    Set rstTRCUnionAA = Nothing
    
    svURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"
    Application.FollowHyperlink (svURL)
    Call pfUpdateCheckboxStatus("InvoiceCompleted")

ElseIf Me.cmbListAllDocuments = "Stage 4:  Factoring invoice CSV" Then

    'factor email prompt
    'need to add other real factoring csv plus invoice generated
    sQuestion = "Do you want to factor this invoice?"
    sAnswer = MsgBox(sQuestion, vbQuestion + vbYesNo, "???")
    
    If sAnswer = vbNo Then 'Code for No
    
        MsgBox "This job will not be sent to factoring."
        
    Else 'Code for yes
    
        Call fFactorInvoicEmailF
        Call pfUpdateCheckboxStatus("InvoicetoFactorEmail")
        
        sCourtDatesID = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![JobNumberField]
        sLinkToCSV = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-" & "-XeroInvoiceCSV" & ".csv"
        DoCmd.OpenQuery "XeroCSVQuery", acViewNormal, acAdd
        DoCmd.TransferText acExportDelim, , "SelectXero", sLinkToCSV, True
        DoCmd.Close ("XeroCSVQuery")
        
        'TR-Court-Union-AppAddr
        'real factoring csv plus invoice generated FactoringCSVQuery
        'paypal csv PayPalDepositInvoiceCSVQ & PayPalFactoringInvoiceCSVQ
        
        Set qdf = CurrentDb.QueryDefs("TR-Court-Union-AppAddr")
        qdf.Parameters(0) = sCourtDatesID
        Set rstTRCUnionAA = qdf.OpenRecordset()
        sFactoringApproved = rstTRCUnionAA.Fields("FactoringApproved")
        
        If sFactoringApproved = True Then
        
            DoCmd.OpenQuery "FactoringCSVQuery", acViewNormal, acAdd
            DoCmd.TransferText acExportDelim, , "FactoringCSVQuery", sLinkToCSV, True
            DoCmd.Close ("FactoringCSVQuery")
            DoCmd.OpenQuery "PayPalFactoringInvoiceCSVQ", acViewNormal, acAdd
            DoCmd.TransferText acExportDelim, , "PayPalFactoringInvoiceCSVQ", sLinkToCSV, True
            DoCmd.Close ("PayPalFactoringInvoiceCSVQ")
            
        Else
        
            DoCmd.OpenQuery "PayPalDepositInvoiceCSVQ", acViewNormal, acAdd
            DoCmd.TransferText acExportDelim, , "PayPalDepositInvoiceCSVQ", sLinkToCSV, True
            DoCmd.Close ("PayPalDepositInvoiceCSVQ")
            
        End If
    
        qdf.Close
        rstTRCUnionAA.Close
        Set qdf = Nothing
        Set rstTRCUnionAA = Nothing
                
        svURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"
        Application.FollowHyperlink (svURL)
        Call pfUpdateCheckboxStatus("InvoiceCompleted")
        
    End If
    
ElseIf Me.cmbListAllDocuments = "Stage 4:  Invoice / Balance Due" Then

    Call fSendPPEmailFactored
    Call pfSendWordDocAsEmail("CIDFinalIncomeReport", "Final Income Notification") 'final income report 'emails adam cid report
        
    'export xero csv
    DoCmd.OpenQuery "XeroCSVQuery", acViewNormal, acAdd
        
    sLinkToCSV = "I:\" & sCourtDatesID & "\WorkingFiles\" & sCourtDatesID & "-" & "-XeroInvoiceCSV" & ".csv"
    DoCmd.TransferText acExportDelim, , "SelectXero", sLinkToCSV, True
    'DoCmd.Close ("XeroCSVQuery")
    
    'open xero website
    svURL = "https://go.xero.com/Import/Import.aspx?type=IMPORTTYPE/ARINVOICES"
    Application.FollowHyperlink (svURL)
    Call pfUpdateCheckboxStatus("InvoiceCompleted")
    
Else
End If
Call pfClearGlobals
End Sub