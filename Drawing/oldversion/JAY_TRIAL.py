import sys
import pygame
from pygame.locals import *
#from OpenGL.GL import *
#from OpenGL.GLU import *
from random import *
import math
import cv2
import numpy as np
from scipy import ndimage

#색 정의
BLACK= (0,0,0) #R G B
RED = (255, 0, 0)
GREEN = (255,0, 255)
BLUE = (0, 0, 255)
ORANGE = (255,180,0)
YELLOW = (255,255,0)
YELLOW_A = (255,255,0, 80)
BLUE_A = (0, 0, 255, 127)  # R, G, B, Alpha(투명도, 255 : 완전 불투명)

#--------------------main
TARGET_FPS = 20
clock = pygame.time.Clock()
done = False

#W = 320
#H = 240
W= 640
H= 480
display = (W, H)
user=(0,0)
screen = pygame.display.set_mode(display, DOUBLEBUF )

pygame.init()
num = 0

################################CAMERA########################
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH,W)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT,H)
fgbg = cv2.createBackgroundSubtractorMOG2(varThreshold=200, detectShadows=False)

runned = False

def nothing(x):
    pass

cv2.namedWindow("panel", cv2.WINDOW_NORMAL)
cv2.createTrackbar("Threshold","panel", 0, 255, nothing)
cv2.resizeWindow("panel", 7, 100)

thresh_done=False
################################################################

while not done:
    for event in pygame.event.get(): 
        if event.type == pygame.QUIT:  
            done = True
    
    while runned == False: # capture bg
        ret, frame = cap.read()
        cv2.imshow("original", frame)
        if cv2.waitKey(1) & 0xFF == ord('s'):
            break
        
    ret, frame = cap.read()
    
    if thresh_done==False and runned == True:
        
        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)      
        abdiff = cv2.absdiff(this_img, background_img)
        thresh = cv2.getTrackbarPos("Threshold","panel")
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        cv2.imshow("threshimg",thresh_img)        
        if cv2.waitKey(1) & 0xFF == ord('d'):
            print("---------THRESH DONE-----------")
            thresh_done=True
            
    if runned == False: # make bg into gray and blur the photo
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        background_img = cv2.GaussianBlur(background_img, (5,5),0)
        runned = True
        
    elif runned == True and thresh_done==True:

        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)      
        abdiff = cv2.absdiff(this_img, background_img)
        thresh = cv2.getTrackbarPos("Threshold","panel")
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        
        kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)) # array of 1s in circle shape
        opening = cv2.morphologyEx(thresh_img, cv2.MORPH_OPEN, kernel2, 3) # remove noise
        border = cv2.dilate(opening, kernel2, iterations=3) # increases area (join broken parts)
        # find the border of user
        border = border - cv2.erode(border, None) # erode: decrease area
        
        
        temp = np.rot90(border) 
        temp = np.flipud(temp)
        exists = np.where(temp == 255)
        
        temp = np.rot90(thresh_img)        
        mask = np.flipud(temp)
        me = pygame.surfarray.make_surface(mask).convert()
        me.set_alpha(100)

        center_point = ndimage.measurements.center_of_mass(mask) # get center of border

        try:
            user = (int(center_point[0]),int(center_point[1])) # make (x,y) into int value
            print(user)
        except:
            pass
        
        screen.fill(BLACK)  # 화면을 검은색으로 지운다
        screen.blit(me,(0,0))
        pygame.draw.circle(screen, (0,0,255), user, 15, 10)


        pygame.display.flip()  # 화면 전체를 업데이트
        clock.tick(TARGET_FPS)  # 프레임 수 맞추기


        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
pygame.quit()
sys.exit()
