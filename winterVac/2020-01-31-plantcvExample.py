# -*- coding: utf-8 -*-
"""
Created on Fri Jan 31 21:11:34 2020

@author: INSLAB
"""

from plantcv import plantcv as pcv
import numpy as np
import cv2
from skimage.measure import compare_ssim
import imutils

cap = cv2.VideoCapture(1)
fgbg = cv2.createBackgroundSubtractorMOG2(varThreshold=200, detectShadows=False)
##fgbg = cv2.createBackgroundSubtractorKNN(dist2Threshold=200, detectShadows=0)
runned = False

while(1):
    
    ##To avoid background selection failure caused by auto focusing
    while (1 and runned==False):
        ret, frame = cap.read()
        cv2.imshow("original", frame)
        if cv2.waitKey(1) & 0xFF == ord('s'):
            break
    ############################################################
    ret, frame = cap.read()

    if runned == False:
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        background_img = cv2.GaussianBlur(background_img, (5,5),0)
        runned=True
    else:
        this_img = cv2.cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)
        
        difference = cv2.absdiff(background_img, this_img)
        _, difference = cv2.threshold(difference, 25,255,cv2.THRESH_BINARY)
        cv2.imshow("original", frame)
        cv2.imshow("mask", difference)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
