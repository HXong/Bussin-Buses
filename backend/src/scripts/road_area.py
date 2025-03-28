# import cv2
# import numpy as np

# def estimate_road_area(image_path, draw=False, save_path=None):
#     image = cv2.imread(image_path)
#     hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

#     #for 1112.jpg
#     # lower_gray = np.array([0, 0, 90])
#     # upper_gray = np.array([100, 40, 152])

#     lower_gray = np.array([0, 0, 90])
#     upper_gray = np.array([180, 23, 184])
#     mask = cv2.inRange(hsv, lower_gray, upper_gray)

#     lower_green = np.array([13, 12, 0])
#     upper_green = np.array([123, 118, 144])
#     green_mask = cv2.inRange(hsv, lower_green, upper_green)
#     mask[green_mask > 0] = 0

#     height = mask.shape[0]
#     mask[:int(height * 0.10), :] = 0

#     kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7,7))
#     mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
#     mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=2)

#     # filtering to keep only road blobs
#     contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
#     filtered_mask = np.zeros_like(mask)

#     for contour in contours:
#         area = cv2.contourArea(contour)
#         if area > 5000:
#             approx = cv2.approxPolyDP(contour, 0.02 * cv2.arcLength(contour, True), True)
#             if len(approx) >= 4: 
#                 cv2.drawContours(filtered_mask, [contour], -1, 255, -1)

#     mask = filtered_mask
#     road_area = cv2.countNonZero(mask)

#     if draw:
#         blue_overlay = np.full_like(image, (255, 0, 0))  
#         mask_norm = (mask / 255)[:, :, np.newaxis]
#         overlay = (image * (1 - mask_norm * 0.6) + blue_overlay * (mask_norm * 0.6)).astype(np.uint8)

#         if save_path:
#             cv2.imwrite(save_path, overlay)

#         return road_area, overlay

#     return road_area, image


import cv2
import numpy as np
import os

def estimate_road_area(image_path, draw=False, save_path=None):
    image = cv2.imread(image_path)
    height, width = image.shape[:2]

    base_name = os.path.splitext(os.path.basename(image_path))[0]
    script_dir = os.path.dirname(__file__) 
    project_root = os.path.abspath(os.path.join(script_dir, "../../"))
    mask_path = os.path.join(project_root, "masks", f"{base_name}_mask.png")

    if not os.path.exists(mask_path):
        raise FileNotFoundError(f"Mask not found: {mask_path}")
    
    mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)

    if mask.shape != (height, width):
        mask = cv2.resize(mask, (width, height))

    road_area = cv2.countNonZero(mask)

    if draw:
        blue_overlay = np.full_like(image, (255, 0, 0))
        mask_norm = (mask / 255)[:, :, np.newaxis]
        overlay = (image * (1 - mask_norm * 0.6) + blue_overlay * (mask_norm * 0.6)).astype(np.uint8)

        if save_path:
            cv2.imwrite(save_path, overlay)

        return road_area, overlay

    return road_area, image
