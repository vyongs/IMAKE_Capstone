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
#--------------------virus 클래스 정의 ----------------------------
class Virus:
    x, y = 0, 0
    touched_B = False
    touched_N =0
    radius = 30
    color = (255,0,0)

    def __init__ (self):
        self.x = randint(50,W-50)
        self.y = randint(50,H-50)
        
    def draw(self):
        pygame.draw.circle(screen, self.color, (self.x, self.y) , self.radius)
        
    def update(self):

        if (mask[v.x][v.y] == 255) and (self.touched_B==False):
        ##사람 없고 && 터치된 기록 x
            self.touched_B = False
            
        elif (mask[v.x][v.y] == 255) and (self.touched_B== True):
        ##사람 없고 && 터치된 기록 o
            self.touched_B = False
            
        elif (mask[v.x][v.y] == 0) and (self.touched_B==False):
        ##사람 있고 && 터치된 기록 x
            self.touched_B = True
            self.touched_N += 1
            self.radius-=10

        elif (mask[v.x][v.y] == 0) and (self.touched_B==True):
        ##사람 있고 && 터치된 기록 o
            self.touched=True
            
        if self.touched_N > 3:
            return True

        return False
        
#--------------------main-----------------------------------------
    
TARGET_FPS = 60
clock = pygame.time.Clock()

W= 640
H= 480
display = (W, H)
screen = pygame.display.set_mode(display, DOUBLEBUF )

pygame.init()
num = 0
colored = np.zeros((640,480,3))
viruses = []

virus_L = pygame.image.load('virus.png')
hand_img1 = pygame.image.load('hands1.png')
hand_img1 = pygame.transform.scale(hand_img1, (W,H))

##-----------카메라 셋업 ~~ --------------------------

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

##---------- ~~ 카메라 셋업 ------------------------


while True:
    
    screen.fill(BLACK)  # 화면을 검은색으로 지운다
    screen.blit(hand_img1,(0,0))
    screen.blit(virus_L, (0,0))
    ##---------- 백그라운드 대비 사람 이미지 처리 ~~ ---------
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
##        thresh = cv2.getTrackbarPos("Threshold","panel") #thresh 값 저장
##        _, thresh_img = cv2.threshold(abdiff, 20, 255, cv2.THRESH_BINARY) #저장된 thresh값 만큼 threshhold줌
##        cv2.imshow("threshimg",thresh_img)        
##        if cv2.waitKey(1) & 0xFF == ord('d'):#d 누르면 thresh 조절 끝
##            print("done")
        thresh_done=True

    ##---------- ~~ 백그라운드 대비 사람 이미지 처리  ---------
    
  ##--------------------게임의 상태를 업데이트하는 부분--------------------------

    elif runned == True and thresh_done==True:
       
        if (len(viruses) <8 ) :
            temp = Virus() #init <-- x,y,qty
            viruses.append(temp)
            #print(temp.x,",",temp.y)


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
        mask = np.flipud(masking)
        #print("len:",len(mask),":",len(mask[0]))
        
        me = pygame.surfarray.make_surface(mask).convert()
        me.set_alpha(80)

        for i in range(len(viruses)-1, -1, -1):
            v = viruses[i]
            v.draw()
            if v.update():
                del(viruses[i])
                


    ##------------------------화면 업데이트 ------------------------------
                    
        
        screen.blit(me,(0,0))
        

        pygame.display.flip()  # 화면 전체를 업데이트
        clock.tick(TARGET_FPS)  # 프레임 수 맞추기

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break


cap.release()
cv2.destroyAllWindows()
pygame.quit()
sys.exit()
