import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt
import math
from PIL import Image
from scipy import ndimage
import pygame

#methods = ['cv2.TM_CCOEFF','cv2.TM_CCOEFF_NORMED','cv2.TM_CCORR','cv2.TM_CCORR_NORMED','cv2.TM_SQDIFF','cv2.TM_SQDIFF_NORMED']
method = 'TM_CCOEFF_NORMED'

# load footstep imgs in cv2
animal_init = ['horse','bird', 'cat']
footstep = { }
for i in animal_init:
    footstep[i+'_y']=Image.open('sprites/'+i+'_y.png')
    footstep[i+'_g']=Image.open('sprites/'+i+'_g.png')
    footstep[i+'_s']=Image.open('sprites/'+i+'_s.png')
    footstep[i+'_p']=Image.open('sprites/'+i+'_p.png')

user = (0,0) #initial point of user


def hough_detect(frame):
    gray = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
    gray = cv.medianBlur(gray,5)
    
    circles = cv.HoughCircles(gray,cv.HOUGH_GRADIENT,1,80,param1=50,param2=35,minRadius=0,maxRadius=70)
    center = None
    
    if circles is not None:
        for c in circles[0,:]:
            #if frame[int(c[1]),int(c[0])][0]<50 and frame[int(c[1]),int(c[0])][1]<50 and frame[int(c[1]),int(c[0])][2]<50:
            center = (c[0],c[1])
            radius = c[2]
    
            # 바깥원
            cv.circle(frame,center,radius,(0,255,0),2)
        
            # 중심원
            cv.circle(frame,center,2,(0,0,255),3)
        
        
    cv.imshow("real-time video", frame)
    
    return center


def rotate_img(animal, pos1, pos2):            
    img_RGBA = footstep[animal].convert('RGBA')

    
    diff_x= pos2[0]-pos1[0]
    diff_y= pos2[1]-pos1[1]

    if abs(diff_x) < 8:
        if diff_y < 0:
            angle = 0
        else:
            angle = 180
    elif abs(diff_y) < 8:
        if diff_x < 0:
            angle = 90
        else:
            angle = -90
    else:
        try:
            pos = (diff_y)/(diff_x)
        except:
            angle = 0
        else:
            angle = math.degrees(math.atan(pos))
            
            if pos < 0:
                if diff_y > 0:
                    angle += 180
            else:
                if diff_x > 0:
                    angle += 180


    result = img_RGBA.rotate(angle,expand=1)

    mode = result.mode
    size = result.size
    data = result.tobytes()

    #print(angle)
    result = pygame.image.fromstring(data,size,mode)
    return result
    
global R,flag,XY,touch,touch2,flag1,flag2,r1,r2,limit
R=30
flag=0
XY=[(0,0),(0,0),(0,0),(0,0),(0,0),(0,0),(0,0)]
touch=(400,300)
touch2=(200,300)
flag1=0
flag2=0
r1=20
r2=20
limit=20 #얼마나 가까이가면 인식할지

cv.destroyAllWindows()
