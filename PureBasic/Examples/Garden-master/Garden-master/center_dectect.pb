IncludePath "C:\Users\Administrator.DESKTOP-78MI24B\Documents\GitHub\IMAKE_Capstone\OpenCV_3.4.1_WIN_32_SRC_(world)"
IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Contour extraction and calculation is used to determine finger, palm, and depth locations." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between views."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
  EndSelect
EndProcedure

;Palm 
Global *pstorage.CvMemStorage, *palm.CvSeq ;pstorage는 palm storage

#CV_SEQ_ELTYPE_POINT = CV_MAKETYPE(#CV_32S, 2)
*pstorage = cvCreateMemStorage(0) : cvClearMemStorage(*pstorage)
*palm = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *pstorage)

Procedure GetConvexHull(*image.IplImage, *contours.CvSeq) ;컨벡스헐을 가져오는 함수
  *hull.CvSeq = cvConvexHull2(*contours, #Null, #CV_CLOCKWISE, #False)
  *pt1.CvPoint = cvGetSeqElem(*hull, *hull\total - 1) : *pt2.CvPoint

  For rtnCount = 0 To *hull\total - 1
    *pt2 = cvGetSeqElem(*hull, rtnCount)
    pt1 = PeekL(*pt1\x) : pt2 = PeekL(*pt1\x + 4)
    pt3 = PeekL(*pt2\x) : pt4 = PeekL(*pt2\x + 4)
    cvLine(*image, pt1, pt2, pt3, pt4, 0, 255, 255, 0, 2, #CV_AA, #Null)
    *pt1 = *pt2
  Next
  *element.CvConvexityDefect : pt.CvPoint
  *storage.CvMemStorage = cvCreateMemStorage(0) : cvClearMemStorage(*storage)
  *defect.CvSeq = cvConvexityDefects(*contours, *hull, *storage)

  For rtnCount = 0 To *defect\total - 1
    *element = cvGetSeqElem(*defect, rtnCount)

    If *element\depth > 10
      pt\x = *element\depth_point\x
      pt\y = *element\depth_point\y
      cvCircle(*image, pt\x, pt\y, 5, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
      cvSeqPush(*palm, @pt)
    EndIf
  Next
  cvReleaseMemStorage(@*storage)
EndProcedure

Global *fstorage.CvMemStorage, *finger.CvSeq ; fstoage는 finger storage
*fstorage = cvCreateMemStorage(0) : cvClearMemStorage(*fstorage) 
; *fstorage에 메모리 공간(디폴트 : 64kb)생성 후 메모리  내용 clear
*finger = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *fstorage)
; opencv에서 사용하는 구조체 seq. 시퀀스 종류 / 헤더 크기 / 시퀀스가 포함할 객체 크기 / 새로운 원소가 추가될 때 할당할 메모리 지정
; 시퀀스 설명 - https://m.blog.naver.com/PostView.nhn?blogId=03tlqfk&logNo=220939395043&proxyReferer=https%3A%2F%2Fwww.google.com%2F

Procedure DetectFingers(*image.IplImage, *contours.CvSeq, centerX, centerY)
  *p0.CvPoint : *p1.CvPoint : *p2.CvPoint
  vector1.CvPoint : vector2.CvPoint
  minP0.CvPoint : minP1.CvPoint : minP2.CvPoint
  l1.CvPoint : l2.CvPoint : l3.CvPoint
  Dim finger.CvPoint(100) : Dim fLocation(100)

  For rtnCount = 0 To *contours\total - 1
    *p0 = cvGetSeqElem(*contours, (rtnCount + 40) % *contours\total)
    *p1 = cvGetSeqElem(*contours, rtnCount)
    *p2 = cvGetSeqElem(*contours,(rtnCount + 80) % *contours\total)
    vector1\x = *p0\x - *p1\x
    vector1\y = *p0\y - *p1\y
    vector2\x = *p0\x - *p2\x
    vector2\y = *p0\y - *p2\y
    dotProduct = vector1\x * vector2\x + vector1\y * vector2\y
    length1.f = Sqr(vector1\x * vector1\x + vector1\y * vector1\y)
    length2.f = Sqr(vector2\x * vector2\x + vector2\y * vector2\y)
    angle.f = Abs(dotProduct / (length1 * length2))

    If angle < 0.1
      If Not signal
        signal = #True
        minP0\x = *p0\x
        minP0\y = *p0\y
        minP1\x = *p1\x
        minP1\y = *p1\y
        minP2\x = *p2\x
        minP2\y = *p2\y
        minAngle.f = angle
      Else
        If angle <= minAngle
          minP0\x = *p0\x
          minP0\y = *p0\y
          minP1\x = *p1\x
          minP1\y = *p1\y
          minP2\x = *p2\x
          minP2\y = *p2\y
          minAngle.f = angle
        EndIf
      EndIf
    Else
      If signal
        signal = #False
        l1\x = minP0\x - centerX
        l1\y = minP0\y - centerY
        l2\x = minP1\x - centerX
        l2\y = minP1\y - centerY
        l3\x = minP2\x - centerX
        l3\y = minP2\y - centerY
        length0 = Sqr(l1\x * l1\x + l1\y * l1\y)
        length1 = Sqr(l2\x * l2\x + l2\y * l2\y)
        length2 = Sqr(l3\x * l3\x + l3\y * l3\y)

        If length0 > length1 And length0 > length2
          finger(count) = minP0
          fLocation(count) = rtnCount + 20
          count + 1
        ElseIf length0 < length1 And length0 < length2
          cvSeqPush(*palm, @minP0)
        EndIf
      EndIf
    EndIf
  Next

  For rtnCount = 0 To count - 1
    If rtnCount > 0
      If fLocation(rtnCount) - fLocation(rtnCount - 1) > 40
        cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 6, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
        cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 10, 0, 255, 0, 0, 2, #CV_AA, #Null)
      EndIf
    Else
      cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 6, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
      cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 10, 0, 255, 0, 0, 2, #CV_AA, #Null)
    EndIf
  Next
EndProcedure

Global palmPositionFull.b = #False, palmCountFull.b = #False

Procedure DetectHand(*image.IplImage, *contours.CvSeq)
  useAvePalm.b = #True

  If *palm\total <= 2 ; -------------------------- 손바닥이 2개 이하일 때 ~
    useAvePalm = #False
    font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
    cvPutText(*image, "ERROR: Palm Position!", 10, 30, @font, 0, 0, 255, 0)
    
    *palmTemp.CvPoint : *temp.CvPoint : *additional.CvPoint
    *storage.CvMemStorage = cvCreateMemStorage(0) : cvClearMemStorage(*storage)
    *palm2.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage) 
    ;cvCreateSeq(int seqFlags, int HeaderSize, int ElemSize, CvMemStorage* storage)  flag => x,y쌍으로 저장

    For i = 0 To *palm\total - 1
      
      ; procedure : 1) palm에서 palmtemp로 원소 인덱싱 2) contours에서 temp로 원소 인덱싱
      ;3) temp(contoures)랑 palmtemp(palm)랑 원소 같으면-> addtional에 contours의 (j + (*contours\total / 2) % *contours\total)번째인덱스 리턴
      ;4) additional\y <= palmtemp\y(palm\y) 이면 cvCircle로 additional의 x,y좌표에 원 그리고 5) palm마지막에 additional을 push
      
      ;6)palm2에서 temp로 원소 인덱싱과 palm의 마지막에 temp를 push 7) temp에 contours 인덱싱 --> palm == palm2, temp == contours
      ;8) additional이 있는데 temp\y(contours\y) <= additional\y이면 *additional = *temp --> 조건에 따라 *additional == *temp
       
      *palmTemp = cvGetSeqElem(*palm, i)  ;cv1get은 뭐지 cvget도 아니고

      For j = 1 To *contours\total - 1
        *temp = cvGetSeqElem(*contours, j) ;cvGetSeqElem(CvSeq* seq, int index) => index에 따라 Sequence의 원소들의 포인터를 반환한다.
        ; Parameters : - seq: 찾고자 하는 원본 Sequence. .- index: 찾고자 하는 원소의 index.

        If *temp\y = *palmTemp\y And *temp\x = *palmTemp\x
          *additional = cvGetSeqElem(*contours, j + (*contours\total / 2) % *contours\total)

          If *additional\y <= *palmTemp\y
            cvCircle(*image, *additional\x, *additional\y, 10, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
            cvSeqPush(*palm2, *additional) ; *additional을 *palm2의 마지막에 push
          EndIf
        EndIf
      Next
    Next
    
    ; palm2 관련 
    For i = 0 To *palm2\total - 1
      *temp = cvGetSeqElem(*palm2, i)
      cvSeqPush(*palm, *temp) ;*palm의 마지막에 *temp를 push함
    Next

    For i = 1 To *contours\total - 1
      *temp = cvGetSeqElem(*contours, 1)
      
      If *additional
        If *temp\y <= *additional\y : *additional = *temp : EndIf
      EndIf
    Next

    If *additional
      cvCircle(*image, *additional\x, *additional\y, 10, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
      cvSeqPush(*palm, *additional) ;*palm의 마지막에 *temp를 push함
    EndIf
  EndIf
  ;----------------------------------- ~ 손바닥이 2개 이하일 때 끝
  
  minCircleCenter.CvPoint2D32f
  ; CvPoint2D32f타입은 실수형 맴버x와 y를 가지고있다.
  ; 참고자료 = https://lueseypid.tistory.com/69 
  If *palm\total : cvMinEnclosingCircle(*palm, @minCircleCenter, @radius.f) : EndIf
  ;                cvMinEnclosingCircle(CvArr* points, CvPoint2D32f* center, float* radius);
  
  ;----------------------------------------- 손바닥이 2개 초과일 때 시작 ~
  If useAvePalm
    avePalmCenter.CvPoint : disTemp.CvPoint

    For i = 0 To *palm\total - 1
      *temp = cvGetSeqElem(*palm, i)
      avePalmCenter\x + *temp\x
      avePalmCenter\y + *temp\y
    Next
    avePalmCenter\x = avePalmCenter\x / *palm\total  ; 센터 평균을 구함
    avePalmCenter\y = avePalmCenter\y / *palm\total

    For i = 0 To *palm\total - 1
      *temp = cvGetSeqElem(*palm, i)
      disTemp\x = *temp\x - avePalmCenter\x
      disTemp\y = *temp\y - avePalmCenter\y
      lengthTemp = Sqr(disTemp\x * disTemp\x + disTemp\y * disTemp\y) ; 루트 처리
      radius2 + lengthTemp ; radius2에 lengthTemp할당
    Next
    radius2 = radius2 / *palm\total
    radius = 0.5 * radius + 0.5 * radius2
    minCircleCenter\x = 0.5 * minCircleCenter\x + 0.5 * avePalmCenter\x
    minCircleCenter\y = 0.5 * minCircleCenter\y + 0.5 * avePalmCenter\y
  EndIf
  
  ; ------------------------------------ ~ 손바닥이 2개 초과일 때 끝
  
  ; ------------------------------------ 그리기 관련..~
  Dim palmPosition.CvPoint(5)
  palmPosition(palmPositionCount)\x = Round(minCircleCenter\x, #PB_Round_Nearest)
  palmPosition(palmPositionCount)\y = Round(minCircleCenter\y, #PB_Round_Nearest)
  palmPositionCount + 1 % 3

  If palmPositionFull ; palmPositionFull 이 true이면
    For i = 0 To 3 - 1
      xTemp.f + palmPosition(i)\x
      yTemp.f + palmPosition(i)\y
    Next
    minCircleCenter\x = Round(xtemp / 3, #PB_Round_Nearest) ; 3개의 x 평균값의 반올림 값 할당
    minCircleCenter\y = Round(ytemp / 3, #PB_Round_Nearest) ; 3개의 y 평균값의
  EndIf
  
  ; 만약 palmPositionCount가 2이고 palmPositionFull이 False면 palmPositionFull을 true로 바꿈
  If palmPositionCount = 2 And palmPositionFull = #False : palmPositionFull = #True : EndIf
  
  
  cvCircle(*image, minCircleCenter\x, minCircleCenter\y, 10, 255, 255, 0, 0, 4, #CV_AA, #Null) ; 하늘색 원 위치
  Debug minCircleCenter\x ;;;;;;;;;
  ;Debug minCircleCenter\y ;;;;;;;;;

  Dim palmSize(5) : palmSize(palmSizeCount) = Round(radius, #PB_Round_Nearest)
  palmSizeCount + 1 % 3

  If palmCountFull
    For i = 0 To 3 - 1
      tempCount + palmSize(i)
    Next
    radius = tempCount / 3
  EndIf

  If palmSizeCount = 2 And palmCountFull = #False : palmCountFull = #True : EndIf 
  ; palmSizeCount가 2개면 (손이 두개면) palmCountFull = false, 3개 이상이면 true

  cvCircle(*image, minCircleCenter\x, minCircleCenter\y, Round(radius, #PB_Round_Nearest), 0, 0, 255, 0, 2, #CV_AA, #Null)
  cvCircle(*image, minCircleCenter\x, minCircleCenter\y, Round(radius * 1.2, #PB_Round_Nearest), 255, 0, 255, 0, 2, #CV_AA, #Null)
  
  ;-------------------------------------------------- finger 관련 ~  
  tipLength.CvPoint : *point.CvPoint

  For i = 0 To *finger\total - 1
    *point = cvGetSeqElem(*finger, i)
    tipLength\x = *point\x - minCircleCenter\x
    tipLength\y = *point\y - minCircleCenter\y
    fingerLength = Sqr(tipLength\x * tipLength\x + tipLength\y * tipLength\y)

    If fingerLength > Round(radius * 1.2, #PB_Round_Nearest)
      cvCircle(*image, *point\x, *point\y, 6, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
    EndIf
  Next
  cvClearSeq(*finger)
  cvClearSeq(*palm)
  cvReleaseMemStorage(@*storage)
EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
  ; 카메라로부터 영상을 받아와 CvCapture포인터 형식으로 반환함. 
Until nCreate = 99 Or *capture

If *capture ; 이미지가 캡쳐되면 가장 큰 if 시작 ---------------------------------------------------------------------
;   cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE) ; 창 생성
;   window_handle = cvGetWindowHandle(#CV_WINDOW_NAME) ; 윈도우 핸들을 반환해서 할당
;   *window_name = cvGetWindowName(window_handle)      ; 윈도우 이름을 받아서 할당
;   lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())
; 
;   If CreatePopupImageMenu(0, #PB_Menu_ModernLook) ;팝업 이미지메뉴 생성되면
;     MenuItem(10, "Exit")
;   EndIf
;   
  ;----------------------------------------윈도우에 관한 내용. ---------------------------------------
;   hWnd = GetParent_(window_handle)
;   iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
;   SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
;   wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
;   SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
   FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
   FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
; 
;   If FrameWidth > 640
;     nRatio.d = 640 / FrameWidth
;     FrameWidth * nRatio : FrameHeight * nRatio
;     cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH, FrameWidth) ; **Set:캡처 처리를 한다. 두번째파라미터가 세팅하고 싶은 것, 세번째 파라미터가 세팅할 값
;     cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight) ;**Get: 캡처와 관련된 값을 가져온다.
;   EndIf ; 캡쳐화면 프레임 크기가 640보다 크면 640이 되도록 조절
  
;   FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
;   FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
;   cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
;   ToolTip(window_handle, #CV_DESCRIPTION) ; 기본 라이브러리에 없음. (마우스 나타내는 +표시 관련된 것 같음.)
  
  cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH,640) ; **Set:캡처 처리를 한다. 두번째파라미터가 세팅하고 싶은 것, 세번째 파라미터가 세팅할 값
  cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight) ;**Get: 캡처와 관련된 값을 가져온다.
  *YCrCb.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3) ;Ipl 구조체 메모리를 생성하여 그 포인터를   반환한다. (이미지 크기와 이미지를 표현하는 비트 크기)
  *mask.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *contour.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null) ; 자체 커널을 생성하는 함수
  *storage.CvMemStorage = cvCreateMemStorage(0) 
  *contours.CvSeq : contourCenter.CvBox2D ;컨투어!!! 센터 !! == 특정 타원을 감싸는 사각형을 표현할 수 있다. (https://makalu.tistory.com/220)
  *image.IplImage
  
;   *param.CvUserData = AllocateMemory(SizeOf(CvUserData)) ; 메모리 할당 (마우스 콜백 함수에 사용됨.)
;   *param\Value = window_handle
;   cvSetMouseCallback(*window_name, @CvMouseCallback(), *param) ;@는 함수 포인터
  
  ;-------------------------------------윈도우에 관한 내용 끝 -----------------------------------
  
  ;-------------------------------------이미지 처리에 관한 내용 repeat 시작 ----------------------------------
  Repeat
    *image = cvQueryFrame(*capture) ; ** 카메라 또는 파일에서 프레임을 잡아 반환한다. 
   

    If *image
      cvFlip(*image, #Null, 1) ; 이미지 플립 (1은 좌우반전, null주면 src에 데이터 덮어씀)   https://m.blog.naver.com/PostView.nhn?blogId=hecki&logNo=30144802937&proxyReferer=https%3A%2F%2Fwww.google.com%2F
      cvSetZero(*mask) ; 배열의 모든 원소를 0으로 처리한다.
      cvCvtColor(*image, *YCrCb, #CV_BGR2YCrCb, 1) ; 파라미터 - 원본이미지, 새 이미지를 저장할 곳, 색 변환 작업에 관한 파라미터, ?, ;;#CV_BGR2YCrCb == 36 
      cvSplit(*YCrCb, #Null, *mask, #Null, #Null) ; 다채널 배열을 여러개의 단채널 배열로 반환한다.
      cvErode(*mask, *mask, *kernel, 2)           ; 이미지 약화, 약화 계산 2번
      cvDilate(*mask, *mask, *kernel, 3)          ; 이미지 강화, 강화 계산 3번
      cvSmooth(*mask, *mask, #CV_GAUSSIAN, 21, 0, 0, 0) ; 스무딩(블러) 파라미터 - 입력영상 , 출력영상, 처리방법, 뒤에 4개는 처리방법에 따라 달라지는 값임
      cvThreshold(*mask, *mask, 130, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU) ; 영상의 이진화. 파라미터 - 입력영상, 출력영상, 임계값, 임계값 넘는 픽셀값을 몇으로 줄지, 설정 (임계값 이하0, 초과1)
      cvClearMemStorage(*storage)
      nContours = cvFindContours(*mask, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0) ;contours 사용
      ; 이진화된 이미지(Binary Image)에서 윤곽을 찾아 그 갯수를 반환한다. 
      ; 파라미터 - 원본 이미지, 윤곽이 저장될 메모리공간, 최윤곽의 윤곽포인터가 저장됨, 시퀀스 헤더의 크기, 모드 (최윤곽의 윤곽만을 찾아낸다.), 컨투어를 구하지 않고 추정하는 메소드 종류 (모든 컨투어의 점을 체인코드에서 포인트로 전환한다.) 모든 컨투어 포인트 이동(뭔지 모르겟음) (0,0) 
      cvSetZero(*contour) 
      
      ;------------------------------이미지 처리
      
      ;------------------------------외곽선 처리

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0) ; 전체 경계선이 포함하는 영역의 넓이를 구한다.

          If area > 20000 And area < 100000
            cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0) ; 외곽선을 그린다.
            ; cvDrawContours(*img, *contour, blue1.d, green1.d, red1.d, alpha1.d, blue2.d, green2.d, red2.d, alpha2.d, maxLevel, thickness, lineType, x, y)
            ; 파라미터 - 윤곽을 그리고자하는 원본 이미지, 윤곽정보 , 외곽선의 색깔, 구멍의 색깔, 그리게 되는 윤곽의 최대 레벨.  , 선의 굵기 (filled이므로 내부를 채움), 선의 종류 (CV_AA: Anti-Aliasing된 선) 
            cvMinAreaRect2(@contourCenter, *contours, #Null)
            ; 2D의 점들의 집합을 둘러 싸는 최소의 직사각형을 찾는다. cvMinAreaRect2(*box, *points, *storage)
            ; 파라미터 - 점들의 seq혹은 배열, 
            GetConvexHull(*image, *contours)
            ; 이정함__ 컨벡스헐 가져오기
            DetectFingers(*image, *contours, contourCenter\center\x, contourCenter\center\y)
            ; 이정함__ 손가락 디텍트
            DetectHand(*image, *contours)


            ; 이정함__ 손 디텍트
          EndIf
          
          *contours = *contours\h_next ; 다음 컨투어를 할당(?
         
        Next
      EndIf

;       Select view
;         Case 0
;           cvShowImage(#CV_WINDOW_NAME, *image)
;         Case 1
;           cvShowImage(#CV_WINDOW_NAME, *mask)
;         Case 2
;           cvShowImage(#CV_WINDOW_NAME, *contour)
;       EndSelect
      keyPressed = cvWaitKey(10) 
; 
;       If keyPressed = 32 : view = (view + 1) % 3 : EndIf  ; key번호는 ascii를 따름 (http://www.asciitable.com/)

    EndIf
  Until keyPressed = 27 Or exitCV ; esc눌렀을 때 까지 repeat 끝 -----------------------------------------------------------------
  
 
  ; ---------------------------------------------------- 메모리 비워줌 (free memory) 시작 ------------------------------------------
  
;   FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseMemStorage(@*fstorage)
  cvReleaseMemStorage(@*pstorage)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*contour)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*YCrCb)
;   cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
  
  ; ---------------------------------------------------- 메모리 비워줌 (free memory)  끝 ------------------------------------------
  
  
Else ; 이미지 캡쳐가 안되면 (가장 큰 if문의 else)
;   MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf ; 가장 큰 if 끝
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 2
; Folding = g
; EnableXP