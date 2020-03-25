import cv2
import numpy as np
video = cv2.VideoCapture(0)
while True:
    ret, orig_frame = video.read()
    if not ret:
        video = cv2.VideoCapture(0)
        continue
    gray = cv2.cvtColor(orig_frame, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray,50,150)

    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 130, maxLineGap=50)
    if lines is not None:
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(orig_frame, (x1, y1), (x2, y2), (0, 255, 0), 5)
    cv2.imshow("frame", orig_frame)
    key = cv2.waitKey(1)
    if key == 27:
        break
video.release()
cv2.destroyAllWindows()
