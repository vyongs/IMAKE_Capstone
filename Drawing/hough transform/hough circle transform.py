import numpy as np
import cv2 as cv

th=70

img_gray = cv.imread('euna.jpg', cv.IMREAD_GRAYSCALE)
img_gray = cv.medianBlur(img_gray,5)
img_color = cv.cvtColor(img_gray,cv.COLOR_GRAY2BGR)

circles = cv.HoughCircles(img_gray,cv.HOUGH_GRADIENT,1,th,
                            param1=50,param2=35,minRadius=0,maxRadius=0)
circles = np.uint16(np.around(circles))

for c in circles[0,:]:

    center = (c[0],c[1])
    radius = c[2]
    
    # 바깥원
    cv.circle(img_color,center,radius,(0,255,0),2)
    
    # 중심원
    cv.circle(img_color,center,2,(0,0,255),3)

cv.imshow('detected circles',img_color)
cv.imwrite('euna_'+str(th)+'.jpg',img_color)
cv.waitKey(0)
cv.destroyAllWindows()
