#iothread

from threading import Thread
import time
import numpy as np
import cv2
from matplotlib import pyplot as plt

capture_l = cv2.VideoCapture(0) #연결 숫자
capture_r = cv2.VideoCapture(1) 

##[프레임 크기 세팅]
capture_l.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
capture_l.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
capture_r.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
capture_r.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)


def save_imgs():  
    ##[동영상 저장]
    while True:
        ret_l, frame_l = capture_l.read()
        ret_R, frame_r = capture_r.read()
        cv2.imshow("VideoFrame_l", frame_l)
        cv2.imshow("VideoFrame_r", frame_r)
        #cv2.imshow("VideoFrame", frame)
        cv2.waitKey(10)

        #[스테레오 이미지 저장]
        cv2.imwrite('cap_l.png',frame_l)
        cv2.imwrite('cap_r.png',frame_r)
        print("save_imgs")
        time.sleep(1)

def depth_cal():
    time.sleep(2)
    #[스테레오 이미지 처리]
    while True:
        imgL = cv2.imread('cap_l.png',0)
        imgR = cv2.imread('cap_r.png',0)
        
        stereo = cv2.StereoBM_create(numDisparities=16, blockSize=27)
        disparity = stereo.compute(imgL,imgR)
        conDis = cv2.convertScaleAbs(disparity)
        
##        disparity.convertTo(disparity, CV_8U)
        cv2.imshow('disparity',conDis)
        cv2.waitKey(10)
##        cv2.show()
##        plt.imshow(disparity,'gray')
##        plt.show()
##        plt.close()
        print("depth_cal")
        time.sleep(1.5)
    
if __name__ == "__main__":
    th1 = Thread(target=save_imgs)
    th2 = Thread(target=depth_cal)
##    while True:
##        save_imgs()
##        depth_cal()

    th1.start()
    th2.start()
    th1.join()
    th2.join()
