#NOTWORKING####NO xfeatures2d in cv2, it is inside opencv-contrib


from __future__ import print_function
import cv2 as cv
import numpy as np

cap = cv.VideoCapture(0)

while(1):
    ret, frame = cap.read()
    #-- Step 1: Detect the keypoints using SURF Detector
    minHessian = 400
    detector = cont.xfeatures2d.SURF_create(hessianThreshold=minHessian)
    keypoints = detector.detect(frame)
    #-- Draw keypoints
    img_keypoints = np.empty((frame.shape[0], frame.shape[1], 3), dtype=np.uint8)
    cv.drawKeypoints(frame, keypoints, img_keypoints)
    #-- Show detected (drawn) keypoints
    cv.imshow('SURF Keypoints', img_keypoints)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
cap.release()
cv2.destroyAllWindows()
