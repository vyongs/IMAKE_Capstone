##건물 아래에서는 안터지게 해야하는데 뭔가 안돼 ㅠ
# -*- coding: utf-8 -*-
import sys
import pygame
from pygame.locals import *
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

global W
global H

W = 640
H = 480
##W= 800
##H= 600

#-----------------------Ray
class Ray:
    dest_x, dest_y = 0,  0
    x,y = W,H
    color = (0,0,0)
    
    def __init__(self, x,y, color):
        self.dest_x = x
        self.dest_y = y
        self.x = x
        self.y = H
        self.color = color
        self.speed = randint(5,8)

    def check_me(self, mouse):
        return (self.x-10 < mouse[0] <self.x+10) and (self.y - 10 < mouse[1] < self.y+10)  

    def update(self, mouse):
        pygame.draw.line(screen, self.color, (self.x,self.y), (self.x,self.y+40),1)     
        self.y -= self.speed

        self.dest_x = self.x
        self.dext_y = self.y
        
        return (self.x-10 < mouse[0] <self.x+10) and (self.y - 10 < mouse[1] < self.y+10)  

#-------------------------Particle
class Particle:
    def __init__ (self, x, y, vx, vy, color,G):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.G = G
       
    def draw(self):
        pygame.draw.ellipse(screen, self.color, [int(self.x),int(self.y),2,2], 1)
            
    def update(self):
        self.vy += self.G
        self.x += self.vx
        self.y += self.vy

        return self.y > H or self.x < 0 or self.x > W  #|| 연산자
    
#-------------------------Fire making function
def Draw(fire_arr):
    for i in range(len(fire_arr)-1, -1, -1):
        fire_arr[i].update()
        fire_arr[i].draw()
    
#-------------------------Fires    
class Fire_type1:
    ######################
    # bursts_in_a_circle #
    ######################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, 3*math.sin(r), 3*math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(300,500)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y+20, R*math.sin(r), R*math.cos(r), color, 0.17))
            
    def draw(self):
        if (self.count < 50):
            Draw(self.outter)
        
        if ( 50 > self.count > 20):
            Draw(self.inner)

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                self.x = self.ray.dest_x
                self.y = self.ray.dest_y
                self.makeoutter()

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##            print("miss")
            return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
        
        self.y += self.vy

        if self.count == 19: #안쪽 폭죽
            self.makeinner()

        return (self.count==51) #boolean ; 카운트 51되면 true

class Fire_type2:
    ###########################
    # circle and circle burst #
    ###########################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, R*math.sin(r), R*math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(300,500)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y+20, R*math.sin(r), R*math.cos(r), color, 0.17))
            
    def draw(self):
        if (self.count < 50):
            Draw(self.outter)
        
        if ( 50 > self.count > 20):
            Draw(self.inner)

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                self.x = self.ray.dest_x
                self.y = self.ray.dest_y
                self.makeoutter()

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
        
        self.y += self.vy

        if self.count == 19: #안쪽 폭죽
            self.makeinner()

        return (self.count==51) #boolean ; 카운트 51되면 true
            
class Fire_type3:
    #####################
    # 요가파이어 스타일 # ## 레어
    #####################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, randint(2,4)*math.sin(r), randint(2,4)**math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        #self.color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(300,500)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y, R*math.sin(r), R*math.cos(r), self.color, 0.17))
            
    def draw(self):
        if self.count<15:
            self.ray.color = self.color
            self.ray.update(mouse)
        if (self.count < 50):
            Draw(self.outter)
        if (15<self.count<65):
            Draw(self.inner)
        

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                
                self.makeoutter()
                self.color = (randint(50,255),randint(50,255), randint(50,255))
                

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)

        if self.count == 15:
            self.makeinner()
            
        self.y += self.vy
        return (self.count==51) #boolean ; 카운트 51되면 true

