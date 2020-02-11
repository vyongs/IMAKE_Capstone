##Not working

import matplotlib
matplotlib.use('TkAgg')

import numpy as np
import cv2
import matplotlib.pyplot as plt

fig = plt.figure()
cap = cv2.VideoCapture(1)


x1 = np.linspace(0.0, 5.0)
x2 = np.linspace(0.0, 2.0)
y1 = np.cos(2 * np.pi * x1) * np.exp(-x1)
y2 = np.cos(2 * np.pi * x2)


line1, = plt.plot(x1, y1, 'ko-')        # so that we can update data later

for i in range(1000):
    # update data
    line1.set_ydata(np.cos(2 * np.pi * (x1+i*3.14/2) ) * np.exp(-x1) )

    # redraw the canvas
    fig.canvas.draw()

    # convert canvas to image
    img = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8,
            sep='')
    img  = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))

    # img is rgb, convert to opencv's default bgr
    img = cv2.cvtColor(img,cv2.COLOR_RGB2BGR)


    # display image with opencv or any operation you like
    cv2.imshow("plot",img)

    # display camera feed
    
    ret,frame = cap.read()
    cv2.imshow("cam",frame)


    rose=cv2.imread('rose.png',cv2.IMREAD_UNCHANGED)
    scale_percent = 15 # percent of original size
    width = int(rose.shape[1] * scale_percent / 100)
    height = int(rose.shape[0] * scale_percent / 100)
    dim = (width, height)
    # resize image
    resized = cv2.resize(rose, dim, interpolation = cv2.INTER_AREA)
    adit = cv2.add(frame, resized)
    cv2.imshow("add",adit)
    

    k = cv2.waitKey(33) & 0xFF
    if k == 27:
        break
