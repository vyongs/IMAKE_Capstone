# -*- coding: utf-8 -*-
"""
Created on Sun Feb  2 00:20:43 2020

@author: lenovo
"""

import cv2
import time
import numpy as np
from imutils.object_detection import non_max_suppression
from imutils import paths

hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
cap = cv2.VideoCapture(1)
cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)

while True:
    r, frame = cap.read()
    if r:
        start_time = time.time()
        frame = cv2.resize(frame,(320, 240)) # Downscale to improve frame rate
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY) # HOG needs a grayscale image

        rects, weights = hog.detectMultiScale(gray_frame, winStride=(4,4),padding=(8,8), scale=1.05)
        
        # Measure elapsed time for detections
#        end_time = time.time()
#        print("Elapsed time:", end_time-start_time)
        
        for i, (x, y, w, h) in enumerate(rects):
#            if weights[i] < 0.7:
#                continue
            cv2.rectangle(frame, (x,y), (x+w,y+h),(0,0,255),2)
        rects = np.array([[x,y,x+w,y+h]for(x,y,w,h) in rects])
        pick = non_max_suppression(rects,probs=None, overlapThresh=0.65)
        for(xA, yA, xB, yB) in pick:
            cv2.rectangle(frame, (xA,yA),(xB, yB),(0,255,0),2)
            
        cv2.imshow("preview", frame)
    k = cv2.waitKey(1)
    if k & 0xFF == ord("q"): # Exit condition
        break
    

# When everything done, release the capture
cap.release()
# and release the output
#out.release()
# finally, close the window
cv2.destroyAllWindows()
cv2.waitKey(1)
