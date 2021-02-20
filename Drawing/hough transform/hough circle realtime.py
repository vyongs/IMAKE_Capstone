import cv2
import numpy as np

video = cv2.VideoCapture(1)
while True:
    ret, orig_frame = video.read()
    if not ret:
        print("Not connected")
        break;
    gray = cv2.cvtColor(orig_frame, cv2.COLOR_BGR2GRAY)
    gray = cv2.medianBlur(gray,5)

    #th2 = cv2.adaptiveThreshold(gray,255,cv2.ADAPTIVE_THRESH_MEAN_C,cv2.THRESH_BINARY,15,2)
    
    circles = cv2.HoughCircles(gray,cv2.HOUGH_GRADIENT,1,150,param1=50,param2=35,minRadius=30,maxRadius=80)
    if circles is not None:
        for c in circles[0,:]:

            center = (c[0],c[1])
            radius = c[2]
    
        # 바깥원
            cv2.circle(gray,center,radius,(0,255,0),2)
    
        # 중심원
            cv2.circle(gray,center,2,(0,0,255),3)
    cv2.imshow("frame", gray)
    key = cv2.waitKey(1)
    if key == 27:
        break

cv2.destroyAllWindows()
video.release()
