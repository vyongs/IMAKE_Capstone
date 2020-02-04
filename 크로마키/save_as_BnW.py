import cv2
import matplotlib.pyplot as plt
import numpy as np

img = cv2.imread('imgs/spiderman/l_foot.jpg', cv2.IMREAD_COLOR)
img_copy = np.copy(img)
img_copy = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

#[초록색 크로마키] 
# 참고 : https://medium.com/fnplus/blue-or-green-screen-effect-with-open-cv-chroma-keying-94d4a6ab2743
lower_green = np.array([0,100,0])
upper_green = np.array([120, 255, 100])
mask = cv2.inRange(img_copy, lower_green, upper_green)

cv2.imwrite('imgs/spiderman/bnw_l_foot_n.jpg',mask)

##ret, thresh = cv2.threshold(img_gray, 230, 255, 0) #160가 원래는 127
##contours,hierarchy= cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
##cv2.drawContours(img, contours, -1, (255, 255, 0), 3)
##
##cv2.imshow('iu', img)
##cv2.imshow('iu_contours', thresh)
##cv2.waitKey(0)

#흰바탕 --> 문제점: 흰색 옷
#동영상 테스트 해보기
