import cv2
import numpy as np
import time
import scipy

cap = cv2.VideoCapture('imgs/green_screen_vid.mp4')

while True:
    ret, frame = cap.read()

    if (ret):
        
        img_copy = np.copy(frame)
        img_copy = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        lower_green = np.array([0,100,0])
        upper_green = np.array([120, 255, 100])
        mask = cv2.inRange(img_copy, lower_green, upper_green)

        #contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        #cv2.drawContours(frame, contours, -1, (255, 255, 0), 3)
        
        cv2.imshow('mask',mask)
        key = cv2.waitKey(10)


    if key & 0xFF == ord('q'):
            break


cap.release()
cv2.destroyAllWindows()
