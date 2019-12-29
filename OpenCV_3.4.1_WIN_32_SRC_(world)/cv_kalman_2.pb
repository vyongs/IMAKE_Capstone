IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Tracks a rotating point at a constant rotation speed where both state and measurement " +
                  "vectors are a 1D point angle; measurement being the real point angle + gaussian noise." + #LF$ + #LF$ +
                  "The real and estimated points are connected by a yellow line segment." + #LF$ + #LF$ +
                  "The real and the measured points are connected by a red line segment." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Reset the rotating tracking point to a different speed." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://cs.unc.edu/~welch/media/pdf/kalman_intro.pdf")
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
*image.IplImage = cvCreateImage(500, 500, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
rng = cvRNG(Random(2147483647))
Dim ArrValues.f(4)
ArrValues(0) = 1
ArrValues(1) = 1
ArrValues(2) = 0
ArrValues(3) = 1
*kalman.CvKalman = cvCreateKalman(2, 1, 0)
*state.CvMat = cvCreateMat(2, 1, CV_MAKETYPE(#CV_32F, 1))
*prediction.CvMat
*measurement.CvMat = cvCreateMat(1, 1, CV_MAKETYPE(#CV_32F, 1))
*noise.CvMat = cvCreateMat(2, 1, CV_MAKETYPE(#CV_32F, 1))
state_pt.CvPoint
prediction_pt.CvPoint
measurement_pt.CvPoint
cvSetZero(*measurement)
font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.4, 0.4, 0, 1, #CV_AA)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  cvRandArr(@rng, *state, #CV_RAND_NORMAL, 0, 0, 0, 0, 0.1, 0, 0, 0)
  *kalman\transition_matrix\fl = @ArrValues()
  cvSetIdentity(*kalman\measurement_matrix, 1, 0, 0, 0)
  cvSetIdentity(*kalman\process_noise_cov, 0.00001, 0, 0, 0)
  cvSetIdentity(*kalman\measurement_noise_cov, 0.1, 0, 0, 0)
  cvSetIdentity(*kalman\error_cov_post, 1, 0, 0, 0)
  cvRandArr(@rng, *kalman\state_post, #CV_RAND_NORMAL, 0, 0, 0, 0, 0.1, 0, 0, 0)

  Repeat
    state_angle.f = *state\fl\f
    state_pt\x = Round(*image\width / 2 + *image\width / 3 * Cos(state_angle), #PB_Round_Nearest)
    state_pt\y = Round(*image\height / 2 - *image\width / 3 * Sin(state_angle), #PB_Round_Nearest)
    *prediction = cvKalmanPredict(*kalman, #Null)
    prediction_angle.f = *prediction\fl\f
    prediction_pt\x = Round(*image\width / 2 + *image\width / 3 * Cos(prediction_angle), #PB_Round_Nearest)
    prediction_pt\y = Round(*image\height / 2 - *image\width / 3 * Sin(prediction_angle), #PB_Round_Nearest)
    cvRandArr(@rng, *measurement, #CV_RAND_NORMAL, 0, 0, 0, 0, Sqr(*kalman\measurement_noise_cov\fl\f), 0, 0, 0)
    cvMatMulAdd(*kalman\measurement_matrix, *state, *measurement, *measurement)
    measurement_angle.f = *measurement\fl\f
    measurement_pt\x = Round(*image\width / 2 + *image\width / 3 * Cos(measurement_angle), #PB_Round_Nearest)
    measurement_pt\y = Round(*image\height / 2 - *image\width / 3 * Sin(measurement_angle), #PB_Round_Nearest)
    cvSetZero(*image)
    cvLine(*image, state_pt\x - 3, state_pt\y - 3, state_pt\x + 3, state_pt\y + 3, 255, 255, 255, 0, 1, #CV_AA, #Null)
    cvLine(*image, state_pt\x + 3, state_pt\y - 3, state_pt\x - 3, state_pt\y + 3, 255, 255, 255, 0, 1, #CV_AA, #Null)
    cvLine(*image, measurement_pt\x - 3, measurement_pt\y - 3, measurement_pt\x + 3, measurement_pt\y + 3, 0, 0, 255, 0, 1, #CV_AA, #Null)
    cvLine(*image, measurement_pt\x + 3, measurement_pt\y - 3, measurement_pt\x - 3, measurement_pt\y + 3, 0, 0, 255, 0, 1, #CV_AA, #Null)
    cvLine(*image, prediction_pt\x - 3, prediction_pt\y - 3, prediction_pt\x + 3, prediction_pt\y + 3, 0, 255, 0, 0, 1, #CV_AA, #Null)
    cvLine(*image, prediction_pt\x + 3, prediction_pt\y - 3, prediction_pt\x - 3, prediction_pt\y + 3, 0, 255, 0, 0, 1, #CV_AA, #Null)
    cvLine(*image, state_pt\x, state_pt\y, measurement_pt\x, measurement_pt\y, 0, 0, 255, 0, 3, #CV_AA, #Null)
    cvLine(*image, state_pt\x, state_pt\y, prediction_pt\x, prediction_pt\y, 0, 255, 255, 0, 3, #CV_AA, #Null)
    cvKalmanCorrect(*kalman, *measurement)
    cvRandArr(@rng, *noise, #CV_RAND_NORMAL, 0, 0, 0, 0, Sqr(*kalman\process_noise_cov\fl\f), 0, 0, 0)
    cvMatMulAdd(*kalman\transition_matrix, *state, *noise, *state)
    cvPutText(*image, "Kalman Prediction", *image\width - 180, 30, @font, 255, 255, 255, 0)
    cvPutText(*image, "Measurement", *image\width - 180, 45, @font, 255, 255, 255, 0)
    cvLine(*image, *image\width - 16, 26, *image\width - 44, 26, 0, 0, 255, 0, 4, #CV_AA, #Null)
    cvLine(*image, *image\width - 16, 41, *image\width - 34, 41, 0, 255, 255, 0, 4, #CV_AA, #Null)
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(100)
  Until keyPressed = 27 Or keyPressed = 32 Or exitCV
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMat(@*noise)
cvReleaseMat(@*measurement)
cvReleaseMat(@*state)
cvReleaseKalman(@*kalman)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\