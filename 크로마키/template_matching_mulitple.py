import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

img_rgb = cv.imread('capture1.jpg')
img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)
template = cv.imread('template1.jpg',0)
w, h = template.shape[::-1]
res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
#print(res)

threshold = 0.7
##
##for i in range(len(res)):
##    if res[i].all() >= threshold:
##        print(i, end=', ')
##    else:
##        print('x', end=', ')

for x in range(len(res)):
    for y in range(len(res[x])):
        if res[x][y] >= threshold:
            print("(",x,",", y ,")", end=', ')
    

print('end')
        
    
loc = np.where( res >= threshold)
print(loc)
for pt in zip(*loc[::-1]):
    #loc의 첫번째 어레이가 x좌표
    #loc의 두번째 어레이가 y좌표임
    cv.rectangle(img_rgb, pt, (pt[0] + w, pt[1] + h), (0,0,255), 2)

cv.imwrite('res_cookie.png',img_rgb)
cv.imshow('result', img_rgb)
