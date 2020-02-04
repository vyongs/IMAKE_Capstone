import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

cap = cv.VideoCapture('imgs/dancing_girl/dancing_girl.mp4')

#methods = ['cv2.TM_CCOEFF','cv2.TM_CCOEFF_NORMED','cv2.TM_CCORR','cv2.TM_CCORR_NORMED','cv2.TM_SQDIFF','cv2.TM_SQDIFF_NORMED']
method = 'TM_CCOEFF_NORMED'

def vyongs_detect(template_file_name, threshold):
    
    template = cv.imread(template_file_name,0)
    w, h = template.shape[::-1]
    
    res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
    min_val,max_val,min_loc, max_loc = cv.minMaxLoc(res)

    if method in [cv.TM_SQDIFF, cv.TM_SQDIFF_NORMED]:
        top_left = min_loc
    else:
        top_left = max_loc
    ##    print(type(top_left)) # type == tuple
    ##    print(top_left) # (x,y)
    bottom_right = (top_left[0]+w,top_left[1]+h)
    cv.rectangle(img_rgb,top_left,bottom_right,255,2)
    

while True:
    ret, img_rgb = cap.read()

    if (ret):
        img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)

        #head
        vyongs_detect('imgs/dancing_girl/head.jpg', 0.9)

        #right arm
        vyongs_detect('imgs/dancing_girl/right_arm.jpg', 0.95)

        #left arm
        vyongs_detect('imgs/dancing_girl/left_arm.jpg', 0.95)

        

        cv.imshow('result', img_rgb)
        if cv.waitKey(1) & 0xFF == ord('q'):
                break
    else:
        break

cap.release()
cv.destroyAllWindows()
