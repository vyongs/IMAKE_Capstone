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


pcv.params.debug="print"


cap = cv2.VideoCapture(1)
fgbg = cv2.createBackgroundSubtractorMOG2(varThreshold=200, detectShadows=0)
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
##        background_img = frame
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        runned=True
    else:
        this_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        frame_ad = cv2.flip(frame, 1)
        
        blur = cv2.GaussianBlur(frame_ad, (5,5), 0)
        
        # rect = removeFaceAra(frame, cascade)
    
        fgmask = fgbg.apply(blur, learningRate=0)
    
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        #get structing element: automatically make kernel, shape and size
        #cv2.MORPH_ELLIPSE, cv2.MORPH_CROSS
        
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel, 2)
        #closing: dialation->erosion (erosion: make thinner)
        #kernel: matrix for close operation
        #https://m.blog.naver.com/samsjang/220505815055
        
        cv2.imshow("original", frame)
        cv2.imshow("mask", fgmask)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
