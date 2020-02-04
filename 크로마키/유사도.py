#https://code-examples.net/ko/q/2e5f7

import sys

#from scipy.misc import imread
from imageio import imread

from scipy.linalg import norm
#from scipy import sum, average
import numpy  #scipyvsum,average --> numpy
import imagehash


##def main():
##    #file1, file2 = sys.argv[1:1+2]
##    # read images as 2D arrays (convert to grayscale for simplicity)
##    img1 = to_grayscale(imread('compare1.jpg').astype(float))
##    img2 = to_grayscale(imread('compare2.jpg').astype(float))
##    # compare
##    n_m, n_0 = compare_images(img1, img2)
##    print ("Manhattan norm:", n_m, "/ per pixel:", n_m/img1.size)
##    print ("Zero norm:", n_0, "/ per pixel:", n_0*1.0/img1.size)

def compare_images(img1, img2):
    # normalize to compensate for exposure difference, this may be unnecessary
    # consider disabling it
    img1 = normalize(img1)
    img2 = normalize(img2)
    # calculate the difference and its norms
    diff = img1 - img2  # elementwise for scipy arrays
    m_norm = numpy.sum(abs(diff))  # Manhattan norm
    z_norm = norm(diff.ravel(), 0)  # Zero norm
    return (m_norm, z_norm)

def to_grayscale(arr):
    "If arr is a color image (3D array), convert it to grayscale (2D array)."
    if len(arr.shape) == 3:
        return numpy.average(arr, -1)  # average over the last axis (color channels)
    else:
        return arr

def normalize(arr):
    rng = arr.max()-arr.min()
    amin = arr.min()
    return (arr-amin)*255/rng



#file1, file2 = sys.argv[1:1+2]
# read images as 2D arrays (convert to grayscale for simplicity)
img1 = to_grayscale(imread('compare1.png').astype(float))
img2 = to_grayscale(imread('compare2.png').astype(float))
# compare
n_m, n_0 = compare_images(img1, img2)
print ("Manhattan norm:", n_m, "/ per pixel:", n_m/img1.size)
print ("Zero norm:", n_0, "/ per pixel:", n_0*1.0/img1.size)


