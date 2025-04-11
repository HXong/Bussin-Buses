import sys
import json
import os
import numpy as np
import cv2
from ultralytics import YOLO
from road_area import estimate_road_area


def count_cars(image_path):
    """
    This script counts the number of cars in an image and estimates the road area.
    It uses the YOLO model for object detection and OpenCV for image processing.

    Parameters
    ----------
    image_path : str
        Path to the input image.
    
    Raises
    ------
    Error
        If no image path is passed in as a
        parameter.

    """

    try:
        if not os.path.exists(image_path):
            return {"error": f"Image not found: {image_path}"}
        
        img = cv2.imread(image_path)
        if img is None:
            return {"error": f"Corrupted or invalid image: {image_path}"}

        # YOLO11l (better accuracy but slower)
        model = YOLO("models/yolo11l.pt")
        try:
            model.to('cuda')
        except:
            model.to('cpu')

        results = model(image_path, imgsz=[960, 1920], conf = 0.1)

        if results is None or len(results) == 0:
            return {"error": "No objects detected"}

        vehicle_area = 0
        cars_detected = 0

        for box in results[0].boxes:
            cls = int(box.cls[0].item())

            if cls in [2, 3, 5, 7]:  
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                width = x2 - x1
                height = y2 - y1
                vehicle_area += width * height

                cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                cv2.putText(img, model.names[cls], (x1, y1), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (36,255,12), 2)

            cars_detected += 1
        
        if vehicle_area == 0:
            vehicle_area = 0

        return cars_detected, vehicle_area, img
    
    except Exception as e:
        print(json.dumps({"error": f"Detection failed: {str(e)}"}))
        return 0

def calculate_congestion_level(vehicle_area, road_area, vehicle_count):
    """
    Calculate the congestion level based on vehicle area, road area, and vehicle count.
    The congestion level is classified as "low", "moderate", or "high".

    Parameters
    ----------
    vehicle_area : float
        The area occupied by vehicles in the image.
    road_area : float
        The area of the road in the image.
    vehicle_count : int
        The number of vehicles detected in the image.
    
    Raises
    ---------
    ZeroDivisionError
        If road_area is zero, indicating no road area detected.
        
    """
    try:
        if road_area == 0:
            if vehicle_count > 30:
                return "high"
            elif vehicle_count >= 15:
                return "moderate"
            else:
                return "low"

        else:
            congestion_level = vehicle_area / road_area
            if congestion_level > 0.56  :
                return "high"
            elif congestion_level >= 0.45:
                return "moderate"
            else:
                return "low"
        
    except ZeroDivisionError:
        return 0

if __name__ == "__main__":
    try:
        image_path = sys.argv[1]

        if not os.path.exists(image_path):
            print(json.dumps({"error": "Image not found"}))
            sys.exit(1)

        count, vehicle_area, img_vehicles = count_cars(image_path)
        try:
            road_area, annotated_image = estimate_road_area(image_path, draw=True)
        except FileNotFoundError:
            road_area = 0
            annotated_image = img_vehicles.copy()

        final_annotated_image = cv2.addWeighted(img_vehicles, 0.6, annotated_image, 0.4, 0)

        congestion_level = calculate_congestion_level(vehicle_area, road_area, count)

        output_path = None
        if congestion_level == "high":
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))  # backend/
            save_dir = os.path.join(project_root, "congested_roads")
            os.makedirs(save_dir, exist_ok=True)

            output_path = os.path.join(save_dir, "annotated_" + os.path.basename(image_path))
            cv2.imwrite(output_path, final_annotated_image)

        result = {
            "image": image_path,
            "vehicle": count,
            "road_area": road_area,
            "vehicle_area": vehicle_area,
            "congestion_level": congestion_level,
            "output_path": output_path
        }

        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"error": f"Main execution failed: {str(e)}"}))
        sys.exit(1)
