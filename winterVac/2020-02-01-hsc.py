#https://076923.github.io/posts/Python-opencv-15/
#Maybe we can refer this blog posting

import numpy as np
import cv2

cap = cv2.VideoCapture(1)
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
        back_inv = cv2.bitwise_not(background_img)
        runned=True
    else:
        thresh = cv2.getTrackbarPos("Threshold","panel")
        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)
        
        sub = this_img - background_img
        
        abdiff = cv2.absdiff(this_img, background_img)
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        
        
        cv2.imshow("sub", sub)
        cv2.imshow("ab", abdiff)
        cv2.imshow("thresh", thresh_img)
        cv2.imshow("panel", panel)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
##        bg = cv2.bitwise_and(frame, frame, mask=background_img)
##        fg = cv2.bitwise_and(frame, frame, mask=back_inv)
##        
##        
##        cv2.imshow("bg", bg)
##        cv2.imshow("fg", fg)
##        
##        if cv2.waitKey(1) & 0xFF == ord('q'):
##            break

cap.release()
cv2.destroyAllWindows()
