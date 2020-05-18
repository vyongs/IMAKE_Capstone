import sys
import pygame
from pygame.locals import *
from pygame.display import *
from OpenGL.GL import *
from OpenGL.GLU import *
from random import *
import math
import cv2
import numpy as np
import clock

global W
W= 640
global H
H= 480
display = (W, H)
screen = pygame.display.set_mode(display, DOUBLEBUF )
pygame.init()
pygame.mixer.init()

sound = pygame.mixer.Sound("gig.wav")
sound2 = pygame.mixer.Sound("gig.wav")
chan1 = pygame.mixer.Channel(0)
chan2 = pygame.mixer.Channel(1)

# set channel to max
chan1.set_volume(1, 0)    #0~1사이의 max 값 지정(0~1인지는 잘 모르겠음)
chan2.set_volume(0, 0)

# set sound to initial value
sound.set_volume(0)
sound2.set_volume(0) 

chan1.play(sound, 50, 0, 0)
chan2.play(sound2, 50, 0, 0)
i=0

while True:
    clock.tick(10)
    volRight=1
    volLeft = 1 - 0.1*i
    sound.set_volume(volLeft)
    sound2.set_volume(volRight)
    i = i+1
    if i>10:
        break

##sound0 = pygame.mixer.Sound("gig.wav")
##channel0 = pygame.mixer.Channel(0)
##channel0.play(sound0)
##channel0.set_volume(1,0)
##sound0.play(-1)

