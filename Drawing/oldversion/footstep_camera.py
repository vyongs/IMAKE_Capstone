import sys
import pygame
import _0217_template_match as detect
import cv2 as cv

cap = cv.VideoCapture(0)

pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()

# img to indicate where user is standing
flower=pygame.image.load('flower.png')
flower_size=50
flower = pygame.transform.scale(flower, (flower_size, flower_size))
flag=0

mousepos=[]
colors=[]
done=False #done game

# color setting
color_now=(0,0,0)
blue=(50,550)
green=(250,550)
red=(450,550)
black=(650,550)
eraser=(750,100)

distance=30

pos_prev = (60, 60)
pos_now = (60, 60)

    
while not done:
    clock.tick(30)

    # resizing flower depending on flag
    if flag==0:
        flower_size-=5
        if flower_size==10:
            flag=1
    else:
        flower_size+=5
        if flower_size==50:
            flag=0

    for event in pygame.event.get(): 
        if event.type == pygame.QUIT:  
            done = True    

    # create white background    
    screen.fill((255,255,255))

    pos_prev = pos_now
    # get hand point from video
    ret,img = cap.read()
      
    if ret == False:
        continue
    
    points = detect.vyongs_detect('circle.png', 0.5,  255,0,0,"head",(300,100),img)

    cv.imshow('result', img)
    # if person head is found
    if type(points) is tuple:
        pos_now = points

    if pos_prev != pos_now:
        mouse_pos = pos_now
    else:
        mouse_pos = pos_prev
    
    mousepos.append(mouse_pos)
    
    if -distance<pos_now[0]-blue[0]<distance and -distance<pos_now[1]-blue[1]<distance:
        color_now=(0,0,255)
    elif -distance<pos_now[0]-green[0]<distance and -distance<pos_now[1]-green[1]<distance:
        color_now=(0,255,0)
    elif -distance<pos_now[0]-red[0]<distance and -distance<pos_now[1]-red[1]<distance:
        color_now=(255,0,0)
    elif -distance<pos_now[0]-black[0]<distance and -distance<pos_now[1]-black[1]<distance:
        color_now=(0,0,0)
    colors.append(color_now)
    
    if -distance<pos_now[0]-eraser[0]<distance and -distance<pos_now[1]-eraser[1]<distance:
        mousepos.clear()
        colors.clear()
    
    for i in range(len(mousepos)-1):
        #pygame.draw.circle(screen,colors[i],mousepos[i],5)
        pygame.draw.line(screen, colors[i], mousepos[i],mousepos[i+1], 2)

    pygame.draw.rect(screen, (85,139,192), [0, 500, 800, 100])
    pygame.draw.rect(screen, (85,139,192), [700, 0, 100, 600])
    
    pygame.draw.circle(screen,(0,0,255),blue,30)
    pygame.draw.circle(screen,(0,255,0),green,30)
    pygame.draw.circle(screen,(255,0,0),red,30)
    pygame.draw.circle(screen,(0,0,0),black,30)
    pygame.draw.circle(screen,(0,0,0),eraser,30,2)

    
    flower = pygame.transform.scale(flower, (flower_size, flower_size))
    screen.blit(flower,(pos_now[0]-int(flower_size/2),pos_now[1]-int(flower_size/2)))
    
    
    pygame.display.update()

cap.release()
cv.destroyAllWindows()
pygame.quit()
