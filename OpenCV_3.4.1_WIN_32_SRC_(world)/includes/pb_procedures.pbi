Procedure.s OpenCVImage(Images = #True, Position = 0)
  If Images
    Folder.s = "images\"
  Else
    Folder = Space(#MAX_PATH)
    SHGetFolderPath_(#Null, #CSIDL_MYPICTURES, 0, 0, Folder)
    PathAddBackslash_(Folder)
  EndIf
  Pattern.s = "All Images (*.*)|*.bmp;*.dib;*.jpeg;*.jpg;*.jpe;*.jp2;*.png;*.pbm;*.pgm;*.ppm;*.sr;*.ras;*.tiff;*.tif" +
              "|Windows Bitmaps (*.bmp;*.dib)|*.bmp;*.dib|JPEG Files (*.jpeg;*.jpg;*.jpe)|*.jpeg;*.jpg;*.jpe|JPEG 2000 Files (*.jp2)|*.jp2" +
              "|Portable Network Graphics (*.png)|*.png|Portable Image Format (*.pbm;*.pgm;*.ppm)|*.pbm;*.pgm;*.ppm" +
              "|Sun Rasters (*.sr;*.ras)|*.sr;*.ras|TIFF Files (*.tiff;*.tif)|*.tiff;*.tif"
  ProcedureReturn OpenFileRequester("Choose an image file", Folder, Pattern, Position)
EndProcedure

Procedure.s SaveCVImage(DeskTop = #True, Position = 1)
  Folder.s = Space(#MAX_PATH)

  If DeskTop : SHGetFolderPath_(#Null, #CSIDL_DESKTOPDIRECTORY, 0, 0, Folder) : Else : SHGetFolderPath_(#Null, #CSIDL_MYPICTURES, 0, 0, Folder) : EndIf

  PathAddBackslash_(Folder)
  Pattern.s = "Windows Bitmaps (*.bmp;*.dib)|*.bmp;*.dib|JPEG Files (*.jpeg;*.jpg;*.jpe)|*.jpeg;*.jpg;*.jpe|JPEG 2000 Files (*.jp2)|*.jp2" +
              "|Portable Network Graphics (*.png)|*.png|Portable Image Format (*.pbm;*.pgm;*.ppm)|*.pbm;*.pgm;*.ppm" +
              "|Sun Rasters (*.sr;*.ras)|*.sr;*.ras|TIFF Files (*.tiff;*.tif)|*.tiff;*.tif"
  ProcedureReturn SaveFileRequester("Enter a file name", Folder, Pattern, Position)
EndProcedure

Procedure GetDBImage(dbName.s)
  If OpenDatabase(0, "database/opencv.sqlite", #Null$, #Null$)
    If DatabaseQuery(0, "SELECT * FROM images WHERE name = '" + dbName + "';")
      If FirstDatabaseRow(0)
        imageSize = DatabaseColumnSize(0, 1)
        *buffer = AllocateMemory(imageSize)

        If *buffer
          GetDatabaseBlob(0, 1, *buffer, imageSize)
          pbimage = CatchImage(#PB_Any, *buffer, imageSize)
          FreeMemory(*buffer)

          If pbimage
            *buffer = EncodeImage(pbimage, #PB_ImagePlugin_JPEG)
            *mat.CvMat = cvCreateMatHeader(ImageHeight(pbimage), ImageWidth(pbimage), CV_MAKETYPE(#CV_32F, 1))
            cvSetData(*mat, *buffer, #CV_AUTOSTEP)
            *image.IplImage = cvDecodeImage(*mat, #CV_LOAD_IMAGE_COLOR)
            FreeMemory(*buffer)
            FreeImage(pbimage)
          EndIf
        EndIf
      EndIf
      FinishDatabaseQuery(0)
    EndIf
    CloseDatabase(0)
  EndIf
  ProcedureReturn *image
EndProcedure

Procedure.s GetDBName(nMethod = 0, dbName.s = #Null$)
  If OpenDatabase(0, "database/opencv.sqlite", #Null$, #Null$)
    If nMethod = 1 : ls_order.s = " DESC" : EndIf

    If DatabaseQuery(0, "SELECT * FROM images ORDER BY name" + ls_order + ";")
      If FirstDatabaseRow(0)
        Select nMethod
          Case 0
            dbName = GetDatabaseString(0, 0)
          Case 1, 2
            Repeat
              If GetDatabaseString(0, 0) = dbName
                If NextDatabaseRow(0) : dbName = GetDatabaseString(0, 0) : EndIf : Break
              EndIf
            Until Not NextDatabaseRow(0)
        EndSelect
      EndIf
      FinishDatabaseQuery(0)
    EndIf
    CloseDatabase(0)
  EndIf
  ProcedureReturn dbName
EndProcedure

Procedure.s ImportImage(*image.IplImage, name.s, extension.s = ".jpg")
  If FileSize("database/opencv.sqlite") = -1
    If FileSize("database") <> -2 : CreateDirectory("database") : EndIf
    If CreateFile(0, "database/opencv.sqlite") : CloseFile(0) : EndIf
  EndIf

  If OpenDatabase(0, "database/opencv.sqlite", #Null$, #Null$)
    DatabaseUpdate(0, "CREATE TABLE images (name VARCHAR(255), image BLOB);")
    params.CvSaveData

    Select LCase(extension)
      Case ".png"
        params\paramId = #CV_IMWRITE_PNG_COMPRESSION
        params\paramValue = 3
      Case ".ppm"
        params\paramId = #CV_IMWRITE_PXM_BINARY
        params\paramValue = 1
      Default
        params\paramId = #CV_IMWRITE_JPEG_QUALITY
        params\paramValue = 95
    EndSelect
    *mat.CvMat = cvEncodeImage(extension, *image, @params)
    pbimage = CatchImage(#PB_Any, *mat\ptr)

    If IsImage(pbimage)
      Select LCase(extension)
        Case ".jpg"
          *buffer = EncodeImage(pbimage, #PB_ImagePlugin_JPEG)
        Case ".png"
          *buffer = EncodeImage(pbimage, #PB_ImagePlugin_PNG)
        Case ".ppm"
          *buffer = EncodeImage(pbimage)
      EndSelect
      LocalTime.SYSTEMTIME
      GetLocalTime_(LocalTime)
      dateTime.s = Right("0" + Str(LocalTime\wMonth), 2) + "_" + Right("0" + Str(LocalTime\wDay), 2) + "_" + Str(LocalTime\wYear) + "_" + Right("0" + Str(LocalTime\wHour), 2) + "_" + Right("0" + Str(LocalTime\wMinute), 2) + "_" + Right("0" + Str(LocalTime\wSecond), 2) + "_" + Right("00" + Str(LocalTime\wMilliseconds), 3)
      name + "_" + dateTime + extension
      length = MemorySize(*buffer)
      SetDatabaseBlob(0, 0, *buffer, length)
      DatabaseUpdate(0, "INSERT INTO images (name, image) VALUES ('" + name + "', ?);")
      FreeImage(pbimage)
    EndIf
    CloseDatabase(0)
  EndIf
  ProcedureReturn name
EndProcedure

Procedure OpenCV2PBImage(*frame.IplImage, pbImage, nWidth, nHeight, nDepth = 24)
  *image.Pointer

  If nDepth = 32 : nByte = 1 : EndIf

  Select *frame\nChannels
    Case 1
      If StartDrawing(ImageOutput(pbImage))
        imageData = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        For y = 0 To nHeight - 1
          *image = imageData + widthStep * (nHeight - 1 - y)

          For x = 0 To nWidth - 1
            nGray = PeekA(@*frame\imageData\b + y * *frame\widthStep + x)
            *image\b = nGray : *image + 1
            *image\b = nGray : *image + 1
            *image\b = nGray : *image + 1 + nByte
          Next
        Next
        StopDrawing()
      EndIf
    Case 3
      If StartDrawing(ImageOutput(pbImage))
        imageData = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        For y = 0 To nHeight - 1
          *image = imageData + widthStep * (nHeight - 1 - y)

          For x = 0 To nWidth - 1
            nB = PeekA(@*frame\imageData\b + y * *frame\widthStep + x * 3 + 0)
            nG = PeekA(@*frame\imageData\b + y * *frame\widthStep + x * 3 + 1)
            nR = PeekA(@*frame\imageData\b + y * *frame\widthStep + x * 3 + 2)
            *image\b = nB : *image + 1
            *image\b = nG : *image + 1
            *image\b = nR : *image + 1 + nByte
          Next
        Next
        StopDrawing()
      EndIf
  EndSelect
EndProcedure

Procedure OpenCV2PBImage24_ASM(*frame.IplImage, pbImage, nWidth, nHeight)
  Select *frame\nChannels
    Case 1
      If StartDrawing(ImageOutput(pbImage))
        *src = *frame\imageData + *frame\widthStep * (*frame\height - 1)
        *dst = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        While nHeight
          !mov eax, [p.p_src]
          !mov edx, [p.p_dst]
          !mov ecx, [p.v_nWidth]
          !push ebx
          !.8uc1_l0:
          !movzx ebx, byte [eax]
          !mov [edx], bl
          !mov [edx + 1], bl
          !mov [edx + 2], bl
          !add eax, 1
          !add edx, 3
          !sub ecx, 1
          !jnz .8uc1_l0
          !pop ebx
          *src - *frame\widthStep
          *dst + widthStep
          nHeight - 1
        Wend          
        StopDrawing()
      EndIf
    Case 3
      If StartDrawing(ImageOutput(pbImage))
        *src = *frame\imageData + *frame\widthStep * (*frame\height - 1)
        *dst = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        While nHeight
          !mov eax, [p.p_src]
          !mov edx, [p.p_dst]
          !mov ecx, [p.v_nWidth]
          !push ebx
          !imul ecx, 3
          !test ecx, 1
          !jz .8uc3_l0
          !sub ecx, 1
          !movzx ebx, byte [eax + ecx]
          !mov [edx + ecx], bl
          !.8uc3_l0:
          !test ecx, 2
          !jz .8uc3_l2
          !sub ecx, 2
          !movzx ebx, word [eax + ecx]
          !mov [edx + ecx], bx
          !jmp .8uc3_l2
          !.8uc3_l1:
          !mov ebx, [eax + ecx]
          !mov [edx + ecx], ebx
          !.8uc3_l2:
          !sub ecx, 4
          !jnc .8uc3_l1
          !pop ebx          
          *src - *frame\widthStep
          *dst + widthStep
          nHeight - 1
        Wend
        StopDrawing()
      EndIf
  EndSelect
EndProcedure

Procedure OpenCV2PBImage32_ASM(*frame.IplImage, pbImage, nWidth, nHeight)
  Select *frame\nChannels
    Case 1
      If StartDrawing(ImageOutput(pbImage))
        *src = *frame\imageData + *frame\widthStep * (*frame\height - 1)
        *dst = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        While nHeight
          !mov eax, [p.p_src]
          !mov edx, [p.p_dst]
          !mov ecx, [p.v_nWidth]
          !push ebx
          !.8uc1_l0:
          !movzx ebx, byte [eax]
          !imul ebx, 0x010101
          !or ebx, 0xff000000
          !mov [edx], ebx
          !add eax, 1
          !add edx, 4
          !sub ecx, 1
          !jnz .8uc1_l0
          !pop ebx
          *src - *frame\widthStep
          *dst + widthStep
          nHeight - 1
        Wend          
        StopDrawing()
      EndIf
    Case 3
      If StartDrawing(ImageOutput(pbImage))
        *src = *frame\imageData + *frame\widthStep * (*frame\height - 1)
        *dst = DrawingBuffer()
        widthStep = DrawingBufferPitch()

        While nHeight
          !mov eax, [p.p_src]
          !mov edx, [p.p_dst]
          !mov ecx, [p.v_nWidth]
          !push ebx
          !movzx ebx, byte [eax + 2]
          !shl ebx, 16
          !mov bx, [eax]
          !jmp .8uc3_l1
          !.8uc3_l0:
          !mov ebx, [eax - 1]
          !shr ebx, 8
          !.8uc3_l1:
          !or ebx, 0xff000000
          !mov [edx], ebx
          !add eax, 3
          !add edx, 4
          !sub ecx, 1
          !jnz .8uc3_l0
          !pop ebx          
          *src - *frame\widthStep
          *dst + widthStep
          nHeight - 1
        Wend
        StopDrawing()
      EndIf
  EndSelect
EndProcedure

#DPI_AWARENESS_CONTEXT                      = 0
#DPI_AWARENESS_CONTEXT_UNAWARE              = #DPI_AWARENESS_CONTEXT - 1
#DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         = #DPI_AWARENESS_CONTEXT - 2
#DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    = #DPI_AWARENESS_CONTEXT - 3
#DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = #DPI_AWARENESS_CONTEXT - 4

Select #True
  Case Bool(OSVersion() >= #PB_OS_Windows_10)
    Prototype protoSetProcessDpiAwarenessContext(value)
    Global SetProcessDpiAwarenessContext.protoSetProcessDpiAwarenessContext
EndSelect

Procedure FixWindowUnresponsive()
  Protected Message.MSG

  If PeekMessage_(@Message, #Null, 0, 0, #PM_REMOVE)
    TranslateMessage_(@Message)
    DispatchMessage_(@Message)
  EndIf
EndProcedure

Procedure BringWindowToTop(hWnd)
  ForeThread = GetWindowThreadProcessId_(GetForegroundWindow_(), #Null)
  AppThread = GetCurrentThreadId_()

  If ForeThread <> AppThread
    AttachThreadInput_(ForeThread, AppThread, #True)
    BringWindowToTop_(hWnd)
    ShowWindow_(hWnd, #SW_SHOW)
    AttachThreadInput_(ForeThread, AppThread, #False)
  Else
    BringWindowToTop_(hWnd)
    ShowWindow_(hWnd, #SW_SHOW)
  EndIf
EndProcedure

Procedure ToolTip(hWnd, Msg.s)
  hToolTip = CreateWindowEx_(#WS_EX_TOPMOST, #TOOLTIPS_CLASS, #Null, #TTS_BALLOON | #TTS_NOPREFIX, 0, 0, 0, 0, hWnd, #Null, GetModuleHandle_(#Null), #Null)
  ti.TOOLINFO\cbSize = SizeOf(TOOLINFO)
  ti\uFlags = #TTF_IDISHWND | #TTF_SUBCLASS
  ti\uId = hWnd
  ti\lpszText = @Msg
  SendMessage_(hToolTip, #TTM_SETMAXTIPWIDTH, 0, 405)
  SendMessage_(hToolTip, #TTM_SETDELAYTIME, #TTDT_AUTOPOP, 15000)
  SendMessage_(hToolTip, #TTM_SETDELAYTIME, #TTDT_INITIAL, 5000)
  SendMessage_(hToolTip, #TTM_SETDELAYTIME, #TTDT_RESHOW, -1)
  SendMessage_(hToolTip, #TTM_ADDTOOL, 0, ti)
EndProcedure

Procedure.s GetFOURCC(fourcc)
  ProcedureReturn UCase(Chr(fourcc & $FF)) + UCase(Chr((fourcc & $FF00) >> 8)) + UCase(Chr((fourcc & $FF0000) >> 16)) + UCase(Chr((fourcc & $FF000000) >> 24))
EndProcedure

Procedure.q UnsignedLong(value)
  Define Result.q

  If value < 0 : Result = value + 4294967295 + 1 : Else : Result = value : EndIf

  ProcedureReturn Result
EndProcedure

Procedure.q cvRNG(seed.q)
  Global rng.q

  If seed < -1 : seed + 9223372036854775807 + 1 : EndIf
  If seed : rng = seed : Else : rng = -1 : EndIf

  ProcedureReturn rng
EndProcedure

Procedure cvRandInt(temp.q)
  If temp < 0 : temp + 9223372036854775807 + 1 : EndIf

  temp * #CV_RNG_COEFF + (temp >> 32)

  If temp < 0 : temp + 9223372036854775807 + 1 : EndIf

  rng = temp
  ProcedureReturn temp
EndProcedure

Procedure.d cvRandReal(rng.q)
  ProcedureReturn cvRandInt(rng) * Pow(2, -32)
EndProcedure

Procedure cvScalar(val0.d, val1.d = 0, val2.d = 0, val3.d = 0)
  *scalar.CvScalar = AllocateMemory(SizeOf(CvScalar))
  *scalar\val[0] = val0
  *scalar\val[1] = val1
  *scalar\val[2] = val2
  *scalar\val[3] = val3
  ProcedureReturn *scalar
EndProcedure

Procedure cvRealScalar(val0.d)
  *scalar.CvScalar = AllocateMemory(SizeOf(CvScalar))
  *scalar\Val[0] = val0
  *scalar\Val[1] = 0
  *scalar\Val[2] = 0
  *scalar\Val[3] = 0
  ProcedureReturn *scalar
EndProcedure

Procedure cvScalarAll(val0123.d)
  *scalar.CvScalar = AllocateMemory(SizeOf(CvScalar))
  *scalar\val[0] = val0123
  *scalar\val[1] = val0123
  *scalar\val[2] = val0123
  *scalar\val[3] = val0123
  ProcedureReturn *scalar
EndProcedure

Procedure cvMat(rows, cols, type, *data)
  *m.CvMat = AllocateMemory(SizeOf(CvMat))

  If CV_MAT_DEPTH(type) <= #CV_64F
    type = CV_MAT_TYPE(type)
    *m\type = #CV_MAT_MAGIC_VAL | #CV_MAT_CONT_FLAG | type
    *m\cols = cols
    *m\rows = rows
    *m\Step = *m\cols * CV_ELEM_SIZE(type)
    *m\ptr = *data
    *m\refcount = #Null
    *m\hdr_refcount = 0
    ProcedureReturn *m
  EndIf
EndProcedure

Procedure.d cvmGet(*mat.CvMat, row, col)
  If row < *mat\rows And col < *mat\cols
    type = CV_MAT_TYPE(*mat\type)

    If type = CV_MAKETYPE(#CV_32F, 1)
      ProcedureReturn PeekF(@*mat\fl\f + row * *mat\Step + col * 4)
    Else
      If type = CV_MAKETYPE(#CV_64F, 1) : ProcedureReturn PeekD(@*mat\db\d + row * *mat\Step + col * 8) : EndIf
    EndIf
  EndIf
EndProcedure

Procedure cvmSet(*mat.CvMat, row, col, value.d)
  If row < *mat\rows And col < *mat\cols
    type = CV_MAT_TYPE(*mat\type)

    If type = CV_MAKETYPE(#CV_32F, 1)
      PokeF(@*mat\fl\f + row * *mat\Step + col * 4, value)
    Else
      If type = CV_MAKETYPE(#CV_64F, 1) : PokeD(@*mat\db\d + row * *mat\Step + col * 8, value) : EndIf
    EndIf
  EndIf
EndProcedure

Procedure cvFloor(value.d)
  i = Round(value, #PB_Round_Nearest)
  diff.f = value - i
  ProcedureReturn i - Bool(diff < 0)
EndProcedure

Procedure cvCeil(value.d)
  i = Round(value, #PB_Round_Nearest)
  diff.f = i - value
  ProcedureReturn i + Bool(diff < 0)
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 14
; Folding = -----
; DisableDebugger