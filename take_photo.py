import cv2
from datetime import datetime

cap = cv2.VideoCapture(0)

ret, frame = cap.read()

if ret:
    filename = datetime.now().strftime("%Y%m%d_%H%M%S.jpg")
    cv2.imwrite(filename, frame)
    print(filename)

cap.release()
