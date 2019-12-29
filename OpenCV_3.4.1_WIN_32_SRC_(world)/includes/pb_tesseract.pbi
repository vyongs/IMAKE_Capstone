CompilerIf #PB_Compiler_Version < 530
  IncludePath "binaries"
CompilerElse
  IncludePath "../binaries"
CompilerEndIf

Enumeration OEM
  #OEM_TESSERACT_ONLY
  #OEM_CUBE_ONLY
  #OEM_TESSERACT_CUBE_COMBINED
  #OEM_DEFAULT
EndEnumeration

Enumeration PageSegMode
  #PSM_OSD_ONLY
  #PSM_AUTO_OSD
  #PSM_AUTO_ONLY
  #PSM_AUTO
  #PSM_SINGLE_COLUMN
  #PSM_SINGLE_BLOCK_VERT_TEXT
  #PSM_SINGLE_BLOCK
  #PSM_SINGLE_LINE
  #PSM_SINGLE_WORD
  #PSM_CIRCLE_WORD
  #PSM_SINGLE_CHAR
  #PSM_SPARSE_TEXT
  #PSM_SPARSE_TEXT_OSD
  #PSM_RAW_LINE
  #PSM_COUNT
EndEnumeration

Enumeration PageIteratorLevel
  #RIL_BLOCK
  #RIL_PARA
  #RIL_TEXTLINE
  #RIL_WORD
  #RIL_SYMBOL
EndEnumeration

#L_INSERT                           = 0
#L_COPY                             = 1
#L_CLONE                            = 2
#L_COPY_CLONE                       = 3

Structure BOX
	x.l
	y.l
	w.l
	h.l
	refcount.l
EndStructure

Structure BOXA
	n.l
	nalloc.l
	refcount.l
	*box.BOX
EndStructure

ImportC "libtesseract302.lib"
  LeptPixDestroy(hPix)
  LeptPixRead(filename.p-ascii)
	LeptPixReadMemPNG(*hMemory, size)
	LeptPixWritePNG(filename.p-ascii, hPix, gamma.f)
	TessBaseAPIClear(*TessBaseAPI)
	TessBaseAPIClearAdaptiveClassifier(*TessBaseAPI)
  TessBaseAPICreate()
  TessBaseAPIDelete(*TessBaseAPI)
  TessBaseAPIEnd(*TessBaseAPI)
  TessBaseAPIGetComponentImages(*TessBaseAPI, TessPageIteratorLevel, text_only, *pixaPtrArray, *blockids)
  TessBaseAPIGetUTF8Text(*TessBaseAPI)
  TessBaseAPIInit1(*TessBaseAPI, datapath.p-ascii, language.p-ascii, OEM, *array_configs, configs_size)
  TessBaseAPIInit2(*TessBaseAPI, datapath.p-ascii, language.p-ascii, OEM)
  TessBaseAPIInit3(*TessBaseAPI, datapath.p-ascii, language.p-ascii)
  TessBaseAPIMeanTextConf.l(*TessBaseAPI)
  TessBaseAPIRecognize(*TessBaseAPI, monitor_class)
  TessBaseAPIRect(handle.l, *imagedata, bytes_per_pixel.l, bytes_per_line.l, left.l, top.l, width.l, height.l)
  TessBaseAPISetImage(*TessBaseAPI, *imagedata, width.l, height.l, bytes_per_pixel.l, bytes_per_line.l)
  TessBaseAPISetPageSegMode(*TessBaseAPI, TessPageSegMode)
  TessBaseAPISetRectangle(*TessBaseAPI, left.l, top.l, width.l, height.l)
EndImport

ImportC "liblept168.lib"
  boxaGetBox(*boxa, index.l, accessflag.l)
EndImport

Procedure.s ToAscii(*str)
	If *str
		string.s = PeekS(*str, #PB_Default, #PB_Unicode)
		result.s = Space(1 + StringByteLength(string, #PB_Unicode) / SizeOf(Character))
		PokeS(@result, string, #PB_Default, #PB_Ascii)
		ProcedureReturn result
	EndIf
EndProcedure

Procedure TesseractInit(PageSegMode, OEM, dictionarypath.s, language.s, tesscfg.s)
  hAPI = TessBaseAPICreate()
  CFG$ = ToAscii(@tesscfg)
  CFG = @CFG$

	If hAPI
	  TessBaseAPISetPageSegMode(hAPI, PageSegMode)

	  If TessBaseAPIInit1(hAPI, dictionarypath, language, OEM, @CFG, 1) : TessBaseAPIEnd(hAPI) : Else : ProcedureReturn hAPI : EndIf

  EndIf
EndProcedure

Procedure.s OpenCVImage2TextOCR(hAPI, *image.IplImage)
  *gray.IplImage = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 1)
  *bin.IplImage = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 1)

  If *image\nChannels = 3 : cvCvtColor(*image, *gray, #CV_BGR2GRAY, 1) : Else : *gray = cvCloneImage(*image) : EndIf

  threshold.d = cvThreshold(*gray, *bin, 10, 255, #CV_THRESH_OTSU)
  TessBaseAPIRect(hAPI, *bin\imageData, 1, *bin\widthStep, 0, 0, *bin\width, *bin\height)

  If Not TessBaseAPIRecognize(hAPI, 0)
    Result.s = RTrim(PeekS(TessBaseAPIGetUTF8Text(hAPI), -1, #PB_UTF8), Chr(10))
    Result = LTrim(Result)
  EndIf
  TessBaseAPIEnd(hAPI)
  cvReleaseImage(@*bin)
  cvReleaseImage(@*gray)
  ProcedureReturn Result
EndProcedure
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 5
; Folding = -
; DisableDebugger
