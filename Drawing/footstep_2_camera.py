import sys
import pygame
import _0217_template_match as detect
import cv2 as cv

cap = cv.VideoCapture(0)

pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()


#def bucket_up():


#def bucket_fall():
    
def check_collision(pos,pos_now,distance):
    if -distance<pos_now[0]-pos[0]<distance and -distance<pos_now[1]-pos[1]<distance:
        return True
    else:
        return False

def check_spill(bucket_1,bucket_2,paints,spill,bucket,size,color):
    if spill==0:
        screen.blit(bucket_1,(bucket[0]-int(size/2),bucket[1]-int(size/2)))
    else:
        screen.blit(paints,(color[0]-int(size/2),color[1]-int(size/2)))
        screen.blit(bucket_2,(bucket[0]-int(size/2),bucket[1]-int(size/2)))
        spill+=1
        if spill==20:
            spill=0

def imgRoad(name):
    return pygame.image.load(name+'.png')

def drawObject(animal,color,XY):
    if color==YELLOW:
        screen.blit(imgRoad(animal+'_y'), XY)
    elif color==GREEN:
        screen.blit(imgRoad(animal+'_g'), XY)
    elif color==SKYBLUE:
        screen.blit(imgRoad(animal+'_s'), XY)
    elif color==PINK:
        screen.blit(imgRoad(animal+'_p'), XY)
    elif color=='NONE':
        screen.blit(imgRoad('nothing'),XY)

flower=pygame.image.load('flower.png')
flower_size=50
flower = pygame.transform.scale(flower, (flower_size, flower_size))
flag=0

paints_size=80
paints_y=pygame.transform.scale(imgRoad('paints_y'),(paints_size,paints_size))
paints_g=pygame.transform.scale(imgRoad('paints_g'),(paints_size,paints_size))
paints_s=pygame.transform.scale(imgRoad('paints_s'),(paints_size,paints_size))
paints_p=pygame.transform.scale(imgRoad('paints_p'),(paints_size,paints_size))

bucket_1=pygame.transform.scale(imgRoad('bucket_1'),(paints_size,paints_size))
bucket_2=pygame.transform.scale(imgRoad('bucket_2'),(paints_size,paints_size))

mousepos=[]
colors=[]
animals=[]
done=False #done game

color_now=(0,0,0)
animal_now='horse'

#spill time
spill_y=0
spill_g=0
spill_s=0
spill_p=0

#paint time
time=0

#color
YELLOW=(255,255,0)
GREEN=(0,255,0)
SKYBLUE=(23,219,255)
PINK=(255,0,255)


#coordinate
bucket_y=(150,100)
yellow=(220,100)
bucket_g=(100,300)
green=(170,300)
bucket_s=(380,500)
skyblue=(450,500)
pink=(650,500)
bucket_p=(580,500)
eraser=(750,100)

distance=40

#camera
pos_prev = (60, 60)
pos_now = (60, 60)

