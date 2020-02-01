import cv2

left = cv2.VideoCapture(0)
##right = cv2.VideoCapture(1)

while(True):
    if not (left.grab() ):
        print("No more frames")
        break

    _, leftFrame = left.retrieve()
##    _, rightFrame = right.retrieve()

    cv2.imshow('left', leftFrame)
##    cv2.imshow('right', rightFrame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

left.release()
##right.release()
cv2.destroyAllWindows()
