IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, Dim points.CvPoint3D32f(4), nCount, nComplete, nPrecision, nFlag, nLines

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Bézier Curve: A parametric curve frequently used in computer graphics and related fields." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust the precision." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Add 4 points / Drag points." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle control lines." + #LF$ +
                  "ENTER       " + #TAB$ + ": Clear / Reset the window."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          FileName.s = SaveCVImage()

          If FileName
            params.CvSaveData

            Select LCase(GetExtensionPart(FileName))
              Case "bmp", "dib"
              Case "jpeg", "jpg", "jpe"
                params\paramId = #CV_IMWRITE_JPEG_QUALITY
                params\paramValue = 95
              Case "jp2"
              Case "png"
                params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                params\paramValue = 3
              Case "ppm", "pgm", "pbm"
                params\paramId = #CV_IMWRITE_PXM_BINARY
                params\paramValue = 1
              Case "sr", "ras"
              Case "tiff", "tif"
              Default
                Select SelectedFilePattern()
                  Case 0
                    FileName + ".bmp"
                  Case 1
                    FileName + ".jpg"
                    params\paramId = #CV_IMWRITE_JPEG_QUALITY
                    params\paramValue = 95
                  Case 2
                    FileName + ".jp2"
                  Case 3
                    FileName + ".png"
                    params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                    params\paramValue = 3
                  Case 4
                    FileName + ".ppm"
                    params\paramId = #CV_IMWRITE_PXM_BINARY
                    params\paramValue = 1
                  Case 5
                    FileName + ".sr"
                  Case 6
                    FileName + ".tiff"
                EndSelect
            EndSelect
            cvSaveImage(FileName, *save, @params)
          EndIf
        Case 10
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure PointAdd(*p.CvPoint3D32f, *q.CvPoint3D32f)
  *point.CvPoint3D32f = AllocateMemory(SizeOf(CvPoint3D32f))
  PokeF(@*point\x, PeekF(@*p\x) + PeekF(@*q\x))
  PokeF(@*point\y, PeekF(@*p\y) + PeekF(@*q\y))
  PokeF(@*point\z, PeekF(@*p\z) + PeekF(@*q\z))
  ProcedureReturn *point
EndProcedure

Procedure PointTimes(c.f, x.f, y.f, z.f)
  *point.CvPoint3D32f = AllocateMemory(SizeOf(CvPoint3D32f))
  PokeF(@*point\x, x * c)
  PokeF(@*point\y, y * c)
  PokeF(@*point\z, z * c)
  ProcedureReturn *point
EndProcedure

Procedure Bernstein(u.f, Array p.CvPoint3D32f(1))
  *a.CvPoint3D32f = PointTimes(Pow(u, 3), p(0)\x, p(0)\y, p(0)\z)
  *b.CvPoint3D32f = PointTimes(3 * Pow(u, 2) * (1 - u), p(1)\x, p(1)\y, p(1)\z)
  *c.CvPoint3D32f = PointTimes(3 * u * Pow(1 - u, 2), p(2)\x, p(2)\y, p(2)\z)
  *d.CvPoint3D32f = PointTimes(Pow(1 - u, 3), p(3)\x, p(3)\y, p(3)\z)
  ProcedureReturn PointAdd(PointAdd(*a, *b), PointAdd(*c, *d))
EndProcedure

