import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

def is_it_human(threshold):
    ret, img_rgb = cap.read()
    if (ret):
        img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)

        template = cv.imread('entire_body.jpg',0)
        w, h = template.shape[::-1]
        
        res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
        min_val,max_val,min_loc, max_loc = cv.minMaxLoc(res)

        if method in [cv.TM_SQDIFF, cv.TM_SQDIFF_NORMED]:
            top_left = min_loc
        else:
            top_left = max_loc

        if max_val >= threshold:
            ##bottom_right = (top_left[0]+w,top_left[1]+h)
            ##cv.rectangle(img_rgb,top_left,bottom_right,(255,255,255),2)
            print("human!")
            return True
        else:
            print("NOT human!")
            return False


def vyongs_detect(template_file_name, threshold, b,g,r ,area):
    
    template = cv.imread(template_file_name,0)
    w, h = template.shape[::-1]
    
    res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
    min_val,max_val,min_loc, max_loc = cv.minMaxLoc(res)

    if method in [cv.TM_SQDIFF, cv.TM_SQDIFF_NORMED]:
        top_left = min_loc
    else:
        top_left = max_loc

    if max_val >= threshold:
        bottom_right = (top_left[0]+w,top_left[1]+h)
        cv.rectangle(img_rgb,top_left,bottom_right,(b,g,r),2)
        cv.putText(img_rgb,area, top_left,0, 0.5, (b,g,r))

    ##    print(type(top_left)) # type == tuple
    ##    print(top_left) # (x,y)
    


cap = cv.VideoCapture('dancing_spiderman.mp4')

#methods = ['cv2.TM_CCOEFF','cv2.TM_CCOEFF_NORMED','cv2.TM_CCORR','cv2.TM_CCORR_NORMED','cv2.TM_SQDIFF','cv2.TM_SQDIFF_NORMED']
method = 'TM_CCOEFF_NORMED'

human = is_it_human(0.6)

while True:
    
    ret, img_rgb = cap.read()

    if (ret):
        img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)
        if human:
            #head
            vyongs_detect('bnw.jpg', 0.3,  255,0,0 , "head")

            #shoulder
            vyongs_detect('bnw_shoulder.jpg', 0.7,  255,255,0  ,"shoulder")

            #left arm
            #vyongs_detect('arm_low.jpg', 0.6,  0,0,255)

            
    ##        vyongs_detect('left_foot.jpg', 0.5, 0,0,0)
    ##        vyongs_detect('right_foot.jpg', 0.5, 255,255,255)

            vyongs_detect('bnw_l_foot.jpg', 0.66, 0,0,0  ,"left foot")
            vyongs_detect('bnw_r_foot.jpg', 0.55, 255,255,255, "right foot")


            

            cv.imshow('result', img_rgb)
            if cv.waitKey(1) & 0xFF == ord('q'):
                    break
        else:
            print("not human")
    else:
        break

cap.release()
cv.destroyAllWindows()
