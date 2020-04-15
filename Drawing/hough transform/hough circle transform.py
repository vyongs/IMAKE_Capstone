import numpy as np
import cv2 as cv

minDist=50

img_gray = cv.imread('heads.jpg', cv.IMREAD_GRAYSCALE)
img_gray = cv.medianBlur(img_gray,5)
img_color = cv.cvtColor(img_gray,cv.COLOR_GRAY2BGR)

'''
circles = cv.HoughCircles(img,method,dp, minDist,circles,
                            param1,param2,minRadius,maxRadius)
img = grayscale image
method = HOUGH_GRADIENT or HOUGH_GRADIENT_ALT
dp = 1 이면 입력 이미지와 같은 해상도, 2 이면 절반의 너비와 높이
minDist = 원사이의 최소 거리
circles = 발견한 원에 대한 백터 (x,y,radius) 또는 (x,y,radius,votes)
param1= canny edge detector의 threshold 값
param2 = accumulator의 threshold  (너무 작으면 거짓 원 검출)
minRadius = 원의 최소반지름 (0: 크기를 알 수 없으면
maxRadius = 원의 최대반지름 (0: 크기를 알수 없으면, 음수: 원의 중심만 리턴)

'''
th2 = cv.adaptiveThreshold(img_gray,255,cv.ADAPTIVE_THRESH_MEAN_C,\
cv.THRESH_BINARY,15,2)

cv.imshow("threshold",th2)

circles = cv.HoughCircles(th2,cv.HOUGH_GRADIENT,1,minDist,
                            param1=45,param2=35,minRadius=30,maxRadius=80)

# if nothing is detected
if circles is None:
    print("not detected")
    exit(0)

circles = np.uint16(np.around(circles))
print("\n",circles)

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
