# -*- coding: utf-8 -*-
"""
Created on Tue Feb 11 14:32:51 2020

@author: lenovo
"""
import numpy as np
import cv2
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage, AnnotationBbox


hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

cv2.startWindowThread()


cap = cv2.VideoCapture(1)
cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH,320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT,240)
runned = False
panel = np.zeros([10,700,1],np.uint8)
cv2.namedWindow("panel")
def nothing(x):
    pass

cv2.createTrackbar("Threshold","panel", 0, 255, nothing)


count=0
roseimg = cv2.imread('rose.png',cv2.IMREAD_UNCHANGED)
imgs=list()
for idx in range(5,61):
    img = cv2.imread("rose_resized"+str(idx)+".png",cv2.IMREAD_UNCHANGED)
    alpha = img[:,:,3]
    roseimg = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
    roseimg = np.dstack([roseimg, alpha])
    imgs.append(roseimg)
    
##alpha = roseimg[:,:,3]
##roseimg = cv2.cvtColor(roseimg,cv2.COLOR_BGR2RGB)
##roseimg = np.dstack([roseimg,alpha])

# Create rain data
n_drops = 6
rain_drops = np.zeros(n_drops, dtype=[('position', float, 2),
                                      ('size',     float, 1),
                                      ('growth',   float, 1),
                                      ('color',    float, 4)])

# Initialize the raindrops in random positions and with
# random growth rates.
rain_drops['position'] = np.random.uniform(0, 1, (n_drops, 2))
rain_drops['growth'] = np.random.uniform(1, 5, n_drops)
print(rain_drops)

while(1):
    count = count+1
    
    ##To avoid background selection failure caused by auto focusing
    while (1 and runned==False):
        ret, frame = cap.read()
        cv2.imshow("original", frame)
        if cv2.waitKey(1) & 0xFF == ord('s'):
            break
    ############################################################
    ret, frame = cap.read()

    if runned == False:
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        background_img = cv2.GaussianBlur(background_img, (5,5),0)
        runned=True
    else:
        fig = plt.figure(figsize=(3.2,2.4))
        ax = fig.add_axes([0, 0, 1, 1], frameon=False)
        ax.set_xlim(0, 1), ax.set_xticks([])
        ax.set_ylim(0, 1), ax.set_yticks([])


        this_img = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        boxes, weights = hog.detectMultiScale(this_img, winStride=(8,8) )

        boxes = np.array([[x, y, x + w, y + h] for (x, y, w, h) in boxes])
    
        for (xA, yA, xB, yB) in boxes:
            cv2.rectangle(frame, (xA, yA), (xB, yB),
                              (0, 255, 0), 2)
        
        
        thresh = cv2.getTrackbarPos("Threshold","panel")
        this_img = cv2.GaussianBlur(this_img, (5,5),0)
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
                        
        abdiff = cv2.absdiff(this_img, background_img)
        #현재 이미지와 이전 이미지의 차이를 절댓값으로 구함 -> 같으면 0 다르면 값 존재
#        abdiff = cv2.morphologyEx(abdiff, cv2.MORPH_CLOSE, kernel, 2)
        #noise 제거...
        _, thresh_img = cv2.threshold(abdiff, thresh, 255, cv2.THRESH_BINARY)
        #thresh 보다 크면 255 아님 0
        
        color = cv2.bitwise_and(frame, frame, mask=thresh_img)
        opening = cv2.morphologyEx(thresh_img, cv2.MORPH_OPEN, kernel2, 3)
        border = cv2.dilate(opening, kernel2, iterations=3)
        border = border - cv2.erode(border, None)
        ####################################################################
        frame_number = count
        current_index = int(frame_number % n_drops)

        # Make all colors more transparent as time progresses.
        rain_drops['color'][:, 3] -= 255.0/len(rain_drops)
        rain_drops['color'][:, 3] = np.clip(rain_drops['color'][:, 3], 0, 255)

        # Make all circles bigger.
        rain_drops['size'] += rain_drops['growth']

        # Pick a new position for oldest rain drop, resetting its size,
        # color and growth factor.
        rain_drops['position'][current_index] = np.random.uniform(0, 1, 2)
        rain_drops['size'][current_index] = 7
        rain_drops['color'][current_index] = (0, 0, 0, 255)
        rain_drops['growth'][current_index] = np.random.uniform(1, 5)
        ###################DRAWING##############################################
        for x,y,s,c in zip(rain_drops['position'][:,0], rain_drops['position'][:,1],rain_drops['size'],rain_drops['color']):
##            scale_percent = s
##            print(s)
##            width = int(roseimg.shape[1] * scale_percent / 100)
##            height = int(roseimg.shape[0] * scale_percent / 100)
##            dim = (width, height)
##            # resize image
##            resized = cv2.resize(roseimg, dim, interpolation = cv2.INTER_AREA)
            resized = imgs[int(s)-5]
            resized[:,:,3]=c[3]
            res = OffsetImage(resized, zoom=0.1)
            ab = AnnotationBbox(res, (x,y),frameon=False)
            ax.add_artist(ab)

        fig.canvas.draw()

        img = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8,
                sep='')
        img  = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
        plt.close(fig)

        #####################################################################
        result =  cv2.bitwise_and(img, img, mask=thresh_img)
        
        cv2.imshow("result", result)
##        cv2.imshow("original",frame)
##        cv2.imshow("border", border)
##        cv2.imshow("ab", abdiff)
        cv2.imshow("thresh", thresh_img)
        cv2.imshow("panel", panel)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
