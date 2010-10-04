'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Basic VB API demo for Harvest. Use this sample as a starting point on how to
' connect, authenticate, and send requests to the Harvest API.
' To execute this sample, save this file to your computer, replace the user 
' credentials below, re-save and run the following command from a Windows command 
' prompt:
'
'   cscript harvest_api_sample.vbs
'
' You will then see the XML list of projects output in a MessageBox.
'
' The full HARVEST API documentation can be found at:
'
'   http://getharvest.com/api
'
' Please review the documentation before sending in your questions. 
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' 1. Replace these with the information for your account.
reportUrl = "http://subdomain.harvestapp.com/projects.xml"
user = "your@email.com"
pass = "yourpass"

Set httpReq = CreateObject("MSXML2.ServerXMLHTTP.6.0")
httpReq.open "GET", reportUrl, False

' 2. Set up the HTTP headers so Harvest will interpret this as an API request.
httpReq.setRequestHeader "Content-Type", "application/xml"
httpReq.setRequestHeader "Accept", "application/xml"
httpReq.setRequestHeader "Authorization", "Basic " + Base64Encode(user + ":" + pass)

httpReq.send

' 3. Display the result.
MsgBox httpReq.responseText








'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' The below is taken from Patrick Cuff's post on
'  http://stackoverflow.com/questions/496751/base64-encode-string-in-vbscript.
' It is used to base64-encode the Basic Authentication user/pass string.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function Base64Encode(sText)
    Dim oXML, oNode
    Set oXML = CreateObject("Msxml2.DOMDocument.3.0")
    Set oNode = oXML.CreateElement("base64")
    oNode.dataType = "bin.base64"
    oNode.nodeTypedValue =Stream_StringToBinary(sText)
    Base64Encode = oNode.text
    Set oNode = Nothing
    Set oXML = Nothing
End Function


'Stream_StringToBinary Function
'2003 Antonin Foller, http://www.motobit.com
'Text - string parameter To convert To binary data
Function Stream_StringToBinary(Text)
  Const adTypeText = 2
  Const adTypeBinary = 1

  'Create Stream object
  Dim BinaryStream 'As New Stream
  Set BinaryStream = CreateObject("ADODB.Stream")

  'Specify stream type - we want To save text/string data.
  BinaryStream.Type = adTypeText

  'Specify charset For the source text (unicode) data.
  BinaryStream.CharSet = "us-ascii"

  'Open the stream And write text/string data To the object
  BinaryStream.Open
  BinaryStream.WriteText Text

  'Change stream type To binary
  BinaryStream.Position = 0
  BinaryStream.Type = adTypeBinary

  'Ignore first two bytes - sign of
  BinaryStream.Position = 0

  'Open the stream And get binary data from the object
  Stream_StringToBinary = BinaryStream.Read

  Set BinaryStream = Nothing
End Function

'Stream_BinaryToString Function
'2003 Antonin Foller, http://www.motobit.com
'Binary - VT_UI1 | VT_ARRAY data To convert To a string 
Function Stream_BinaryToString(Binary)
  Const adTypeText = 2
  Const adTypeBinary = 1

  'Create Stream object
  Dim BinaryStream 'As New Stream
  Set BinaryStream = CreateObject("ADODB.Stream")

  'Specify stream type - we want To save text/string data.
  BinaryStream.Type = adTypeBinary

  'Open the stream And write text/string data To the object
  BinaryStream.Open
  BinaryStream.Write Binary

  'Change stream type To binary
  BinaryStream.Position = 0
  BinaryStream.Type = adTypeText

  'Specify charset For the source text (unicode) data.
  BinaryStream.CharSet = "us-ascii"

  'Open the stream And get binary data from the object
  Stream_BinaryToString = BinaryStream.ReadText
  Set BinaryStream = Nothing
End Function


