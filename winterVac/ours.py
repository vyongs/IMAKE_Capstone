
import numpy as np
import cv2
video_capture_0=cv2.VideoCapture(0)

while True:
    ret0,frame0=video_capture_0.read()
    if ret0:
        imgL=cv2.imshow('Cam 0',frame0)
        stereo = cv2.StereoBM_create(numDisparities=1, blockSize=5)
        disparity = stereo.compute(imgL,imgL)
        disparity = cv2.convertScaleAbs(disparity)
        
        cv2.imshow('disp', disparity)
        cv2.waitKey(10)

cv2.destroyAllWindows()
