import numpy as np
import cv2

left = cv2.VideoCapture(0)
print("left")

while True:
    if not (left.grab()):
        print("No more frames")
        break
    
    _, leftFrame = left.retrieve()

    cv2.imshow('left', leftFrame)
    cv2.waitKey(10)
    edges = cv2.Canny(leftFrame,100, 200)
    cv2.imshow('canny',edges)
    cv2.waitKey(10)
    sobel_x = cv2.Sobel(leftFrame, cv2.CV_64F, 1, 0, ksize=3)
    sobel_x = cv2.convertScaleAbs(sobel_x)
    cv2.imshow('sobelX',sobel_x)
    cv2.waitKey(10)

    sobel_y = cv2.Sobel(leftFrame, cv2.CV_64F, 0, 1, ksize=3)
    sobel_y = cv2.convertScaleAbs(sobel_y)
    cv2.imshow('sobely', sobel_y)
    cv2.waitKey(10)
    
    
