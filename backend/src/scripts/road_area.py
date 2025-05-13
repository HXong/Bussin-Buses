import cv2
import numpy as np
import os

def estimate_road_area(image_path, draw=False, save_path=None):
    """
    Estimate the road area in an image using a mask.
    The mask is expected to be in the same directory as the image, with the same base name and a "_mask" suffix.

    Parameters
    ------------
    image_path : str
        Path to the input image.
    draw : bool, optional
        If True, draw the road area on the image. Default is False.
    save_path : str, optional
        Path to save the annotated image. Required if draw is True.
        If not provided, the annotated image will not be saved.

    Raises
    ---------
    FileNotFoundError
        If the mask file is not found in the expected location.
    
        
    """
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
