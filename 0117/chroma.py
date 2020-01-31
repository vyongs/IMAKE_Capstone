import cv2
import numpy as np

img = cv2.imread('iu2.jpg', cv2.IMREAD_COLOR)
img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
ret, thresh = cv2.threshold(img_gray, 230, 255, 0) #160가 원래는 127
contours,hierarchy= cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
cv2.drawContours(img, contours, -1, (255, 255, 0), 3)

cv2.imshow('iu', img)
cv2.imshow('iu_contours', thresh)
cv2.waitKey(0)

#흰바탕 --> 문제점: 흰색 옷
#동영상 테스트 해보기
