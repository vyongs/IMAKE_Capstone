IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, nShow

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Morph one face into another using data derived from lists created using Delaunay triangulation." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Restart morph process." + #LF$ + #LF$ +
                  "[ W ] KEY   " + #TAB$ + ": Toggle Warp Affine."

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

Procedure ReadPoints(FileName.s, Array pt.CvPoint2D32f(1))
  If ReadFile(0, FileName)
    While Not Eof(0)
      xyDimension.s = ReadString(0)

      For rtnCount = 1 To 2
        nPosition.f = ValF(StringField(xyDimension, rtnCount, " "))

        Select rtnCount
          Case 1 : pt(arrSize)\x = nPosition
          Case 2 : pt(arrSize)\y = nPosition
        EndSelect
      Next
      arrSize + 1 : ReDim pt.CvPoint2D32f(arrSize)
    Wend
    CloseFile(0)
  EndIf
EndProcedure

Procedure ApplyAffineTransform(Array srcPoint.CvPoint2D32f(1), Array dstPoint.CvPoint2D32f(1), *warp.CvMat, *source.IplImage)
  cvGetAffineTransform(@srcPoint(), @dstPoint(), *warp)
  cvWarpAffine(*source, *source, *warp, #CV_INTER_LINEAR, 0, 0, 0, 0)
EndProcedure

Procedure MorphTriangle(Array triangle.CvPoint3D32f(2), Array triangle1.CvPoint3D32f(2), Array triangle2.CvPoint3D32f(2), *image1.IplImage, *image2.IplImage, *morph.IplImage, nAlpha.d)
  Dim tri.CvPoint(2) : Dim tri1.CvPoint(2) : Dim tri2.CvPoint(2)
  rect.CvRect : rect1.CvRect : rect2.CvRect
  #CV_SEQ_ELTYPE_POINT = CV_MAKETYPE(#CV_32S, 2)
  *storage.CvMemStorage = cvCreateMemStorage(0) : cvClearMemStorage(*storage)
  *triangle.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
  tri(0)\x = triangle(0, 0)\x
  tri(0)\y = triangle(0, 1)\x
  cvSeqPush(*triangle, @tri(0))
  tri(1)\x = triangle(0, 0)\y
  tri(1)\y = triangle(0, 1)\y
  cvSeqPush(*triangle, @tri(1))
  tri(2)\x = triangle(0, 0)\z
  tri(2)\y = triangle(0, 1)\z
  cvSeqPush(*triangle, @tri(2))
  cvBoundingRect(@rect, *triangle, 0)
  cvClearMemStorage(*storage)
  *triangle1.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
  tri1(0)\x = triangle1(0, 0)\x
  tri1(0)\y = triangle1(0, 1)\x
  cvSeqPush(*triangle1, @tri1(0))
  tri1(1)\x = triangle1(0, 0)\y
  tri1(1)\y = triangle1(0, 1)\y
  cvSeqPush(*triangle1, @tri1(1))
  tri1(2)\x = triangle1(0, 0)\z
  tri1(2)\y = triangle1(0, 1)\z
  cvSeqPush(*triangle1, @tri1(2))
  cvBoundingRect(@rect1, *triangle1, 0)
  cvClearMemStorage(*storage)
  *triangle2.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
  tri2(0)\x = triangle2(0, 0)\x
  tri2(0)\y = triangle2(0, 1)\x
  cvSeqPush(*triangle2, @tri2(0))
  tri2(1)\x = triangle2(0, 0)\y
  tri2(1)\y = triangle2(0, 1)\y
  cvSeqPush(*triangle2, @tri2(1))
  tri2(2)\x = triangle2(0, 0)\z
  tri2(2)\y = triangle2(0, 1)\z
  cvSeqPush(*triangle2, @tri2(2))
  cvBoundingRect(@rect2, *triangle2, 0)
  cvReleaseMemStorage(@*storage)
  Dim trect.CvPoint2D32f(2) : Dim trectInt.CvPoint(2)
  Dim t1rect.CvPoint2D32f(2) : Dim t2rect.CvPoint2D32f(2)

  For rtnCount = 0 To 3 - 1
    trect(rtnCount)\x = tri(rtnCount)\x - rect\x : trect(rtnCount)\y = tri(rtnCount)\y - rect\y
    trectInt(rtnCount)\x = tri(rtnCount)\x - rect\x : trectInt(rtnCount)\y = tri(rtnCount)\y - rect\y
    t1rect(rtnCount)\x = tri1(rtnCount)\x - rect1\x : t1rect(rtnCount)\y = tri1(rtnCount)\y - rect1\y
    t2rect(rtnCount)\x = tri2(rtnCount)\x - rect2\x : t2rect(rtnCount)\y = tri2(rtnCount)\y - rect2\y
  Next
  *warp1.CvMat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*warp1)
  *img1Rect.IplImage = cvCreateImage(rect1\width, rect1\height, #IPL_DEPTH_32F, 3)
  cvSetImageROI(*image1, rect1\x, rect1\y, rect1\width, rect1\height)
  cvCopy(*image1, *img1Rect, #Null)
  cvResetImageROI(*image1)
  *warp2.CvMat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*warp2)
  *img2Rect.IplImage = cvCreateImage(rect2\width, rect2\height, #IPL_DEPTH_32F, 3)
  cvSetImageROI(*image2, rect2\x, rect2\y, rect2\width, rect2\height)
  cvCopy(*image2, *img2Rect, #Null)
  cvResetImageROI(*image2)

  If nShow
    ApplyAffineTransform(t1rect(), trect(), *warp1, *img1Rect)
    ApplyAffineTransform(t2rect(), trect(), *warp2, *img2Rect)
  EndIf
  *img1Temp.IplImage = cvCreateImage(rect\width, rect\height, #IPL_DEPTH_32F, 3)
  *img2Temp.IplImage = cvCreateImage(rect\width, rect\height, #IPL_DEPTH_32F, 3)
  cvResize(*img1Rect, *img1Temp, #CV_INTER_LINEAR)
  cvResize(*img2Rect, *img2Temp, #CV_INTER_LINEAR)
  *imgRect.IplImage = cvCreateImage(rect\width, rect\height, #IPL_DEPTH_32F, 3)
  cvAddWeighted(*img1Temp, 1 - nAlpha, *img2Temp, nAlpha, 0, *imgRect)
  cvReleaseImage(@*img2Temp)
  cvReleaseImage(@*img1Temp)
  *mask.CvMat = cvCreateMat(rect\height, rect\width, CV_MAKETYPE(#CV_32F, 3)) : cvSetZero(*mask)
  cvFillConvexPoly(*mask, trectInt(), 3, 1, 1, 1, 0, #CV_AA, #Null)
  cvMul(*imgRect, *mask, *imgRect, 1)
  cvSubRS(*mask, 1, 1, 1, 0, *mask, #Null)
  cvSetImageROI(*morph, rect\x, rect\y, rect\width, rect\height)
  cvMul(*morph, *mask, *morph, 1)
  cvAdd(*morph, *imgRect, *morph, #Null)
  cvResetImageROI(*morph)
  cvReleaseImage(@*imgRect)
  cvReleaseMat(@*mask)
  cvReleaseImage(@*img2Rect)
  cvReleaseMat(@*warp2)
  cvReleaseImage(@*img1Rect)
  cvReleaseMat(@*warp1)
  FreeArray(t2rect()) : FreeArray(t1rect()) : FreeArray(trectInt()) : FreeArray(trect())
  FreeArray(tri2()) : FreeArray(tri1()) : FreeArray(tri())
EndProcedure

Procedure AnimateMorph(nStage, *image1.IplImage, *image2.IplImage, *morph.IplImage, nAlpha.d)
  Dim points1.CvPoint2D32f(0) : Dim points2.CvPoint2D32f(0) : Dim points3.CvPoint2D32f(0)

  Select nStage
    Case 1
      ReadPoints("trained/delaunay1.txt", points1())
      ReadPoints("trained/delaunay2.txt", points2())
    Case 2
      ReadPoints("trained/delaunay2.txt", points1())
      ReadPoints("trained/delaunay3.txt", points2())
    Case 3
      ReadPoints("trained/delaunay3.txt", points1())
      ReadPoints("trained/delaunay2.txt", points2())
    Case 4
      ReadPoints("trained/delaunay2.txt", points1())
      ReadPoints("trained/delaunay1.txt", points2())
  EndSelect
  nArray = ArraySize(points1())
  Dim points.CvPoint2D32f(nArray)

  For rtnCount = 0 To nArray - 1
    points(rtnCount)\x = (1 - nAlpha) * points1(rtnCount)\x + nAlpha * points2(rtnCount)\x
    points(rtnCount)\y = (1 - nAlpha) * points1(rtnCount)\y + nAlpha * points2(rtnCount)\y
  Next
  Dim triangle.CvPoint3D32f(0, 1) : Dim triangle1.CvPoint3D32f(0, 1) : Dim triangle2.CvPoint3D32f(0, 1)

  If ReadFile(0, "trained/triangle.txt") And ArraySize(points()) > 0
    While Not Eof(0)
      xyzDimension.s = ReadString(0)

      For rtnCount = 1 To 3
        nPosition = Val(StringField(xyzDimension, rtnCount, " "))

        Select rtnCount
          Case 1
            triangle(0, 0)\x = points(nPosition)\x : triangle(0, 1)\x = points(nPosition)\y
            triangle1(0, 0)\x = points1(nPosition)\x : triangle1(0, 1)\x = points1(nPosition)\y
            triangle2(0, 0)\x = points2(nPosition)\x : triangle2(0, 1)\x = points2(nPosition)\y
          Case 2
            triangle(0, 0)\y = points(nPosition)\x : triangle(0, 1)\y = points(nPosition)\y
            triangle1(0, 0)\y = points1(nPosition)\x : triangle1(0, 1)\y = points1(nPosition)\y
            triangle2(0, 0)\y = points2(nPosition)\x : triangle2(0, 1)\y = points2(nPosition)\y
          Case 3
            triangle(0, 0)\z = points(nPosition)\x : triangle(0, 1)\z = points(nPosition)\y
            triangle1(0, 0)\z = points1(nPosition)\x : triangle1(0, 1)\z = points1(nPosition)\y
            triangle2(0, 0)\z = points2(nPosition)\x : triangle2(0, 1)\z = points2(nPosition)\y
        EndSelect
      Next
      MorphTriangle(triangle(), triangle1(), triangle2(), *image1, *image2, *morph, nAlpha)
    Wend
    CloseFile(0)
  EndIf
  FreeArray(triangle2()) : FreeArray(triangle1()) : FreeArray(triangle())
  FreeArray(points3()) : FreeArray(points2()) : FreeArray(points1()) : FreeArray(points())
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
*temp1.IplImage = cvLoadImage("images/delaunay1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
*temp2.IplImage = cvLoadImage("images/delaunay2.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
*temp3.IplImage = cvLoadImage("images/delaunay3.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
*image1.IplImage = cvCreateImage(*temp1\width, *temp1\height, #IPL_DEPTH_32F, 3)
*image2.IplImage = cvCreateImage(*temp2\width, *temp2\height, #IPL_DEPTH_32F, 3)
*image3.IplImage = cvCreateImage(*temp3\width, *temp3\height, #IPL_DEPTH_32F, 3)
cvConvertScale(*temp1, *image1, 1 / 255, 0)
cvConvertScale(*temp2, *image2, 1 / 255, 0)
cvConvertScale(*temp3, *image3, 1 / 255, 0)
cvReleaseImage(@*temp3)
cvReleaseImage(@*temp2)
cvReleaseImage(@*temp1)
*morph.IplImage = cvCreateImage(*image1\width, *image1\height, #IPL_DEPTH_32F, 3)
*morph8.IplImage = cvCreateImage(*image1\width, *image1\height, #IPL_DEPTH_8U, 3)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)
cvShowImage(#CV_WINDOW_NAME, *image1) : cvWaitKey(200)

Repeat
  If SkipMorph = #False
    If keyPressed <> 27 And exitCV = #False
      For rtnCount = 1 To 9
        AnimateMorph(1, *image1, *image2, *morph, rtnCount * 0.11 + 0.01)
        cvConvertScale(*morph, *morph8, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *morph8)
        keyPressed = cvWaitKey(60)
        *param\Pointer1 = *morph8

        Select #True
          Case Bool(keyPressed = 27), exitCV
            Break 2
          Case Bool(keyPressed = 87), Bool(keyPressed = 119)
            nShow ! #True
        EndSelect
      Next
    EndIf

    If keyPressed <> 27 And exitCV = #False
      For rtnCount = 1 To 9
        AnimateMorph(2, *image2, *image3, *morph, rtnCount * 0.11 + 0.01)
        cvConvertScale(*morph, *morph8, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *morph8)
        keyPressed = cvWaitKey(60)
        *param\Pointer1 = *morph8

        Select #True
          Case Bool(keyPressed = 27), exitCV
            Break 2
          Case Bool(keyPressed = 87), Bool(keyPressed = 119)
            nShow ! #True
        EndSelect
      Next
    EndIf

    If keyPressed <> 27 And exitCV = #False
      For rtnCount = 1 To 9
        AnimateMorph(3, *image3, *image2, *morph, rtnCount * 0.11 + 0.01)
        cvShowImage(#CV_WINDOW_NAME, *morph8)
        cvConvertScale(*morph, *morph8, 255, 0)
        keyPressed = cvWaitKey(60)
        *param\Pointer1 = *morph8

        Select #True
          Case Bool(keyPressed = 27), exitCV
            Break 2
          Case Bool(keyPressed = 87), Bool(keyPressed = 119)
            nShow ! #True
        EndSelect
      Next
    EndIf

    If keyPressed <> 27 And exitCV = #False
      For rtnCount = 1 To 9
        AnimateMorph(4, *image2, *image1, *morph, rtnCount * 0.11 + 0.01)
        cvConvertScale(*morph, *morph8, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *morph8)
        keyPressed = cvWaitKey(60)
        *param\Pointer1 = *morph8

        Select #True
          Case Bool(keyPressed = 27), exitCV
            Break 2
          Case Bool(keyPressed = 87), Bool(keyPressed = 119)
            nShow ! #True
        EndSelect
      Next
    EndIf
  EndIf
  SkipMorph = #True
  keyPressed = cvWaitKey(0)

  Select keyPressed
    Case 32
      SkipMorph = #False
    Case 87, 119
      nShow ! #True
      SkipMorph = #False
  EndSelect
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*morph8)
cvReleaseImage(@*morph)
cvReleaseImage(@*image3)
cvReleaseImage(@*image2)
cvReleaseImage(@*image1)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\