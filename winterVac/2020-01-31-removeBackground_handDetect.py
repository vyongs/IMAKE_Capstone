# -*- coding: utf-8 -*-
"""
Created on Fri Jan 31 20:44:13 2020

@author: INSLAB
"""


import numpy as np
import cv2
from skimage.measure import compare_ssim
import imutils

cap = cv2.VideoCapture(1)
fgbg = cv2.createBackgroundSubtractorMOG2(varThreshold=200, detectShadows=False)
fgbg = cv2.createBackgroundSubtractorKNN(dist2Threshold=200, detectShadows=False)
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
        frame_ad = cv2.flip(frame, 1) 
        
        blur = cv2.GaussianBlur(frame_ad, (5,5), 0)
        # rect = removeFaceAra(frame, cascade)
    
        fgmask = fgbg.apply(blur, learningRate=0)
    
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, kernel, 2)
        
        this_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
##        this_img = frame
        score, diff = compare_ssim(background_img, this_img, full=True)
        diff = (diff*255).astype("uint8")
        thresh = cv2.threshold(diff,0,255,cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
        sub = this_img - background_img
        bit_xor = cv2.subtract(this_img,background_img)
        bit_thresh = cv2.threshold(bit_xor, 0, 255, cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
        sub_thresh = cv2.threshold(sub, 0, 255, cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
##        fgmask = fgbg.apply(frame)
##        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
        cv2.imshow("bitthresh", sub_thresh)
        cv2.imshow("test", diff)
        cv2.imshow('frame',thresh)
        cv2.imshow("original", frame)
        cv2.imshow("mask", fgmask)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