class Fire_type4:
    ###############################
    # 외국 장미 아이스크림 스타일 #
    ###############################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, randint(2,4)*math.sin(r), randint(2,4)*math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        #self.color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(150,300)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y, R*math.sin(r)/2, R*math.cos(r)/2, self.color, 0.08))
            
    def draw(self):
        if self.count<15:
            self.ray.color = self.color
        if (self.count < 50):
            Draw(self.outter)
            Draw(self.inner)

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전              
                self.makeoutter()
                self.color = (randint(100,255),randint(100,255),randint(100,255))
                self.makeinner()
            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
            
        return (self.count==51) #boolean ; 카운트 51되면 true

class Fire_type5:
    #########################
    # a circle and a circle #
    #########################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, 3*math.sin(r), 3*math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(300,600)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y+20, 3*math.sin(r), 3*math.cos(r), color, 0.17))
            
    def draw(self):
        if (self.count < 50):
            Draw(self.outter)
        
        if ( 50 > self.count > 20):
            Draw(self.inner)

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                self.x = self.ray.dest_x
                self.y = self.ray.dest_y
                self.makeoutter()

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
        
        self.y += self.vy

        if self.count == 19: #안쪽 폭죽
            self.makeinner()

        return (self.count==51) #boolean ; 카운트 51되면 true

