import cv2
import numpy as np

video = cv2.VideoCapture(1)

criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 100, 0.2)

# number of clusters (K)
k = 3

while True:
    ret, orig_frame = video.read()
    if not ret:
        print("Not connected")
        break;
    gray = cv2.cvtColor(orig_frame, cv2.COLOR_BGR2GRAY)
    gray = cv2.medianBlur(gray,5)

    pixel_values = gray.reshape((-1, 1))
    pixel_values = np.float32(pixel_values)

    _, labels, (centers) = cv2.kmeans(pixel_values, k, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)
    
    # convert back to 8 bit values
    centers = np.uint8(centers)

    # flatten the labels array
    labels = labels.flatten()

    # convert all pixels to the color of the centroids
    segmented_image = centers[labels.flatten()]
    # reshape back to the original image dimension
    segmented_image = segmented_image.reshape(gray.shape)

    circles = cv2.HoughCircles(segmented_image,cv2.HOUGH_GRADIENT,1,150,param1=50,param2=35,minRadius=0,maxRadius=0)
    if circles is not None:
        for c in circles[0,:]:

            center = (c[0],c[1])
            radius = c[2]
    
        # 바깥원
            cv2.circle(orig_frame,center,radius,(0,255,0),2)
    
        # 중심원
            cv2.circle(orig_frame,center,2,(0,0,255),3)
    cv2.imshow("frame", orig_frame)
    cv2.imshow("kmeans", segmented_image)
    key = cv2.waitKey(1)
    if key == 27:
        break

cv2.destroyAllWindows()
video.release()
