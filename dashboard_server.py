from flask import Flask, Response, jsonify
from pymavlink import mavutil
import cv2, threading, math

app = Flask(__name__)
master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)
master.wait_heartbeat()
data = {'roll':0,'pitch':0,'yaw':0,'vib_x':0,'vib_y':0,'vib_z':0,'xacc':0,'yacc':0,'zacc':0,'servo':[1500]*6,'load':0,'voltage':0,'alerts':[]}

def mavlink_thread():
    while True:
        msg = master.recv_match(blocking=True, timeout=1)
        if not msg: continue
        t = msg.get_type()
        alerts = []
        if t == 'ATTITUDE':
            data['roll'] = round(math.degrees(msg.roll),2)
            data['pitch'] = round(math.degrees(msg.pitch),2)
            data['yaw'] = round(math.degrees(msg.yaw),2)
            if abs(data['roll'])>30: alerts.append('WARN: Roll 이상')
            if abs(data['pitch'])>30: alerts.append('WARN: Pitch 이상')
        elif t == 'VIBRATION':
            data['vib_x']=round(msg.vibration_x,4)
            data['vib_y']=round(msg.vibration_y,4)
            data['vib_z']=round(msg.vibration_z,4)
            if max(data['vib_x'],data['vib_y'],data['vib_z'])>0.3: alerts.append('WARN: 진동 과다')
        elif t == 'RAW_IMU':
            data['xacc']=msg.xacc
            data['yacc']=msg.yacc
            data['zacc']=msg.zacc
        elif t == 'SERVO_OUTPUT_RAW':
            data['servo']=[msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]
            for i,v in enumerate(data['servo']):
                if v!=0 and (v<1100 or v>1900): alerts.append('WARN: 모터'+str(i+1)+' PWM이상')
        elif t == 'SYS_STATUS':
            data['load']=msg.load
            data['voltage']=msg.voltage_battery
            if msg.load>800: alerts.append('WARN: CPU 과부하')
        if alerts: data['alerts']=alerts
        else: data['alerts']=[]

threading.Thread(target=mavlink_thread,daemon=True).start()

camera = cv2.VideoCapture(0)

def gen_frames():
    NL=b'\r\n'
    BD=b'--frame'
    CT=b'Content-Type: image/jpeg'
    while True:
        ok,frame=camera.read()
        if not ok: continue
        _,buf=cv2.imencode('.jpg',frame)
        yield BD+NL+CT+NL+NL+buf.tobytes()+NL

@app.route('/video')
def video(): return Response(gen_frames(),mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api')
def api(): return jsonify(data)

@app.route('/')
def index(): return open('/home/mjtest/dashboard.html').read()

app.run(host='0.0.0.0',port=8080,threaded=True)