Procedure DrawControlLine(*image.IplImage, Array p.CvPoint3D32f(1))
  Dim pc.CvPoint(4)

  For rtnCount = 0 To 4 - 1
    pc(rtnCount)\x = p(rtnCount)\x
    pc(rtnCount)\y = p(rtnCount)\y
  Next

  If nLines
    cvLine(*image, pc(0)\x, pc(0)\y, pc(1)\x, pc(1)\y, 255, 0, 0, 0, 1, #CV_AA, #Null)
    cvLine(*image, pc(2)\x, pc(2)\y, pc(3)\x, pc(3)\y, 255, 0, 0, 0, 1, #CV_AA, #Null)
  EndIf
EndProcedure

Procedure DrawBezier(*image.IplImage, Array points.CvPoint3D32f(1))
  *ptNew.CvPoint3D32f = AllocateMemory(SizeOf(CvPoint3D32f))
  ptPrevious.CvPoint
  ptCurrent.CvPoint
  ptPrevious\x = points(0)\x
  ptPrevious\y = points(0)\y

  For rtnCount = 0 To (nPrecision * 50) + 5
    u.f = rtnCount / (nPrecision * 50 + 5)
    *ptNew = Bernstein(u, points())
    ptCurrent\x = PeekF(@*ptNew\x)
    ptCurrent\y = PeekF(@*ptNew\y)

    If rtnCount > 0 : cvLine(*image, ptCurrent\x, ptCurrent\y, ptPrevious\x, ptPrevious\y, 0, 255, 230, 0, 1, #CV_AA, #Null) : EndIf

    ptPrevious = ptCurrent
  Next
  DrawControlLine(*image, points())
EndProcedure

Procedure InRectangle(pX, pY, tlX, tlY, brX, brY)
 If pX >= tlX And pX <= brX And pY >= tlY And pY <= brY : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select #True
    Case Bool(event = #CV_EVENT_RBUTTONDOWN)
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case Bool(event = #CV_EVENT_LBUTTONDOWN And nComplete = 0)
      nCount + 1

      If nCount <= 4
        points(nCount - 1)\x = x
        points(nCount - 1)\y = y
        cvRectangle(*param\Pointer1, x - 5, y - 5, x + 5, y + 5, 0, 255, 0, 0, 1, #CV_AA, #Null)
      EndIf

      If nCount = 4
        Dim reorder.CvPoint3D32f(4)
        reorder(0) = points(0)
        reorder(1) = points(2)
        reorder(2) = points(3)
        reorder(3) = points(1)
        points(0) = reorder(0)
        points(1) = reorder(1)
        points(2) = reorder(2)
        points(3) = reorder(3)
        DrawBezier(*param\Pointer1, points())
        nComplete = 1
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
    Case Bool(event = #CV_EVENT_LBUTTONDOWN And nComplete = 1)
      nFlag = -1

      For rtnCount = 0 To 4 - 1
        If InRectangle(x, y, points(rtnCount)\x - 5, points(rtnCount)\y - 5, points(rtnCount)\x + 5, points(rtnCount)\y + 5)
          nFlag = rtnCount
          Break
        EndIf
      Next
    Case Bool(event = #CV_EVENT_MOUSEMOVE And nComplete = 1 And nFlag <> -1)
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        points(nFlag)\x = x
        points(nFlag)\y = y
        cvSetZero(*param\Pointer1)

        For rtnCount = 0 To 4 - 1
          cvRectangle(*param\Pointer1, points(rtnCount)\x - 5, points(rtnCount)\y - 5, points(rtnCount)\x + 5, points(rtnCount)\y + 5, 0, 255, 0, 0, 1, #CV_AA, #Null)
        Next
        DrawBezier(*param\Pointer1, points())
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
      EndIf
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  nPrecision = pos
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
*window_name = cvGetWindowName(window_handle)
lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
  MenuItem(1, "Save")
  MenuBar()
  MenuItem(10, "Exit")
EndIf
hWnd = GetParent_(window_handle)
iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
*image.IplImage = cvCreateImage(800, 600, #IPL_DEPTH_8U, 3) : cvSetZero(*image)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
nPrecision = 1 : nFlag = -1 : nLines = 1
cvCreateTrackbar("Precision", #CV_WINDOW_NAME, @nPrecision, 1, @CvTrackbarCallback())
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)

    Select keyPressed
      Case 13
        cvSetTrackbarPos("Precision", #CV_WINDOW_NAME, 1)
        cvSetZero(*image)
        Dim points.CvPoint3D32f(4)
        nCount = 0
        nComplete = 0
        nPrecision = 1
        nFlag = -1
        nLines = 1
      Case 32
        nLines ! #True
        keybd_event_(#VK_Z, 0, 0, 0)
      Case 90, 122
        If nComplete = 1
          cvSetZero(*image)

          For rtnCount = 0 To 4 - 1
            cvRectangle(*param\Pointer1, points(rtnCount)\x - 5, points(rtnCount)\y - 5, points(rtnCount)\x + 5, points(rtnCount)\y + 5, 0, 255, 0, 0, 1, #CV_AA, #Null)
          Next
          DrawBezier(*image, points())
        EndIf
    EndSelect
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.71 LTS (Windows - x86)
; CursorPosition = 1
; Folding = --
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\