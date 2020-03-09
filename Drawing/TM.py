import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt
import math
from PIL import Image
import pygame

cap = cv.VideoCapture(0)

#methods = ['cv2.TM_CCOEFF','cv2.TM_CCOEFF_NORMED','cv2.TM_CCORR','cv2.TM_CCORR_NORMED','cv2.TM_SQDIFF','cv2.TM_SQDIFF_NORMED']
method = 'TM_CCOEFF_NORMED'

# load footstep imgs in cv2
animal_init = ['horse','bird', 'cat']
footstep = { }
for i in animal_init:
    footstep[i+'_y']=Image.open(i+'_y.png')
    footstep[i+'_g']=Image.open(i+'_g.png')
    footstep[i+'_s']=Image.open(i+'_s.png')
    footstep[i+'_p']=Image.open(i+'_p.png')

def vyongs_detect(template_file_name, threshold, b,g,r,area,point,img):
    global R,flag,XY,touch,touch2,flag1,flag2,r1,r2,limit

    img_gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
    #img_gray=cv.multiply(flower,img_gray)
    
    for i in range(5,-1,-1):
        XY[i+1]=XY[i] #이전좌표 저장
    
    template = cv.imread(template_file_name,0)
    w, h = template.shape[::-1]
    
    res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
    min_val,max_val,min_loc, max_loc = cv.minMaxLoc(res)
    
    if method in [cv.TM_SQDIFF, cv.TM_SQDIFF_NORMED]:
        top_left = min_loc
    else:
        top_left = max_loc

    if max_val >= threshold:
        #print(max_val)
        bottom_right = (top_left[0]+w,top_left[1]+h)
        x=int(top_left[0]+w/2)
        y=int(top_left[1]+h/2)
        XY[0]=(x,y)

        if touch[0]-limit<x<touch[0]+limit and touch[1]-limit<y<touch[1]+limit:
            flag1=1
        if touch2[0]-limit<x<touch2[0]+limit and touch2[1]-limit<y<touch2[1]+limit:
            flag2=1

        cv.circle(img,(XY[6]),R,(211,0,148),-1)#
        cv.circle(img,(XY[5]),R,(130,0,75),-1)#남
        cv.circle(img,(XY[4]),R,(255,0,0),-1)#파
        cv.circle(img,(XY[3]),R,(0,255,0),-1)#초
        cv.circle(img,(XY[2]),R,(0,255,255),-1)#노
        cv.circle(img,(XY[1]),R,(0,127,255),-1) #주
        cv.circle(img,(XY[0]),R,(0,0,255),-1) #빨
        #cv.rectangle(img_rgb,top_left,bottom_right,(b,g,r),2)
        #cv.putText(img_rgb,str(int(round(max_val,2)*100))+'%', top_left,0, 0.5, (b,g,r))
        
        
        if flag==0: #커졌다 작아지게
            R+=1
            if R==50:
                flag=1
        else:
            R-=1
            if R==30:
                flag=0
            
        
        return (x,y)

def rotate_img(animal, pos1, pos2):
    img_RGBA = footstep[animal].convert('RGBA')
    
    diff_x= pos2[0]-pos1[0]
    diff_y= pos2[1]-pos1[1]

    if abs(diff_x) < 7:
        if diff_y < 0:
            angle = 0
        else:
            angle = 180
    elif abs(diff_y) < 7:
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
    
flower=cv.imread('flower.png')
    
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
