IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Creates a sequence of points, bounding them in a rectangle of the minimal area."

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

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
  EndSelect
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
*image.IplImage = cvCreateImage(600, 400, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvSetZero(*image)
#CV_SEQ_ELTYPE_POINT = CV_MAKETYPE(#CV_32S, 2)
*storage.CvMemStorage = cvCreateMemStorage(0)
cvClearMemStorage(*storage)
*sequence.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
element.CvPoint

For y = 120 To 270 Step 25
  For x = 70 To 190 Step 25
    offset + 10
    element\x = x + offset
    element\y = y
    cvSeqPush(*sequence, @element)
    cvCircle(*image, element\x, element\y, 2, 100, x - 150, y, 0, 3, #CV_AA, #Null)
  Next
Next
box.CvBox2D
cvMinAreaRect2(@box, *sequence, #Null)
Dim pt1.CvPoint2D32f(4)
Dim pt2.CvPoint(4)
cvBoxPoints(box\center\x, box\center\y, box\size\width, box\size\height, box\angle, pt1())
pt2(0)\x = pt1(0)\x
pt2(0)\y = pt1(0)\y
pt2(1)\x = pt1(1)\x
pt2(1)\y = pt1(1)\y
pt2(2)\x = pt1(2)\x
pt2(2)\y = pt1(2)\y
pt2(3)\x = pt1(3)\x
pt2(3)\y = pt1(3)\y
cvLine(*image, pt2(0)\x, pt2(0)\y, pt2(1)\x, pt2(1)\y, 0, 255, 255, 0, 1, #CV_AA, #Null)
cvLine(*image, pt2(1)\x, pt2(1)\y, pt2(2)\x, pt2(2)\y, 0, 255, 255, 0, 1, #CV_AA, #Null)
cvLine(*image, pt2(2)\x, pt2(2)\y, pt2(3)\x, pt2(3)\y, 0, 255, 255, 0, 1, #CV_AA, #Null)
cvLine(*image, pt2(3)\x, pt2(3)\y, pt2(0)\x, pt2(0)\y, 0, 255, 255, 0, 1, #CV_AA, #Null)
angle.d = 90 - box\angle
font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)
cvPutText(*image, Str(angle) + " Degrees", 20, 360, @font, 255, 200, 100, 0)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMemStorage(@*storage)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\