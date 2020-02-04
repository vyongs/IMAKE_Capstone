import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

cap = cv.VideoCapture('green_screen_vid.mp4')

while True:
    ret, img_rgb = cap.read()
    
    img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)
    template = cv.imread('color_head.jpg',0)
    w, h = template.shape[::-1]
    res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)

    threshold = 0.55
        
    loc = np.where( res >= threshold)
    for pt in zip(*loc[::-1]):
        #loc의 첫번째 어레이가 x좌표
        #loc의 두번째 어레이가 y좌표임
        cv.rectangle(img_rgb, pt, (pt[0] + w, pt[1] + h), (0,0,255), 2)

    #cv.imwrite('res_cookie.png',img_rgb)
    cv.imshow('result', img_rgb)
    if cv.waitKey(1) & 0xFF == ord('q'):
            break
