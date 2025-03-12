import cv2
import numpy as np

def estimate_road_area(image_path):
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150)  # Edge detection

    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    road_width, road_length = 0, 0
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w * h > road_width * road_length:  
            road_width, road_length = w, h  

    return road_width * road_length