import matplotlib
matplotlib.use('TkAgg')

import numpy as np
import cv2
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage, AnnotationBbox

cap = cv2.VideoCapture(1)
roseimg = cv2.imread('rose.png',cv2.IMREAD_UNCHANGED)

fig = plt.figure(figsize=(5, 5))
ax = fig.add_axes([0, 0, 1, 1], frameon=False)
ax.set_xlim(0, 1), ax.set_xticks([])
ax.set_ylim(0, 1), ax.set_yticks([])

# Create rain data
n_drops = 6
rain_drops = np.zeros(n_drops, dtype=[('position', float, 2),
                                      ('size',     float, 1),
                                      ('growth',   float, 1),
                                      ('color',    float, 4)])

# Initialize the raindrops in random positions and with
# random growth rates.
rain_drops['position'] = np.random.uniform(0, 1, (n_drops, 2))
rain_drops['growth'] = np.random.uniform(2, 10, n_drops)

# Construct the scatter which we will update during animation
# as the raindrops develop.
##scat = ax.scatter(rain_drops['position'][:, 0], rain_drops['position'][:, 1],
##                  s=rain_drops['size'], lw=0.5, edgecolors=rain_drops['color'],
##                  facecolors='none')
count = 0;

while(1):
    _, frame = cap.read()
    count = count+1
##    cv2.imshow("original",frame)
    
    ########################################################################
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
    rain_drops['size'][current_index] = 5
    rain_drops['color'][current_index] = (0, 0, 0, 255)
    rain_drops['growth'][current_index] = np.random.uniform(2, 10)
    ###############################Resizing##################################

    ###################DRAWING##############################################
    for x,y,s,c in zip(rain_drops['position'][:,0], rain_drops['position'][:,1],rain_drops['size'],rain_drops['color']):
        scale_percent = s
        width = int(roseimg.shape[1] * scale_percent / 100)
        height = int(roseimg.shape[0] * scale_percent / 100)
        dim = (width, height)
        # resize image
        resized = cv2.resize(roseimg, dim, interpolation = cv2.INTER_AREA)
        resized[:,:,3]=resized[:,:,3]-70
        res = OffsetImage(resized, zoom=0.1)
        ab = AnnotationBbox(res, (x,y),frameon=False)
        ax.add_artist(ab)

    fig.canvas.draw()

    img = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8,
            sep='')
    img  = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))
    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)

    cv2.imshow("imgs",img)
    
    k = cv2.waitKey(33) & 0xFF
    if k == 27:
        break
