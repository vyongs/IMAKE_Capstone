import numpy as np
import cv2
from skimage.measure import compare_ssim
import imutils


cap = cv2.VideoCapture(1)

kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(3,3))
fgbg = cv2.createBackgroundSubtractorKNN()

runned = False

while(1):
    ret, frame = cap.read()
    if runned == False:
##        background_img = frame
        background_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        runned=True
    else:
        this_img = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
##        this_img = frame
        score, diff = compare_ssim(background_img, this_img, full=True)
        diff = (diff*255).astype("uint8")
        thresh = cv2.threshold(diff,0,255,cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
        sub = this_img - background_img
        bit_xor = cv2.subtract(this_img,background_img)
        bit_thresh = cv2.threshold(bit_xor, 0, 255, cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
        sub_thresh = cv2.threshold(sub, 0, 255, cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)[1]
##        fgmask = fgbg.apply(frame)
##        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
        cv2.imshow("bitthresh", sub_thresh)
        cv2.imshow("test", diff)
        cv2.imshow('frame',thresh)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
