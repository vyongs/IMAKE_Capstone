import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt
import math
from PIL import Image
from scipy import ndimage
import pygame

# for calculating new location for footstep
LEFT = 0
DISTANCE = 6
LOWEST_DIST = 2
#DIST_SLOPE = (LOWEST_DIST/DISTANCE)**(-1/90)
DIST_SLOPE = 1.8

# load footstep imgs in cv2
animal_init = ['horse','bird', 'cat']
footstep = { }
for i in animal_init:
    footstep[i+'_y']=Image.open(i+'_y.png')
    footstep[i+'_g']=Image.open(i+'_g.png')
    footstep[i+'_s']=Image.open(i+'_s.png')
    footstep[i+'_p']=Image.open(i+'_p.png')

user = (0,0) #initial point of user

# detect where user is and return (x, y)
def jay_detect(background_img, frame):
    this_img = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
    this_img = cv.GaussianBlur(this_img, (5,5),0)      
    abdiff = cv.absdiff(this_img, background_img)
    thresh = cv.getTrackbarPos("Threshold","panel")
    _, thresh_img = cv.threshold(abdiff, thresh, 255, cv.THRESH_BINARY)

    temp = np.rot90(thresh_img)        
    mask = np.flipud(temp)
    
    center_point = ndimage.measurements.center_of_mass(mask) # get center of border

    try:
        user = (int(center_point[0]),int(center_point[1])) # make (x,y) into int value
        print(user)
    except:     
        user =(0,0)
    
    return user


# calc angle and new location for foot
def calc_angle(pos1,pos2, cnt):
    foot = cnt % 2
    angle= 0
    diff_x= pos2[0]-pos1[0]
    diff_y= pos2[1]-pos1[1]

    if abs(diff_x) < 8:
        if diff_y < 0: # up
            angle = 0
            if foot is LEFT:
                new_pos = (pos2[0]-DISTANCE, pos2[1])
            else:
                new_pos = (pos2[0]+DISTANCE, pos2[1])
        else:          # down
            angle = 180
            if foot is LEFT:
                new_pos = (pos2[0]+DISTANCE, pos2[1])
            else:
                new_pos = (pos2[0]-DISTANCE, pos2[1])
                
    elif abs(diff_y) < 8:
        if diff_x < 0: # right 
            angle = 90
            if foot is LEFT:
                new_pos = (pos2[0], pos2[1] - DISTANCE)
            else:
                new_pos = (pos2[0], pos2[1] + DISTANCE)
        else:          # left
            angle = -90
            if foot is LEFT:
                new_pos = (pos2[0], pos2[1] + DISTANCE)
            else:
                new_pos = (pos2[0], pos2[1] - DISTANCE)
    else:
        try:
            slope = (diff_y)/(diff_x)
            c = (diff_x/diff_y)*pos2[0]+pos2[1] # y = -slope*x + c
        except:
            angle = 0
            new_pos = (0,0)
        else:
            angle = math.degrees(math.atan(slope))
            dist = DISTANCE*DIST_SLOPE**(-abs(angle))
            print("angle: ", angle, "dist: ", dist)
            
            if slope < 0:
                if diff_y > 0: # 3rd quadrant
                    angle += 180
                    if foot is LEFT:
                        x = pos2[0]+dist
                    else:
                        x = pos2[0]-dist
                else:          # 1st quadrant
                    if foot is LEFT:
                        x = pos2[0]-dist
                    else:
                        x = pos2[0]+dist
                
            else:
                if diff_x > 0: # 4th quadrant
                    angle += 180
                    if foot is LEFT:
                        x = pos2[0]+dist
                    else:
                        x = pos2[0]-dist
                else:          # 1st quadrant
                    if foot is LEFT:
                        x = pos2[0]-dist
                    else:
                        x = pos2[0]+dist
                           
            new_pos = (x, -slope*x+c)
                    
    return angle, new_pos
    

def rotate_img(animal, angle):
    img_RGBA = footstep[animal].convert('RGBA')

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
