import cv2
 
img = cv2.imread('rose.png', cv2.IMREAD_UNCHANGED)
 
print('Original Dimensions : ',img.shape)
 


for idx in range(5,61):
    scale_percent = idx # percent of original size
    width = int(img.shape[1] * scale_percent / 100)
    height = int(img.shape[0] * scale_percent / 100)
    dim = (width, height)
    # resize image
    resized = cv2.resize(img, dim, interpolation = cv2.INTER_AREA)
    cv2.imwrite("rose_resized"+str(idx)+".png", resized)
 
print('Resized Dimensions : ',resized.shape)
 
cv2.imshow("Resized image", resized)
cv2.waitKey(0)
cv2.destroyAllWindows()
