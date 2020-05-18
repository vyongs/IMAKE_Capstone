# -*- coding: utf-8 -*-
import sys
import pygame
from pygame.locals import *
from pygame.display import *
from OpenGL.GL import *
from OpenGL.GLU import *
from random import *
import math
import cv2
import numpy as np


#색 정의
BLACK= (0,0,0) #R G B
RED = (255, 0, 0)
GREEN = (255,0, 255)
BLUE = (0, 0, 255)
ORANGE = (255,180,0)
YELLOW = (255,255,0)
YELLOW_A = (255,255,0, 80)
BLUE_A = (0, 0, 255, 127)  # R, G, B, Alpha(투명도, 255 : 완전 불투명)

##global W
##W = 320
##global H
##H = 240

#--------------------main
TARGET_FPS = 60
clock = pygame.time.Clock()

#W = 320
#H = 240
W= 640
H= 480
display = (W, H)
screen = pygame.display.set_mode(display, DOUBLEBUF )

colored = np.zeros((640,480,3)) ##colored!!!
R_color = [randint(0,255),randint(0,255),randint(0,255)]
pygame.init()
num = 0
count = 200

################################CAMERA########################
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH,W)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT,H)
fgbg = cv2.createBackgroundSubtractorMOG2(varThreshold=200, detectShadows=False)

runned = False

def nothing(x):
    pass

##cv2.namedWindow("panel", cv2.WINDOW_NORMAL)
##cv2.createTrackbar("Threshold","panel", 0, 255, nothing)
##cv2.resizeWindow("panel", 7, 100)

thresh_done=False
################################################################

while True:
    
    while runned == False:
        ret, frame = cap.read()
        cv2.imshow("original", frame)
        if cv2.waitKey(1) & 0xFF == ord('s'): # s버튼 누르고
            break
        
    ret, frame = cap.read() #배경캡쳐 됨

    if runned == False: #백그라운드 이미지 처리
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        background_img = cv2.GaussianBlur(background_img, (5,5),0)
        runned = True

##    if thresh_done==False and runned == True:
##        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
##        this_img = cv2.GaussianBlur(this_img, (5,5),0)      
##        abdiff = cv2.absdiff(this_img, background_img)
####        thresh = cv2.getTrackbarPos("Threshold","panel") #thresh 값 저장
##        _, thresh_img = cv2.threshold(abdiff, 20, 255, cv2.THRESH_BINARY) #저장된 thresh값 만큼 threshhold줌
##        cv2.imshow("threshimg",thresh_img)        
##        if cv2.waitKey(1) & 0xFF == ord('d'):#d 누르면 thresh 조절 끝
##            print("done")
        thresh_done=True

        
    elif runned == True and thresh_done==True:
        if count < 60 :
            screen.fill(BLACK)

            fontObj = pygame.font.Font(None, 32)  
            textSurfaceObj = fontObj.render(str(3-int(count/20)), True, GREEN)   # 텍스트 객체를 생성한다. 첫번째 파라미터는 텍스트 내용, 두번째는 Anti-aliasing 사용 여부, 세번째는 텍스트 컬러를 나타낸다
            textRectObj = textSurfaceObj.get_rect();                      # 텍스트 객체의 출력 위치를 가져온다
            textRectObj.center = (W/2, H/2)                               # 텍스트 객체의 출력 중심 좌표를 설정한다
            screen.blit(textSurfaceObj, textRectObj)
            
            pygame.display.flip()
            clock.tick(TARGET_FPS)
            count+=1

            
            continue

        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)      
        abdiff = cv2.absdiff(this_img, background_img)

        _, thresh_img = cv2.threshold(abdiff, 20, 255, cv2.THRESH_BINARY)
        cv2.imshow("ya",abdiff)
        kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        opening = cv2.morphologyEx(thresh_img, cv2.MORPH_OPEN, kernel2, 3)
        border = cv2.dilate(opening, kernel2, iterations=3)
        border = border - cv2.erode(border, None)

        temp = np.rot90(border)
        temp = np.flipud(temp)
        temp = np.rot90(thresh_img)
        masking = temp

        
        colored[masking != 0] = [R_color[0],R_color[1],R_color[2]]
        numarr = np.where(colored!=0) #색칠된 부분
        if(float(len(numarr[0]))/float(W*H)/3 >0.9):
            colored = np.zeros((640,480,3)) ##colored!!!
            R_color = [randint(0,255),randint(0,255),randint(0,255)]
            count=0

        
            
        mask = np.flipud(colored)
        me = pygame.surfarray.make_surface(mask).convert()
        me.set_alpha(255)

        screen.fill(BLACK)  # 화면을 검은색으로 지운다
        screen.blit(me,(0,0))

        pygame.display.flip()  # 화면 전체를 업데이트
        clock.tick(TARGET_FPS)  # 프레임 수 맞추기

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
        
cap.release()
cv2.destroyAllWindows()
pygame.quit()
sys.exit()



        
