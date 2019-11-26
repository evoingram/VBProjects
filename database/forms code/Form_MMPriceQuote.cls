VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_MMPriceQuote"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub btnPriceQuote_Click()
'============================================================================
' Name        : btnPriceQuote_Click
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call btnPriceQuote_Click
' Description : get a price quote for a customer with audio length + deadline or turnaround
'============================================================================

Dim iAudioLength As Integer
Dim vWorkTimeAvailable As Integer, sPageRate As String
Dim dDeadline As Date, dDateDiff As Date
Dim sPriceQuote As String

iAudioLength = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![txtAudioLength].Value

dDeadline = Forms![NewMainMenu]![ProcessJobSubformNMM].Form![txtDeadline].Value
dDateDiff = DateDiff("d", Now, dDeadline)

If iAudioLength > 865 Then
    If dDateDiff > 29 Then
        sPageRate = "2.65"
    ElseIf dDateDiff < 30 And dDateDiff > 13 Then
        sPageRate = "3.25"
    ElseIf dDateDiff < 14 And dDateDiff > 6 Then
        sPageRate = "3.75"
    ElseIf dDateDiff < 7 Then
        sPageRate = "4.25"
    Else
    End If
Else
    If dDateDiff > 29 Then
        sPageRate = "3.00"
    ElseIf dDateDiff < 30 And dDateDiff > 13 Then
        sPageRate = "3.50"
    ElseIf dDateDiff < 14 And dDateDiff > 6 Then
        sPageRate = "4.00"
    ElseIf dDateDiff < 7 And dDateDiff > 2 Then
        sPageRate = "4.75"
    ElseIf dDateDiff < 3 Then
        sPageRate = "5.25"
    Else
    End If
End If
sPriceQuote = (((iAudioLength / 60) * 45) * sPageRate)
If sPriceQuote < 50 Then
    sPriceQuote = 50
End If
Me.txtAvailabilityYN.ControlSource = "=" & Chr(34) & "$" & sPriceQuote & Chr(34)
End Sub


Private Sub Command39_Click()
'============================================================================
' Name        : Command39_Click
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call Command39_Click
' Description : generates and displays the actual price quote email sent to client
'============================================================================


Call pfPriceQuoteEmail
End Sub

Private Sub btnCheckAvailability_Click()
'============================================================================
' Name        : btnCheckAvailability_Click
' Author      : Erica L Ingram
' Copyright   : 2019, A Quo Co.
' Call command: Call btnCheckAvailability_Click
' Description : compares calendar against current tasks length sum to see if i'm available to complete work within a certain deadline
'============================================================================

Dim iTimeLength As Integer, iAudioLength As Integer, iCalcJobLength As Integer
Dim iWorkTimeAvail As Integer, iAvailTimePreDeadline As Integer
Dim dDeadline As Date, dDateDifference As Date
Dim qdf As QueryDef
Dim rstTasksB4DdlnQ As DAO.Recordset

iTimeLength = 0
iAudioLength = Forms![NewMainMenu]![ProcessJobSubformNMM]![SearchJobsSubform].Form![txtAudioLength].Value
dDeadline = Forms![NewMainMenu]![ProcessJobSubformNMM]![SearchJobsSubform].Form![txtDeadline].Value
iCalcJobLength = (55 + (iAudioLength * 3) + (iAudioLength * 1.5))
dDateDifference = DateDiff("d", Now, dDeadline)
iWorkTimeAvail = 600 * dDateDifference

Set qdf = CurrentDb.QueryDefs("TasksBeforeDeadlineQuery")
qdf.Parameters(0) = dDeadline
Set rstTasksB4DdlnQ = qdf.OpenRecordset()

If Not (rstTasksB4DdlnQ.EOF And rstTasksB4DdlnQ.BOF) Then  'For each CourtDates.ID

    rstTasksB4DdlnQ.MoveFirst
    
    Do Until rstTasksB4DdlnQ.EOF = True
        iTimeLength = iTimeLength + rstTasksB4DdlnQ.Fields("TimeLength").Value
        rstTasksB4DdlnQ.MoveNext
    Loop
    
Else
End If

'when complete
iAvailTimePreDeadline = iWorkTimeAvail - iCalcJobLength - iTimeLength
If iAvailTimePreDeadline >= -30 Then

    Me.txtAvailabilityYN.ControlSource = "=""Yes"""
    
ElseIf iAvailTimePreDeadline < -30 Then

    Me.txtAvailabilityYN.ControlSource = "=""No"""
    
Else
End If
End Sub
