import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

cap = cv.VideoCapture(0)

#methods = ['cv2.TM_CCOEFF','cv2.TM_CCOEFF_NORMED','cv2.TM_CCORR','cv2.TM_CCORR_NORMED','cv2.TM_SQDIFF','cv2.TM_SQDIFF_NORMED']
method = 'TM_CCOEFF_NORMED'

def vyongs_detect(template_file_name, threshold, b,g,r,area,point):
    
    template = cv.imread(template_file_name,0)
    w, h = template.shape[::-1]
    
    res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
    min_val,max_val,min_loc, max_loc = cv.minMaxLoc(res)

    if method in [cv.TM_SQDIFF, cv.TM_SQDIFF_NORMED]:
        top_left = min_loc
    else:
        top_left = max_loc

    if max_val >= threshold:
        #print(max_val)
        bottom_right = (top_left[0]+w,top_left[1]+h)
        cv.rectangle(img_rgb,top_left,bottom_right,(b,g,r),2)
        cv.putText(img_rgb,str(int(round(max_val,2)*100))+'%', top_left,0, 0.5, (b,g,r))
        return True
    ##    print(type(top_left)) # type == tuple
    ##    print(top_left) # (x,y)
    
    

while True:
    ret, img_rgb = cap.read()
    

    if (ret):
        img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)

        #if vyongs_detect('entire_body.jpg', 0.7, 255,255,255):
            #a=0
        #else:
            #break

        #head
        vyongs_detect('a1.jpg', 0.5,  255,0,0,"head",(300,100))

        #shoulder
        #vyongs_detect('shoulder.jpg', 0.7,  255,255,0,"shoulder")

        #left arm
        #vyongs_detect('arm_low.jpg', 0.6,  0,0,255)

        #
##        vyongs_detect('left_foot.jpg', 0.5, 0,0,0)
##        vyongs_detect('right_foot.jpg', 0.5, 255,255,255)

        vyongs_detect('a2.jpg', 0.7, 0,255,0,"left_up",(40,40))
        vyongs_detect('a3.jpg',0.7,0,255,255,"right_up",(500,40))
        vyongs_detect('a4.jpg',0.6,255,255,255,"O",(300,300))
        #vyongs_detect('a3.jpg', 0.7, 0,0,255,"mid",(100,40))
        #vyongs_detect('euna_3.jpg', 0.7, 255,255,255,"down",(300,40))


        

        cv.imshow('result', img_rgb)
        if cv.waitKey(1) & 0xFF == ord('q'):
                break
    else:
        break

cap.release()
cv.destroyAllWindows()
