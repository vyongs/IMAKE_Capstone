# -*- coding: utf-8 -*-
"""
Created on Sat Feb  1 21:23:52 2020

@author: lenovo
"""
#watershed? Algorithm
#https://m.blog.naver.com/PostView.nhn?blogId=samsjang&logNo=220601488606&proxyReferer=https%3A%2F%2Fwww.google.com%2F
#fill border
#https://webnautes.tistory.com/1281
#https://docs.opencv.org/master/d3/db4/tutorial_py_watershed.html

import numpy as np
import cv2

# initialize the HOG descriptor/person detector
hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

cv2.startWindowThread()


cap = cv2.VideoCapture(1)
cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH,320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT,240)
runned = False
panel = np.zeros([10,700,1],np.uint8)
cv2.namedWindow("panel")
def nothing(x):
    pass

cv2.createTrackbar("Threshold","panel", 0, 255, nothing)


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
        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        boxes, weights = hog.detectMultiScale(this_img, winStride=(8,8) )

        boxes = np.array([[x, y, x + w, y + h] for (x, y, w, h) in boxes])
    
        for (xA, yA, xB, yB) in boxes:
            # display the detected boxes in the colour picture
            cv2.rectangle(frame, (xA, yA), (xB, yB),
                              (0, 255, 0), 2)
        
        thresh = cv2.getTrackbarPos("Threshold","panel")
        this_img = cv2.GaussianBlur(this_img, (5,5),0)
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        
        #get structing element: automatically make kernel, shape and size
        #cv2.MORPH_ELLIPSE, cv2.MORPH_CROSS
                
        abdiff = cv2.absdiff(this_img, background_img)
        abdiff = cv2.morphologyEx(abdiff, cv2.MORPH_CLOSE, kernel, 2)
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        color = cv2.bitwise_and(frame, frame, mask=thresh_img)
        opening = cv2.morphologyEx(thresh_img, cv2.MORPH_OPEN, kernel2, 3)
        border = cv2.dilate(opening, kernel2, iterations=3)
        border = border - cv2.erode(border, None)
        
        #https://copycoding.tistory.com/158?category=1042125 
        #About Threshold
        cv2.imshow("color", color)
        cv2.imshow("original",frame)
        cv2.imshow("border", border)
        cv2.imshow("ab", abdiff)
        cv2.imshow("thresh", thresh_img)
        cv2.imshow("panel", panel)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