while not done:
    clock.tick(10)
    if flag==0:
        flower_size-=5
        if flower_size==10:
            flag=1
    else:
        flower_size+=5
        if flower_size==50:
            flag=0
    
    pos_now=pygame.mouse.get_pos()
    
    for event in pygame.event.get(): 
        if event.type == pygame.QUIT:  
            done = True
            
        #마우스 클릭시 동물이 바뀜
        elif event.type== pygame.MOUSEBUTTONDOWN:
            if animal_now=='horse':
                animal_now='cat'
            elif animal_now=='cat':
                animal_now='bird'
            elif animal_now=='bird':
                animal_now='horse'

    
    screen.fill((0,0,0))
    
    pos_prev = pos_now
    # get hand point from video
    ret,img = cap.read()
      
    if ret == False:
        continue
    
    points = detect.vyongs_detect('circle.jpg', 0.5,  255,0,0,"head",(300,100),img)

    cv.imshow('result', img)
    # if person head is found
    if type(points) is tuple:
        pos_now = points

    if pos_prev != pos_now:
        mouse_pos = pos_now
    else:
        mouse_pos = pos_prev
    
    mousepos.append(mouse_pos)
    #mousepos.append(pygame.mouse.get_pos())
    animals.append(animal_now)
    
    if check_collision(yellow,pos_now,distance):
        if spill_y!=0:
            color_now=YELLOW
            time=1
    elif check_collision(green,pos_now,distance):
        if spill_g!=0:
            color_now=GREEN
            time=1
    elif check_collision(skyblue,pos_now,distance):
        if spill_s!=0:
            color_now=SKYBLUE
            time=1
    elif check_collision(pink,pos_now,distance):
        if spill_p!=0:
            color_now=PINK
            time=1
    colors.append(color_now)

    if time>0:
        time+=1
        if time==20:
            color_now='NONE'
            time=0
    
    if -distance<pos_now[0]-eraser[0]<distance and -distance<pos_now[1]-eraser[1]<distance:
        mousepos.clear()
        colors.clear()
        animals.clear()
    
    for i in range(len(mousepos)):
        #pygame.draw.circle(screen,colors[i],mousepos[i],5)
        drawObject(animals[i],colors[i],mousepos[i])
        

    #pygame.draw.rect(screen, (85,139,192), [0, 500, 800, 100])
    #pygame.draw.rect(screen, (85,139,192), [700, 0, 100, 600])
    '''
    pygame.draw.circle(screen,(0,0,255),blue,30)
    pygame.draw.circle(screen,(0,255,0),green,30)
    pygame.draw.circle(screen,(255,0,0),red,30)
    pygame.draw.circle(screen,(0,0,0),black,30)
    pygame.draw.circle(screen,(0,0,0),eraser,30,2)
    '''
    
    
    if spill_y==0:
        screen.blit(bucket_1,(bucket_y[0]-int(paints_size/2),bucket_y[1]-int(paints_size/2)))
    else:
        screen.blit(paints_y,(yellow[0]-int(paints_size/2),yellow[1]-int(paints_size/2)))
        screen.blit(bucket_2,(bucket_y[0]-int(paints_size/2),bucket_y[1]-int(paints_size/2)))
        spill_y+=1
        if spill_y==20:
            spill_y=0

    if spill_g==0:
        screen.blit(bucket_1,(bucket_g[0]-int(paints_size/2),bucket_g[1]-int(paints_size/2)))
    else:
        screen.blit(paints_g,(green[0]-int(paints_size/2),green[1]-int(paints_size/2)))
        screen.blit(bucket_2,(bucket_g[0]-int(paints_size/2),bucket_g[1]-int(paints_size/2)))
        spill_g+=1
        if spill_g==20:
            spill_g=0

    if spill_s==0:
        screen.blit(bucket_1,(bucket_s[0]-int(paints_size/2),bucket_s[1]-int(paints_size/2)))
    else:
        screen.blit(paints_s,(skyblue[0]-int(paints_size/2),skyblue[1]-int(paints_size/2)))
        screen.blit(bucket_2,(bucket_s[0]-int(paints_size/2),bucket_s[1]-int(paints_size/2)))
        spill_s+=1
        if spill_s==20:
            spill_s=0

    if spill_p==0:
        screen.blit(bucket_1,(bucket_p[0]-int(paints_size/2),bucket_p[1]-int(paints_size/2)))
    else:
        screen.blit(paints_p,(pink[0]-int(paints_size/2),pink[1]-int(paints_size/2)))
        screen.blit(bucket_2,(bucket_p[0]-int(paints_size/2),bucket_p[1]-int(paints_size/2)))
        spill_p+=1
        if spill_p==20:
            spill_p=0
    

    pygame.draw.circle(screen,(255,255,255),eraser,30)


    
    if check_collision(bucket_y,pos_now,distance):
        spill_y+=1
    elif check_collision(bucket_g,pos_now,distance):
        spill_g+=1
    elif check_collision(bucket_s,pos_now,distance):
        spill_s+=1
    elif check_collision(bucket_p,pos_now,distance):
        spill_p+=1
    
    '''
    screen.blit(paints_g,(green[0]-int(paints_size/2),green[1]-int(paints_size/2)))
    screen.blit(paints_s,(skyblue[0]-int(paints_size/2),skyblue[1]-int(paints_size/2)))
    screen.blit(paints_p,(pink[0]-int(paints_size/2),pink[1]-int(paints_size/2)))
    pygame.draw.circle(screen,(255,255,255),eraser,30)
    '''
    
    flower = pygame.transform.scale(flower, (flower_size, flower_size))
    screen.blit(flower,(pos_now[0]-int(flower_size/2),pos_now[1]-int(flower_size/2)))
    
    pygame.display.update()
    
pygame.quit()