class Fire_type6:
    ##########
    # planet #
    ##########
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(50,200)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x+randint(1,5), self.ray.y+randint(1,2), 7*math.sin(r), 2*math.cos(r) ,self.color, 0.08))
            self.outter.append(Particle(self.ray.x-randint(1,5), self.ray.y+randint(1,2), 7*math.sin(r), 2*math.cos(r) ,self.color, 0.08))
            self.outter.append(Particle(self.ray.x+randint(1,5), self.ray.y-randint(1,2), 7*math.sin(r), 2*math.cos(r) ,self.color, 0.08))
            self.outter.append(Particle(self.ray.x-randint(1,5), self.ray.y-randint(1,2), 7*math.sin(r), 2*math.cos(r) ,self.color, 0.08))

    def makeinner(self):
        color = (randint(50,255),randint(50,255), randint(50,255))
        for i in range (randint(400,600)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.inner.append(Particle(self.ray.x, self.ray.y-5, R*math.sin(r), R*math.cos(r), color, 0.08))
            
    def draw(self):
        if (self.count < 30):
            Draw(self.outter)
            Draw(self.inner)            

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                self.makeoutter()
                self.makeinner()

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
        
        self.y += self.vy

        return (self.count==51) #boolean ; 카운트 51되면 true

class Fire_type7:
    ################
    # basic circle #
    ################
    def __init__ (self, x, y):
        self.x = x
        self.y = y
        self.vy = 0.16
        self.color = (randint(100,255),randint(100,255),randint(100,255))
        self.thickness = randint(1,3)
        
        self.ray = Ray(x,y,self.color)
        self.ray_bool = False

        self.outter = []
        self.inner = []
        self.count = 0
       
    def makeoutter(self):
        for i in range (randint(200,500)):
            r = uniform(0, 2*math.pi) #float
            R = uniform(0, math.pi) #float
            self.outter.append(Particle(self.ray.x, self.ray.y, R*math.sin(r), R*math.cos(r) ,self.color, 0.08))

    def draw(self):
        if (self.count < 30):
            Draw(self.outter)          

    def update(self, mouse):
        
        if self.ray_bool: #마우스에 닿았을 때
            if self.count==0: #바깥쪽 폭죽 생성 전
                self.makeoutter()

            else: #바깥쪽 폭죽 생성 후
                self.draw()
            self.count += 1
                
        elif ( self.ray.y < 0 ): # 터치하지 못하고 지나가 없어졌을 경우
##                print("miss")
                return True #boolean
            
        else: #마우스에 아직 안 닿았을 때
            self.ray_bool = self.ray.update(mouse)
        
        self.y += self.vy

        return (self.count==51) #boolean ; 카운트 51되면 true

def random_Fire():
    random = randint(1,7)
    if random == 1:
        temp = Fire_type1(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 2:
        temp = Fire_type2(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 3:
        temp = Fire_type3(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 4:
        temp = Fire_type4(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 5:
        temp = Fire_type5(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 6:
        temp = Fire_type6(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
    elif random == 7:
        temp = Fire_type7(randint(50,W-50), randint(50,H)) #init <-- x,y,qty
        fires.append(temp)
#--------------------main
TARGET_FPS = 20
clock = pygame.time.Clock()

display = (W, H)
screen = pygame.display.set_mode(display, DOUBLEBUF )

fires = []
pygame.init()
num = 0
##Background image for showing
bgimage = pygame.image.load('background.png').convert_alpha()
bgimage = pygame.transform.scale(bgimage, (W,H))

##Background image array for checking firework
bg = cv2.imread('background.png')
src = cv2.resize(bg, dsize=(W,H), interpolation = cv2.INTER_AREA)
temp = np.rot90(src)
src=np.flipud(temp)

arc = cv2.Canny(src, 40, 45)
arc_x = np.where(arc==255)[0]
arc_y = np.where(arc==255)[1]

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

while True:
    
    while runned == False:
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
            print("done")
            thresh_done=True
            
    if runned == False:
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        background_img = cv2.GaussianBlur(background_img, (5,5),0)
        runned = True
        
    elif runned == True and thresh_done==True:

        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        this_img = cv2.GaussianBlur(this_img, (5,5),0)      
        abdiff = cv2.absdiff(this_img, background_img)
        thresh = cv2.getTrackbarPos("Threshold","panel")
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        
        kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        opening = cv2.morphologyEx(thresh_img, cv2.MORPH_OPEN, kernel2, 3)
        border = cv2.dilate(opening, kernel2, iterations=3)
        border = border - cv2.erode(border, None)

        temp = np.rot90(border)
        temp = np.flipud(temp)
        exists = np.where(temp == 255)

        temp = np.rot90(thresh_img)        
        mask = np.flipud(temp)
        me = pygame.surfarray.make_surface(mask).convert()
        me.set_alpha(100)
        
        if (len(fires) < 6) :
            random_Fire()
            
        screen.fill(BLACK)  # 화면을 검은색으로 지운다
        screen.blit(me,(0,0))
        
        for i in range(len(fires)-1, -1, -1):
            f = fires[i]
            me_done=False
            m_x = f.ray.x
            m_y =  f.ray.y
            inside = np.where(arc_x == m_x)[0]  #여기수정필요...
            if len(inside) > 0:
                out = min(inside)
                if m_y > arc_y[out]:
                    if f.update([0,0]):
                        del(fires[i])
                        me_done=True
                    continue
                else:
                    if len(exists[0]) > 0:
                        for k in range(len(exists[0])):
                            mouse=[exists[0][k],exists[1][k]]
                            if f.ray.check_me(mouse) and not me_done:
                                me_done = True
                                break
                        if f.update(mouse):
                            del(fires[i])
                            
                    else:
                        if f.update([0,0]):
                            del(fires[i])
                            me_done=True
            else:
                if len(exists[0]) > 0:
                    for k in range(len(exists[0])):
                        mouse=[exists[0][k],exists[1][k]]
                        if f.ray.check_me(mouse) and not me_done:
                            me_done = True
                            break
                    if f.update(mouse):
                        del(fires[i])
                            
                else:
                    if f.update([0,0]):
                        del(fires[i])
                        me_done=True
                                    
        screen.blit(bgimage,(0,0))
##        test_bg = pygame.surfarray.make_surface(arc).convert()
##        test_bg.set_alpha(100)
##        screen.blit(test_bg,(0,0))
        
        pygame.display.flip()  # 화면 전체를 업데이트
        clock.tick(TARGET_FPS)  # 프레임 수 맞추기

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
pygame.quit()
sys.exit()
