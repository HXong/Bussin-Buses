import sys
import json
import os
import torch
import cv2
from ultralytics import YOLO
from road_area import estimate_road_area

def count_cars(image_path):
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

        results = model(image_path, imgsz=[640, 1280])

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

            cars_detected += 1
        
        if vehicle_area == 0:
            vehicle_area = 0

        return cars_detected, vehicle_area
    
    except Exception as e:
        print(json.dumps({"error": f"Detection failed: {str(e)}"}))
        return 0

def calculate_congestion_level(vehicle_area, road_area):
    try:
        congestion_level = vehicle_area / road_area
        if congestion_level > 0.82  :
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

        count, vehicle_area = count_cars(image_path)
        road_area = estimate_road_area(image_path)
        congestion_level = calculate_congestion_level(vehicle_area, road_area)

        result = {
            "image": image_path,
            "vehicle": count,
            "road_area": road_area,
            "vehicle_area": vehicle_area,
            "congestion_level": congestion_level
        }

        print(json.dumps(result, indent=4))
    except Exception as e:
        print(json.dumps({"error": f"Main execution failed: {str(e)}"}))
        sys.exit(1)
