IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, Dim srcPoints.CvPoint2D32f(0), Dim dstPoints.CvPoint2D32f(0), nStartPoint

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Moving Least Squares (MLS) image deformation; includes two transformation functions: Rigid and Similarity." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust grid size." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Set points / Deform image." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle original image." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset image / settings." + #LF$ + #LF$ +
                  "[ A ] KEY   " + #TAB$ + ": Toggle anchor points." + #LF$ +
                  "[ D ] KEY   " + #TAB$ + ": Delete selected point." + #LF$ +
                  "[ G ] KEY   " + #TAB$ + ": Toggle grid lines." + #LF$ +
                  "[ L ] KEY   " + #TAB$ + ": Load points files." + #LF$ +
                  "[ P ] KEY   " + #TAB$ + ": Toggle points." + #LF$ +
                  "[ R ] KEY   " + #TAB$ + ": Run deformed animation." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Save points files." + #LF$ +
                  "[ T ] KEY   " + #TAB$ + ": Switch transformation." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          openCV = #True
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
        Case 2
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
  Static srcPoint.CvPoint2D32f, dstPoint.CvPoint2D32f
  Define.CvPoint2D32f tmpSrcPoint, tmpDstPoint

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      srcPoint\x = -1 : srcPoint\y = -1
      dstPoint\x = -1 : dstPoint\y = -1
      arrSize = ArraySize(srcPoints())

      For k = nStartPoint To arrSize - 1
        Select #True
          Case Bool(Abs(x - dstPoints(k)\x) < 15 And Abs(y - dstPoints(k)\y) < 15)
            dstPoint\x = x : dstPoint\y = y : arrPoint = k : Break
          Case Bool(Abs(x - srcPoints(k)\x) < 15 And Abs(y - srcPoints(k)\y) < 15)
            srcPoint\x = x : srcPoint\y = y : arrPoint = k : Break
        EndSelect
      Next

      Select #True
        Case Bool(srcPoint\x > -1 And srcPoint\y > -1), Bool(dstPoint\x > -1 And dstPoint\y > -1)
          tmpSrcPoint\x = srcPoints(arrSize - 1)\x : tmpSrcPoint\y = srcPoints(arrSize - 1)\y
          tmpDstPoint\x = dstPoints(arrSize - 1)\x : tmpDstPoint\y = dstPoints(arrSize - 1)\y
          srcPoints(arrSize - 1)\x = srcPoints(arrPoint)\x : srcPoints(arrSize - 1)\y = srcPoints(arrPoint)\y
          dstPoints(arrSize - 1)\x = dstPoints(arrPoint)\x : dstPoints(arrSize - 1)\y = dstPoints(arrPoint)\y
          srcPoints(arrPoint)\x = tmpSrcPoint\x : srcPoints(arrPoint)\y = tmpSrcPoint\y
          dstPoints(arrPoint)\x = tmpDstPoint\x : dstPoints(arrPoint)\y = tmpDstPoint\y
        Default
          ReDim srcPoints(arrSize + 1) : ReDim dstPoints(arrSize + 1)
          srcPoints(arrSize)\x = x : srcPoints(arrSize)\y = y
          dstPoints(arrSize)\x = x : dstPoints(arrSize)\y = y
      EndSelect
      keybd_event_(#VK_V, 0, 0, 0)
    Case #CV_EVENT_LBUTTONUP
      arrSize = ArraySize(srcPoints())

      If Abs(srcPoints(arrSize - 1)\x - dstPoints(arrSize - 1)\x) < 15 And Abs(srcPoints(arrSize - 1)\y - dstPoints(arrSize - 1)\y) < 15
        Select #True
          Case Bool(srcPoint\x > -1 And srcPoint\y > -1)
            srcPoints(arrSize - 1)\x = dstPoints(arrSize - 1)\x : srcPoints(arrSize - 1)\y = dstPoints(arrSize - 1)\y
            srcPoint\x = -1 : srcPoint\y = -1
          Default
            dstPoints(arrSize - 1)\x = srcPoints(arrSize - 1)\x : dstPoints(arrSize - 1)\y = srcPoints(arrSize - 1)\y
            dstPoint\x = -1 : dstPoint\y = -1
        EndSelect
        keybd_event_(#VK_W, 0, 0, 0)
      EndIf
    Case #CV_EVENT_MOUSEMOVE
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        arrSize = ArraySize(srcPoints())

        If arrSize
          Select #True
            Case Bool(srcPoint\x > -1 And srcPoint\y > -1)
              srcPoints(arrSize - 1)\x = x : srcPoints(arrSize - 1)\y = y
              keybd_event_(#VK_X, 0, 0, 0)
            Default
              dstPoints(arrSize - 1)\x = x : dstPoints(arrSize - 1)\y = y
              keybd_event_(#VK_Y, 0, 0, 0)
          EndSelect
        EndIf
      EndIf
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://vision.gel.ulaval.ca/~jflalonde/cours/4105/h14/tps/results/project/jingweicao/index.html")
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

Procedure.f BilinearInterpolation(x.f, y.f, v11.f, v12.f, v21.f, v22.f)
  ProcedureReturn (v11 * (1 - y) + v12 * y) * (1 - x) + (v21 * (1 - y) + v22 * y) * x
EndProcedure

Procedure GenerateImage(*original.IplImage, *mls.IplImage, Array rDx.f(2), Array rDy.f(2), nGridSize, nDeformRatio.f = 1)
  Define.f deltaX, deltaY, nx, ny, BI

  srcW = *mls\width : srcH = *mls\height
  tarW = *mls\width : tarH = *mls\height

  Repeat
    Repeat
      nj = j + nGridSize : ni = i + nGridSize
      w = nGridSize : h = nGridSize

      If nj >= tarW : nj = tarW - 1 : w = nj - j + 1 : EndIf
      If ni >= tarH : ni = tarH - 1 : h = ni - i + 1 : EndIf

      For di = 0 To h - 1
        For dj = 0 To w - 1
          deltaX = BilinearInterpolation(di / h, dj / w, rDx(i, j), rDx(i, nj), rDx(ni, j), rDx(ni, nj))
          deltaY = BilinearInterpolation(di / h, dj / w, rDy(i, j), rDy(i, nj), rDy(ni, j), rDy(ni, nj))
          nx = j + dj + deltaX * nDeformRatio
          ny = i + di + deltaY * nDeformRatio

          If nx < 0 : nx = 0 : EndIf
          If ny < 0 : ny = 0 : EndIf
          If nx > srcW - 1 : nx = srcW - 1 : EndIf
          If ny > srcH - 1 : ny = srcH - 1 : EndIf

          nxi = Int(nx) : nyi = Int(ny)
          nxi1 = Round(nx, #PB_Round_Up)
          nyi1 = Round(ny, #PB_Round_Up)

          If *original\nChannels = 1
            nValue1 = PeekA(@*original\imageData\b + nyi * *original\widthStep + nxi)
            nValue2 = PeekA(@*original\imageData\b + nyi * *original\widthStep + nxi1)
            nValue3 = PeekA(@*original\imageData\b + nyi1 * *original\widthStep + nxi)
            nValue4 = PeekA(@*original\imageData\b + nyi1 * *original\widthStep + nxi1)
            BI = BilinearInterpolation(ny - nyi, nx - nxi, nValue1, nValue2, nValue3, nValue4)
            PokeA(@*mls\imageData\b + (i + di) * *mls\widthStep + (j + dj), BI)
          Else
            For k = 0 To 3 - 1
              nValue1 = PeekA(@*original\imageData\b + nyi * *original\widthStep + nxi * 3 + k)
              nValue2 = PeekA(@*original\imageData\b + nyi * *original\widthStep + nxi1 * 3 + k)
              nValue3 = PeekA(@*original\imageData\b + nyi1 * *original\widthStep + nxi * 3 + k)
              nValue4 = PeekA(@*original\imageData\b + nyi1 * *original\widthStep + nxi1 * 3 + k)
              BI = BilinearInterpolation(ny - nyi, nx - nxi, nValue1, nValue2, nValue3, nValue4)
              PokeA(@*mls\imageData\b + (i + di) * *mls\widthStep + (j + dj) * 3 + k, BI)
            Next
          EndIf
        Next
      Next
      j + nGridSize
    Until j >= tarW - 1
    i + nGridSize : j = 0
  Until i >= tarH - 1
EndProcedure

Procedure.f CalculateArea(Array xyPoints.CvPoint2D32f(1))
  Define.CvPoint2D32f lt, rb

  lt\x = 1e10 : lt\y = 1e10
  rb\x = -1e10 : rb\y = -1e10

  For k = 0 To ArraySize(xyPoints()) - 1
    If xyPoints(k)\x < lt\x : lt\x = xyPoints(k)\x : EndIf
    If xyPoints(k)\x > rb\x : rb\x = xyPoints(k)\x : EndIf
    If xyPoints(k)\y < lt\y : lt\y = xyPoints(k)\y : EndIf
    If xyPoints(k)\y > rb\y : rb\y = xyPoints(k)\y : EndIf
  Next
  ProcedureReturn (rb\x - lt\x) * (rb\y - lt\y)
EndProcedure

Procedure TransformRigid(Array srcPoints.CvPoint2D32f(1), Array dstPoints.CvPoint2D32f(1), Array rDx.f(2), Array rDy.f(2), nGridSize, preScale = #False, nAlpha.f = 1)
  Define.f ratio, sw, s1, s2, miuR
  Define.CvPoint2D32f swp, swq, pstar, qstar, Pi, PiJ, Qi, curV, curVJ, tmpP, newP

  tarH = ArraySize(rDx()) : tarW = ArraySize(rDx(), 2)
  Dim rDx(tarH, tarW) : Dim rDy(tarH, tarW)
  nPoint = ArraySize(srcPoints())

  If nPoint > 1
    If preScale
      ratio = Sqr(CalculateArea(srcPoints()) / CalculateArea(dstPoints()))

      For k = 0 To nPoint - 1
        srcPoints(k)\x * 1 / ratio : srcPoints(k)\y * 1 / ratio
      Next
    EndIf
    Dim w.f(nPoint)

    Repeat
      If i >= tarW And i < tarW + nGridSize - 1 : i = tarW - 1 : ElseIf i >= tarW : Break : EndIf

      Repeat
        If j >= tarH And j < tarH + nGridSize - 1 : j = tarH - 1 : ElseIf j >= tarH : j = 0 : Break : EndIf

        sw = 0
        swp\x = 0 : swp\y = 0
        swq\x = 0 : swq\y = 0
        curV\x = i : curV\y = j
        newP\x = 0 : newP\y = 0

        For k = 0 To nPoint - 1
          If i = dstPoints(k)\x And j = dstPoints(k)\y : Break : EndIf

          If nAlpha = 1
            w(k) = 1 / ((i - dstPoints(k)\x) * (i - dstPoints(k)\x) + (j - dstPoints(k)\y) * (j - dstPoints(k)\y))
          Else
            w(k) = Pow((i - dstPoints(k)\x) * (i - dstPoints(k)\x) + (j - dstPoints(k)\y) * (j - dstPoints(k)\y), -nAlpha)
          EndIf
          sw + w(k)
          swp\x + w(k) * dstPoints(k)\x : swp\y + w(k) * dstPoints(k)\y
          swq\x + w(k) * srcPoints(k)\x : swq\y + w(k) * srcPoints(k)\y
        Next

        If k = nPoint
          pstar\x = 1 / sw * swp\x : pstar\y = 1 / sw * swp\y
          qstar\x = 1 / sw * swq\x : qstar\y = 1 / sw * swq\y
          s1 = 0 : s2 = 0

          For k = 0 To nPoint - 1
            If i = dstPoints(k)\x And j = dstPoints(k)\y : Continue : EndIf

            Pi\x = dstPoints(k)\x - pstar\x : Pi\y = dstPoints(k)\y - pstar\y
            PiJ\x = -Pi\y : PiJ\y = Pi\x
            Qi\x = srcPoints(k)\x - qstar\x : Qi\y = srcPoints(k)\y - qstar\y
            s1 + w(k) * (Qi\x * Pi\x + Qi\y * Pi\y)
            s2 + w(k) * (Qi\x * PiJ\x + Qi\y * PiJ\y)
          Next
          miuR = Sqr(s1 * s1 + s2 * s2)
          curV\x - pstar\x : curV\y - pstar\y
          curVJ\x = -curV\y : curVJ\y = curV\x

          For k = 0 To nPoint - 1
            If i = dstPoints(k)\x And j = dstPoints(k)\y : Continue : EndIf

            Pi\x = dstPoints(k)\x - pstar\x : Pi\y = dstPoints(k)\y - pstar\y
            PiJ\x = -Pi\y : PiJ\y = Pi\x
            tmpP\x = (Pi\x * curV\x + Pi\y * curV\y) * srcPoints(k)\x - (PiJ\x * curV\x + PiJ\y * curV\y) * srcPoints(k)\y
            tmpP\y = (-Pi\x * curVJ\x + -Pi\y * curVJ\y) * srcPoints(k)\x + (PiJ\x * curVJ\x + PiJ\y * curVJ\y) * srcPoints(k)\y
            tmpP\x * w(k) / miuR : tmpP\y * w(k) / miuR
            newP\x + tmpP\x : newP\y + tmpP\y
          Next
          newP\x + qstar\x : newP\y + qstar\y
        Else
          newP\x = srcPoints(k)\x : newP\y = srcPoints(k)\y
        EndIf

        If preScale
          rDx(j, i) = newP\x * ratio - i
          rDy(j, i) = newP\y * ratio - j
        Else
          rDx(j, i) = newP\x - i
          rDy(j, i) = newP\y - j
        EndIf
        j + nGridSize
      ForEver
      i + nGridSize
    ForEver

    If preScale
      For k = 0 To nPoint - 1
        srcPoints(k)\x * ratio : srcPoints(k)\y * ratio
      Next
    EndIf
  EndIf
EndProcedure

Procedure TransformSimilar(Array srcPoints.CvPoint2D32f(1), Array dstPoints.CvPoint2D32f(1), Array rDx.f(2), Array rDy.f(2), nGridSize)
  Define.f sw, miuS
  Define.CvPoint2D32f swp, swq, pstar, qstar, Pi, PiJ, curV, curVJ, tmpP, newP

  tarH = ArraySize(rDx()) : tarW = ArraySize(rDx(), 2)
  Dim rDx(tarH, tarW) : Dim rDy(tarH, tarW)
  nPoint = ArraySize(srcPoints())

  If nPoint > 1
    Dim w.f(nPoint)

    Repeat
      If i >= tarW And i < tarW + nGridSize - 1 : i = tarW - 1 : ElseIf i >= tarW : Break : EndIf

      Repeat
        If j >= tarH And j < tarH + nGridSize - 1 : j = tarH - 1 : ElseIf j >= tarH : j = 0 : Break : EndIf

        sw = 0
        swp\x = 0 : swp\y = 0
        swq\x = 0 : swq\y = 0
        curV\x = i : curV\y = j
        newP\x = 0 : newP\y = 0

        For k = 0 To nPoint - 1
          If i = dstPoints(k)\x And j = dstPoints(k)\y : Break : EndIf

          w(k) = 1 / ((i - dstPoints(k)\x) * (i - dstPoints(k)\x) + (j - dstPoints(k)\y) * (j - dstPoints(k)\y))
          sw + w(k)
          swp\x + w(k) * dstPoints(k)\x : swp\y + w(k) * dstPoints(k)\y
          swq\x + w(k) * srcPoints(k)\x : swq\y + w(k) * srcPoints(k)\y
        Next

        If k = nPoint
          pstar\x = 1 / sw * swp\x : pstar\y = 1 / sw * swp\y
          qstar\x = 1 / sw * swq\x : qstar\y = 1 / sw * swq\y
          miuS = 0

          For k = 0 To nPoint - 1
            If i = dstPoints(k)\x And j = dstPoints(k)\y : Continue : EndIf

            Pi\x = dstPoints(k)\x - pstar\x : Pi\y = dstPoints(k)\y - pstar\y
            miuS + w(k) * (Pi\x * Pi\x + Pi\y * Pi\y)
          Next
          curV\x - pstar\x : curV\y - pstar\y
          curVJ\x = -curV\y : curVJ\y = curV\x

          For k = 0 To nPoint - 1
            If i = dstPoints(k)\x And j = dstPoints(k)\y : Continue : EndIf

            Pi\x = dstPoints(k)\x - pstar\x : Pi\y = dstPoints(k)\y - pstar\y
            PiJ\x = -Pi\y : PiJ\y = Pi\x
            tmpP\x = (Pi\x * curV\x + Pi\y * curV\y) * srcPoints(k)\x - (PiJ\x * curV\x + PiJ\y * curV\y) * srcPoints(k)\y
            tmpP\y = (-Pi\x * curVJ\x + -Pi\y * curVJ\y) * srcPoints(k)\x + (PiJ\x * curVJ\x + PiJ\y * curVJ\y) * srcPoints(k)\y
            tmpP\x * w(k) / miuS : tmpP\y * w(k) / miuS
            newP\x + tmpP\x : newP\y + tmpP\y
          Next
          newP\x + qstar\x : newP\y + qstar\y
        Else
          newP\x = srcPoints(k)\x : newP\y = srcPoints(k)\y
        EndIf
        rDx(j, i) = newP\x - i
        rDy(j, i) = newP\y - j
        j + nGridSize
      ForEver
      i + nGridSize
    ForEver
  EndIf
EndProcedure

Procedure LoadPoints(Array srcPoints.CvPoint2D32f(1), Array dstPoints.CvPoint2D32f(1), PointsFile.s)
  If LoadJSON(0, PointsFile) And LoadJSON(1, GetPathPart(PointsFile) + GetFilePart(PointsFile, #PB_FileSystem_NoExtension) + ".dst")
    ExtractJSONArray(JSONValue(0), srcPoints())
    ExtractJSONArray(JSONValue(1), dstPoints())
    FreeJSON(0) : FreeJSON(1)
  EndIf
EndProcedure

Procedure SavePoints(Array srcPoints.CvPoint2D32f(1), Array dstPoints.CvPoint2D32f(1), PointsFile.s)
  If CreateJSON(0) And CreateJSON(1)
    InsertJSONArray(JSONValue(0), srcPoints())
    InsertJSONArray(JSONValue(1), dstPoints())
    SaveJSON(0, PointsFile)
    SaveJSON(1, GetPathPart(PointsFile) + GetFilePart(PointsFile, #PB_FileSystem_NoExtension) + ".dst")
    FreeJSON(0) : FreeJSON(1)
  EndIf
EndProcedure

Procedure OpenCV(ImageFile.s)
  If FileSize(ImageFile) > 0
    cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
    window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
    *window_name = cvGetWindowName(window_handle)
    lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

    If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
      MenuItem(1, "Open")
      MenuBar()
      MenuItem(2, "Save")
      MenuBar()
      MenuItem(10, "Exit")
    EndIf
    hWnd = GetParent_(window_handle)
    iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
    SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
    wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
    SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48)
      iWidth = dtWidth - 100
      iRatio1.f = iWidth / *image\width
      iHeight = dtHeight - (100 + 48)
      iRatio2.f = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight + 48)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200
      ShowOriginal = #True : ShowPoints = #True : nGridSize = 2 : nStartPoint = 0
      cvCreateTrackbar("Grid Size", #CV_WINDOW_NAME, @nGridSize, 20, @CvTrackbarCallback())
      Dim anchorPoints.CvPoint2D32f(8) : Dim srcPoints(0) : Dim dstPoints(0)
      Dim tmpSrcPoints.CvPoint2D32f(0) : Dim tmpDstPoints.CvPoint2D32f(0)
      Dim rDx.f(*resize\height, *resize\width) : Dim rDy.f(*resize\height, *resize\width)
      anchorPoints(0)\x = 0 : anchorPoints(0)\y = 0
      anchorPoints(1)\x = *resize\width / 2 : anchorPoints(1)\y = 0
      anchorPoints(2)\x = *resize\width - 1 : anchorPoints(2)\y = 0
      anchorPoints(3)\x = *resize\width - 1 : anchorPoints(3)\y = *resize\height / 2
      anchorPoints(4)\x = *resize\width - 1 : anchorPoints(4)\y = *resize\height - 1
      anchorPoints(5)\x = *resize\width / 2 : anchorPoints(5)\y = *resize\height - 1
      anchorPoints(6)\x = 0 : anchorPoints(6)\y = *resize\height - 1
      anchorPoints(7)\x = 0 : anchorPoints(7)\y = *resize\height / 2
      cvLine(*resize, 0, 0, *resize\width, 0, 0, 0, 0, 0, 2, 8, #Null)
      cvLine(*resize, *resize\width - 1, 0, *resize\width - 1, *resize\height, 0, 0, 0, 0, 2, 8, #Null)
      cvLine(*resize, *resize\width, *resize\height - 1, 0, *resize\height - 1, 0, 0, 0, 0, 2, 8, #Null)
      cvLine(*resize, 0, *resize\height, 0, 0, 0, 0, 0, 0, 2, 8, #Null)
      *mls.IplImage = cvCloneImage(*resize) : *reset.IplImage = cvCloneImage(*resize)
      PointsFile.s = #PB_Compiler_FilePath + "binaries\other\" + GetFilePart(ImageFile, #PB_FileSystem_NoExtension)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
      ShowImage.s = "Rigid: Original"
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)
      cvPutText(*resize, ShowImage, 30, 35, @font, 0, 0, 0, 0)
      cvPutText(*resize, ShowImage, 28, 33, @font, 255, 255, 255, 0)
      cvPutText(*mls, ShowImage, 30, 35, @font, 0, 0, 0, 0)
      cvPutText(*mls, ShowImage, 28, 33, @font, 255, 255, 255, 0)

      Repeat
        If *mls
          Select keyPressed
            Case 32, 65, 97, 68, 100, 71, 103, 76, 108, 80, 112, 84, 116, 86 To 90, 118 To 122
              If ShowGrid
                i = 0 : j = 0

                Repeat
                  cvLine(*resize, 0, i, *mls\width, i, 241, 236, 208, 0, 1, #CV_AA, #Null)
                  i + nGridSize * 5 + 5
                Until i >= *mls\height - 1

                Repeat
                  cvLine(*resize, j, 0, j, *mls\height, 241, 236, 208, 0, 1, #CV_AA, #Null)
                  j + nGridSize * 5 + 5
                Until j >= *mls\width - 1
              EndIf
          EndSelect

          Select keyPressed
            Case 65, 97, 68, 100, 76, 108, 84, 116, 86 To 90, 118 To 122
              Select nTransform
                Case 0 : TransformRigid(srcPoints(), dstPoints(), rDx(), rDy(), nGridSize * 5 + 5)
                Case 1 : TransformSimilar(srcPoints(), dstPoints(), rDx(), rDy(), nGridSize * 5 + 5)
              EndSelect
          EndSelect

          Select keyPressed
            Case 13, 32, 65, 97, 68, 100, 71, 103, 76, 108, 80, 112, 84, 116, 86 To 90, 118 To 122
              GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5)

              If ShowPoints
                If nStartPoint
                  For k = 0 To nStartPoint - 1
                    Select srcPoints(k)\x
                      Case 0 : nX = 10
                      Case *resize\width - 1 : nX = srcPoints(k)\x - 10
                      Default : nX = srcPoints(k)\x
                    EndSelect

                    Select srcPoints(k)\y
                      Case 0 : nY = 10
                      Case *resize\height - 1 : nY = srcPoints(k)\y - 10
                      Default : nY = srcPoints(k)\y
                    EndSelect
                    cvCircle(*resize, nX, nY, 5, 0, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*resize, nX, nY, 3, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*mls, nX, nY, 5, 0, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*mls, nX, nY, 3, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
                  Next
                EndIf
                arrSize = ArraySize(srcPoints())

                For k = nStartPoint To arrSize - 1
                  If srcPoints(k)\x = dstPoints(k)\x And srcPoints(k)\y = dstPoints(k)\y
                    cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 5, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 5, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)

                    If k = arrSize - 1
                      cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                      cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                    EndIf
                  Else
                    cvLine(*resize, srcPoints(k)\x, srcPoints(k)\y, dstPoints(k)\x, dstPoints(k)\y, 255, 255, 255, 0, 4, #CV_AA, #Null)
                    cvLine(*resize, srcPoints(k)\x, srcPoints(k)\y, dstPoints(k)\x, dstPoints(k)\y, 0, 0, 0, 0, 2, #CV_AA, #Null)
                    cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 5, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*resize, dstPoints(k)\x, dstPoints(k)\y, 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)

                    If k = arrSize - 1
                      cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*resize, srcPoints(k)\x, srcPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                      cvCircle(*resize, dstPoints(k)\x, dstPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*resize, dstPoints(k)\x, dstPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                    EndIf
                    cvLine(*mls, srcPoints(k)\x, srcPoints(k)\y, dstPoints(k)\x, dstPoints(k)\y, 255, 255, 255, 0, 4, #CV_AA, #Null)
                    cvLine(*mls, srcPoints(k)\x, srcPoints(k)\y, dstPoints(k)\x, dstPoints(k)\y, 0, 0, 0, 0, 2, #CV_AA, #Null)
                    cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 5, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
                    cvCircle(*mls, dstPoints(k)\x, dstPoints(k)\y, 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)

                    If k = arrSize - 1
                      cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*mls, srcPoints(k)\x, srcPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                      cvCircle(*mls, dstPoints(k)\x, dstPoints(k)\y, 7, 255, 255, 255, 0, 2, #CV_AA, #Null)
                      cvCircle(*mls, dstPoints(k)\x, dstPoints(k)\y, 8, 0, 0, 0, 0, 1, #CV_AA, #Null)
                    EndIf
                  EndIf
                Next

                If ShowOriginal : ShowImage = ": Original" : Else : ShowImage = ": Deformed" : EndIf

                Select nTransform
                  Case 0
                    cvPutText(*resize, "Rigid" + ShowImage, 30, 35, @font, 0, 0, 0, 0)
                    cvPutText(*resize, "Rigid" + ShowImage, 28, 33, @font, 255, 255, 255, 0)
                    cvPutText(*mls, "Rigid" + ShowImage, 30, 35, @font, 0, 0, 0, 0)
                    cvPutText(*mls, "Rigid" + ShowImage, 28, 33, @font, 255, 255, 255, 0)
                  Case 1
                    cvPutText(*resize, "Similarity" + ShowImage, 30, 35, @font, 0, 0, 0, 0)
                    cvPutText(*resize, "Similarity" + ShowImage, 28, 33, @font, 255, 255, 255, 0)
                    cvPutText(*mls, "Similarity" + ShowImage, 30, 35, @font, 0, 0, 0, 0)
                    cvPutText(*mls, "Similarity" + ShowImage, 28, 33, @font, 255, 255, 255, 0)
                EndSelect
              EndIf
          EndSelect

          If ShowOriginal
            cvShowImage(#CV_WINDOW_NAME, *resize)
            *param\Pointer1 = *resize
          Else
            cvShowImage(#CV_WINDOW_NAME, *mls)
            *param\Pointer1 = *mls
          EndIf
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13, 32, 65, 97, 68, 100, 71, 103, 76, 108, 80, 112, 84, 116, 86 To 90, 118 To 122 : cvCopy(*reset, *resize, #Null)
          EndSelect

          Select keyPressed
            Case 13
              ShowOriginal = #True : ShowGrid = #False : ShowPoints = #True
              nGridSize = 2 : nStartPoint = 0 : nTransform = 0
              cvSetTrackbarPos("Grid Size", #CV_WINDOW_NAME, nGridSize)
              Dim srcPoints(0) : Dim dstPoints(0)
              Dim rDx(*resize\height, *resize\width) : Dim rDy(*resize\height, *resize\width)
              cvCopy(*reset, *mls, #Null)
            Case 32
              ShowOriginal ! #True
            Case 65, 97
              arrSize = ArraySize(srcPoints())

              If arrSize - nStartPoint > 0
                For k = nStartPoint To arrSize - 1
                  If srcPoints(k)\x <> dstPoints(k)\x Or srcPoints(k)\y <> dstPoints(k)\y : ShowOriginal = #False : Break : EndIf
                Next
              EndIf
              nAnchorPoints = ArraySize(anchorPoints())

              If arrSize >= nAnchorPoints
                nStartPoint = 0

                For k = 0 To nAnchorPoints - 1
                  AnchorPoint = Bool(srcPoints(k)\x = anchorPoints(k)\x And srcPoints(k)\y = anchorPoints(k)\y)

                  If Not AnchorPoint : nStartPoint = nAnchorPoints : Break : EndIf

                Next
              Else
                nStartPoint = nAnchorPoints : AnchorPoint = #False
              EndIf

              Select AnchorPoint
                Case #True
                  If arrSize > nAnchorPoints
                    nPoints = arrSize - nAnchorPoints
                    Dim tmpSrcPoints(nPoints) : Dim tmpDstPoints(nPoints)

                    For k = 0 To nPoints - 1
                      tmpSrcPoints(k)\x = srcPoints(k + nAnchorPoints)\x : tmpSrcPoints(k)\y = srcPoints(k + nAnchorPoints)\y
                      tmpDstPoints(k)\x = dstPoints(k + nAnchorPoints)\x : tmpDstPoints(k)\y = dstPoints(k + nAnchorPoints)\y
                    Next
                    Dim srcPoints(nPoints) : Dim dstPoints(nPoints)
                    CopyArray(tmpSrcPoints(), srcPoints()) : CopyArray(tmpDstPoints(), dstPoints())
                  Else
                    Dim srcPoints(0) : Dim dstPoints(0)
                  EndIf
                Case #False
                  Dim tmpSrcPoints(arrSize) : Dim tmpDstPoints(arrSize)

                  For k = 0 To arrSize - 1
                    tmpSrcPoints(k)\x = srcPoints(k)\x : tmpSrcPoints(k)\y = srcPoints(k)\y
                    tmpDstPoints(k)\x = dstPoints(k)\x : tmpDstPoints(k)\y = dstPoints(k)\y
                  Next
                  Dim srcPoints(nAnchorPoints) : Dim dstPoints(nAnchorPoints)
                  CopyArray(anchorPoints(), srcPoints()) : CopyArray(anchorPoints(), dstPoints())
                  ReDim srcPoints(arrSize + nAnchorPoints) : ReDim dstPoints(arrSize + nAnchorPoints)

                  For k = 0 To arrSize - 1
                    srcPoints(k + nAnchorPoints)\x = tmpSrcPoints(k)\x : srcPoints(k + nAnchorPoints)\y = tmpSrcPoints(k)\y
                    dstPoints(k + nAnchorPoints)\x = tmpDstPoints(k)\x : dstPoints(k + nAnchorPoints)\y = tmpDstPoints(k)\y
                  Next
              EndSelect
            Case 68, 100
              ShowOriginal = #False
              arrSize = ArraySize(srcPoints())

              If arrSize > nStartPoint : ReDim srcPoints(arrSize - 1) : ReDim dstPoints(arrSize - 1) : EndIf

              Select #True
                Case Bool(arrSize = nStartPoint + 1) : ShowOriginal = #True : cvCopy(*reset, *mls, #Null)
                Case Bool(arrSize = nStartPoint + 2) : ShowPoints = #True
              EndSelect
            Case 71, 103
              ShowGrid ! #True
            Case 76, 108
              Filename.s = OpenFileRequester("Load Points File", PointsFile + ".src", "Points File (*.src)|*.src", 0)

              If FileSize(Filename) > 0 And FileSize(GetPathPart(Filename) + GetFilePart(Filename, #PB_FileSystem_NoExtension) + ".dst") > 0
                ShowOriginal = #False : ShowPoints = #True : nStartPoint = 0
                LoadPoints(srcPoints(), dstPoints(), Filename)
                arrSize = ArraySize(srcPoints())
                nAnchorPoints = ArraySize(anchorPoints())

                If arrSize >= nAnchorPoints
                  nStartPoint = nAnchorPoints

                  For k = 0 To nAnchorPoints - 1
                    If Not Bool(srcPoints(k)\x = anchorPoints(k)\x And srcPoints(k)\y = anchorPoints(k)\y) : nStartPoint = 0 : Break : EndIf
                  Next
                EndIf
              EndIf
            Case 80, 112
              ShowPoints ! #True
            Case 82, 114
              ShowAnimation = #False
              arrSize = ArraySize(srcPoints())

              If arrSize - nStartPoint > 1
                For k = nStartPoint To arrSize - 1
                  If srcPoints(k)\x <> dstPoints(k)\x Or srcPoints(k)\y <> dstPoints(k)\y : ShowAnimation = #True : Break : EndIf
                Next

                If ShowAnimation
                  ShowPoints = #False
                  cvCopy(*reset, *resize, #Null)

                  If ShowGrid
                    i = 0 : j = 0

                    Repeat
                      cvLine(*resize, 0, i, *mls\width, i, 241, 236, 208, 0, 1, #CV_AA, #Null)
                      i + nGridSize * 5 + 5
                    Until i >= *mls\height - 1

                    Repeat
                      cvLine(*resize, j, 0, j, *mls\height, 241, 236, 208, 0, 1, #CV_AA, #Null)
                      j + nGridSize * 5 + 5
                    Until j >= *mls\width - 1
                  EndIf

                  If ShowOriginal
                    For k = 0 To 125 Step 8
                      GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5, k * 0.008)
                      cvShowImage(#CV_WINDOW_NAME, *mls) : cvWaitKey(10)
                    Next

                    For k = 125 To 0 Step -8
                      GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5, k * 0.008)
                      cvShowImage(#CV_WINDOW_NAME, *mls) : cvWaitKey(10)
                    Next
                  Else
                    For k = 125 To 0 Step -8
                      GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5, k * 0.008)
                      cvShowImage(#CV_WINDOW_NAME, *mls) : cvWaitKey(10)
                    Next

                    For k = 0 To 125 Step 8
                      GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5, k * 0.008)
                      cvShowImage(#CV_WINDOW_NAME, *mls) : cvWaitKey(10)
                    Next
                  EndIf
                  GenerateImage(*resize, *mls, rDx(), rDy(), nGridSize * 5 + 5)
                EndIf
              EndIf
            Case 83, 115
              arrSize = ArraySize(srcPoints())

              If arrSize - nStartPoint > 0
                Filename = SaveFileRequester("Save Points File", PointsFile + ".src", "Points File (*.src)|*.src", 0)

                If Filename
                  If GetExtensionPart(Filename) <> "src" : Filename + ".src" : EndIf

                  SavePoints(srcPoints(), dstPoints(), Filename)
                EndIf
              EndIf
            Case 84, 116
              ShowOriginal = #True
              arrSize = ArraySize(srcPoints())

              If arrSize - nStartPoint > 1
                For k = nStartPoint To arrSize - 1
                  If srcPoints(k)\x <> dstPoints(k)\x Or srcPoints(k)\y <> dstPoints(k)\y : ShowOriginal = #False : Break : EndIf
                Next
              EndIf

              If ShowOriginal : ShowPoints = #True : EndIf

              nTransform = (nTransform + 1) % 2
            Case 86, 118
              arrSize = ArraySize(srcPoints())

              If arrSize = 1 : ShowPoints = #True : EndIf

            Case 87, 119
              arrSize = ArraySize(srcPoints())

              If srcPoints(arrSize - 1)\x = dstPoints(arrSize - 1)\x And srcPoints(arrSize - 1)\y = dstPoints(arrSize - 1)\y : ShowPoints = #True : EndIf

            Case 89, 121
              arrSize = ArraySize(srcPoints())

              If Abs(srcPoints(arrSize - 1)\x - dstPoints(arrSize - 1)\x) >= 15 Or Abs(srcPoints(arrSize - 1)\y - dstPoints(arrSize - 1)\y) >= 15
                ShowOriginal = #False
              EndIf
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*mls)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/weight2.jpg")
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 1
; Folding = --
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\