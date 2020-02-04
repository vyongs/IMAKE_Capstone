import cv2
import numpy as np
import time

cap = cv2.VideoCapture('whitewall.avi')

while True:
    ret, frame = cap.read()

    if (ret):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        ret, thresh = cv2.threshold(gray, 130, 255, 0)
        contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        cv2.drawContours(frame, contours, -1, (255, 255, 0), 3)
        
        cv2.imshow('frame',frame)
        cv2.imshow('contours', thresh)

    if cv2.waitKey(1) & 0xFF == ord('q'):
            break


cap.release()
cv2.destroyAllWindows()
