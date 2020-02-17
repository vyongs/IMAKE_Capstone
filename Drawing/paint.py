import sys
import pygame

pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()

flower=pygame.image.load('flower.png')
flower_size=50
flower = pygame.transform.scale(flower, (flower_size, flower_size))
flag=0

mousepos=[]
colors=[]
done=False #done game

color_now=(0,0,0)

blue=(50,550)
green=(250,550)
red=(450,550)
black=(650,550)
eraser=(750,100)

distance=30

while not done:
    clock.tick(200)
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

    
    screen.fill((255,255,255))
    
    
    mousepos.append(pygame.mouse.get_pos())
    
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
    
    for i in range(len(mousepos)):
        pygame.draw.circle(screen,colors[i],mousepos[i],5)

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
    
pygame.quit()
