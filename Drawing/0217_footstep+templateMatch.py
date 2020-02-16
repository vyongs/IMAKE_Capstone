import sys
import pygame
import template_match as detect
import cv2 as cv

# get camera connection
cap = cv.VideoCapture(0)

# pygame setting
pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()

# variable setting
mousepos=[]
colors=[]
done=False #done game

# color setting
color_now=(0,0,0)
blue=(100,500)
green=(300,500)
red=(500,500)
black=(700,500)
eraser=(700,100)

# mouse point setting
prev_point = (60, 60)
curr_point = (60, 60)


while not done:
    clock.tick(10)
    for event in pygame.event.get(): 
        # close game
        if event.type == pygame.QUIT:  
            done = True    

    
    screen.fill((255,255,255))

    prev_point = curr_point

    # get hand point from video
    ret,img = cap.read()
      
    if ret == False:
        continue

    points = detect.vyongs_detect('circle.png', 0.5,  255,0,0,"head",(300,100),img)

    cv.imshow('result', img)
    if type(points) is tuple:
        curr_point = points

    if prev_point != curr_point:
        mouse_pos = curr_point
    else:
        mouse_pos = prev_point
        
    mousepos.append(mouse_pos)

    # detect if point is near paint pallets    
    if -10<mouse_pos[0]-blue[0]<10 and -10<mouse_pos[1]-blue[1]<10:
        color_now=(0,0,255)
    elif -10<mouse_pos[0]-green[0]<10 and -10<mouse_pos[1]-green[1]<10:
        color_now=(0,255,0)
    elif -10<mouse_pos[0]-red[0]<10 and -10<mouse_pos[1]-red[1]<10:
        color_now=(255,0,0)
    elif -10<mouse_pos[0]-black[0]<10 and -10<mouse_pos[1]-black[1]<10:
        color_now=(0,0,0)
    colors.append(color_now)
    if -10<mouse_pos[0]-eraser[0]<10 and -10<pmouse_pos[1]-eraser[1]<10:
        mousepos.clear()
        colors.clear()
    
    for i in range(len(mousepos)):
        pygame.draw.circle(screen,colors[i],mousepos[i],5)
    
    pygame.draw.circle(screen,(0,0,255),blue,10)
    pygame.draw.circle(screen,(0,255,0),green,10)
    pygame.draw.circle(screen,(255,0,0),red,10)
    pygame.draw.circle(screen,(0,0,0),black,10)
    pygame.draw.circle(screen,(0,0,0),eraser,10,2)
    
    pygame.display.update()

cap.release()
cv.destroyAllWindows()
pygame.quit()  
