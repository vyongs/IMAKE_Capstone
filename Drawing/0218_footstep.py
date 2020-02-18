import sys
import pygame

pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()

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

flower=pygame.image.load('flower.png')
flower_size=50
flower = pygame.transform.scale(flower, (flower_size, flower_size))
flag=0

paints_size=80
paints_y=pygame.transform.scale(imgRoad('paints_y'),(paints_size,paints_size))
paints_g=pygame.transform.scale(imgRoad('paints_g'),(paints_size,paints_size))
paints_s=pygame.transform.scale(imgRoad('paints_s'),(paints_size,paints_size))
paints_p=pygame.transform.scale(imgRoad('paints_p'),(paints_size,paints_size))

mousepos=[]
colors=[]
animals=[]
done=False #done game

color_now=(0,0,0)
animal_now='horse'

#color
YELLOW=(255,255,0)
GREEN=(0,255,0)
SKYBLUE=(23,219,255)
PINK=(255,0,255)


#coordinate
yellow=(50,500)
green=(250,500)
skyblue=(450,500)
pink=(650,500)
eraser=(750,100)

distance=40



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
                animal_now='horse'

    
    screen.fill((0,0,0))
    
    
    mousepos.append(pygame.mouse.get_pos())
    animals.append(animal_now)
    
    if -distance<pos_now[0]-yellow[0]<distance and -distance<pos_now[1]-yellow[1]<distance:
        color_now=YELLOW
    elif -distance<pos_now[0]-green[0]<distance and -distance<pos_now[1]-green[1]<distance:
        color_now=GREEN
    elif -distance<pos_now[0]-skyblue[0]<distance and -distance<pos_now[1]-skyblue[1]<distance:
        color_now=SKYBLUE
    elif -distance<pos_now[0]-pink[0]<distance and -distance<pos_now[1]-pink[1]<distance:
        color_now=PINK
    colors.append(color_now)
    
    if -distance<pos_now[0]-eraser[0]<distance and -distance<pos_now[1]-eraser[1]<distance:
        mousepos.clear()
        colors.clear()
    
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
    screen.blit(paints_y,(yellow[0]-int(paints_size/2),yellow[1]-int(paints_size/2)))
    screen.blit(paints_g,(green[0]-int(paints_size/2),green[1]-int(paints_size/2)))
    screen.blit(paints_s,(skyblue[0]-int(paints_size/2),skyblue[1]-int(paints_size/2)))
    screen.blit(paints_p,(pink[0]-int(paints_size/2),pink[1]-int(paints_size/2)))
    pygame.draw.circle(screen,(255,255,255),eraser,30)

    
    flower = pygame.transform.scale(flower, (flower_size, flower_size))
    screen.blit(flower,(pos_now[0]-int(flower_size/2),pos_now[1]-int(flower_size/2)))
    
    
    pygame.display.update()
    
pygame.quit()
