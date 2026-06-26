sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install python3-pip python3-dev screen -y
sudo apt-get install python3-pip python3-dev screen -y
pip3 install future pymavlink MAVProxy
pip3 install future pymavlink MAVProxy --break-system-packages
sudo raspi-config
sudo nano /boot/firmware/config.txt
sudo systemctl disable hciuart
sudo systemctl disable bluetooth
sudo reboot
ls
cat stream.pu
cat stream.py
python3 -c "
content = '''
from flask import Flask, Response, jsonify
from pymavlink import mavutil
import cv2, threading, time, math

app = Flask(__name__)

master = mavutil.mavlink_connection(\"/dev/ttyAMA0\", baud=921600)
master.wait_heartbeat()

camera = cv2.VideoCapture(0)

data = {
    \"roll\": 0, \"pitch\": 0, \"yaw\": 0,
    \"vib_x\": 0, \"vib_y\": 0, \"vib_z\": 0,
    \"xacc\": 0, \"yacc\": 0, \"zacc\": 0,
    \"servo\": [1500]*6,
    \"load\": 0, \"voltage\": 0,
    \"alerts\": []
}

def mavlink_thread():
    while True:
        msg = master.recv_match(blocking=True, timeout=1)
        if not msg:
            continue
        t = msg.get_type()
        alerts = []

        if t == \"ATTITUDE\":
            data[\"roll\"] = round(math.degrees(msg.roll), 2)
            data[\"pitch\"] = round(math.degrees(msg.pitch), 2)
            data[\"yaw\"] = round(math.degrees(msg.yaw), 2)
            if abs(data[\"roll\"]) > 30:
                alerts.append(\"WARN: Roll 이상 \" + str(data[\"roll\"]) + \"deg\")
            if abs(data[\"pitch\"]) > 30:
                alerts.append(\"WARN: Pitch 이상 \" + str(data[\"pitch\"]) + \"deg\")

        elif t == \"VIBRATION\":
            data[\"vib_x\"] = round(msg.vibration_x, 4)
            data[\"vib_y\"] = round(msg.vibration_y, 4)
            data[\"vib_z\"] = round(msg.vibration_z, 4)
            if max(data[\"vib_x\"], data[\"vib_y\"], data[\"vib_z\"]) > 0.3:
                alerts.append(\"WARN: 진동 과다\")

        elif t == \"RAW_IMU\":
            data[\"xacc\"] = msg.xacc
            data[\"yacc\"] = msg.yacc
            data[\"zacc\"] = msg.zacc

        elif t == \"SERVO_OUTPUT_RAW\":
            data[\"servo\"] = [
                msg.servo1_raw, msg.servo2_raw, msg.servo3_raw,
                msg.servo4_raw, msg.servo5_raw, msg.servo6_raw
            ]
            for i, v in enumerate(data[\"servo\"]):
                if v != 0 and (v < 1100 or v > 1900):
                    alerts.append(\"WARN: 모터\" + str(i+1) + \" PWM 이상 \" + str(v))

        elif t == \"SYS_STATUS\":
            data[\"load\"] = msg.load
            data[\"voltage\"] = msg.voltage_battery
            if msg.load > 800:
                alerts.append(\"WARN: CPU 과부하 \" + str(msg.load))

        if alerts:
            data[\"alerts\"] = alerts

thread = threading.Thread(target=mavlink_thread, daemon=True)
thread.start()

def gen_frames():
    while True:
        success, frame = camera.read()
        if not success:
            continue
        _, buffer = cv2.imencode(\".jpg\", frame)
        yield (b\"--frame\\r\\nContent-Type: image/jpeg\\r\\n\\r\\n\"
               + buffer.tobytes() + b\"\\r\\n\")

@app.route(\"/video\")
def video():
    return Response(gen_frames(),
                    mimetype=\"multipart/x-mixed-replace; boundary=frame\")

@app.route(\"/api\")
def api():
    return jsonify(data)

@app.route(\"/\")
def index():
    return open(\"/home/mjtest/dashboard.html\").read()

app.run(host=\"0.0.0.0\", port=8080)
'''
open('dashboard_server.py', 'w').write(content)
print('done')
"
python3 -c "
content = '''<!DOCTYPE html>
<html>
<head>
<meta charset=\"UTF-8\">
<title>ROV Dashboard</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#0a0f1e; color:#e0e8ff; font-family:monospace; }
h1 { text-align:center; padding:16px; color:#4fc3f7; font-size:1.4em; letter-spacing:2px; }
.grid { display:grid; grid-template-columns:1fr 1fr 1fr; gap:12px; padding:0 16px 16px; }
.card { background:#111827; border:1px solid #1e3a5f; border-radius:8px; padding:14px; }
.card h2 { color:#4fc3f7; font-size:0.85em; margin-bottom:10px; border-bottom:1px solid #1e3a5f; padding-bottom:6px; }
.val { font-size:1.1em; margin:4px 0; }
.val span { color:#00e5ff; font-weight:bold; }
.warn { color:#ff5252; font-weight:bold; }
.ok { color:#69f0ae; }
.alert-box { background:#1a0a0a; border:1px solid #ff5252; border-radius:6px; padding:10px; margin-top:6px; min-height:40px; }
.alert-item { color:#ff5252; font-size:0.85em; margin:2px 0; }
.no-alert { color:#69f0ae; font-size:0.85em; }
#video-container { grid-column: span 1; display:flex; justify-content:center; align-items:center; }
#video-container img { width:100%; border-radius:6px; border:1px solid #1e3a5f; }
.servo-bar { height:8px; background:#1e3a5f; border-radius:4px; margin:4px 0; }
.servo-fill { height:8px; background:#4fc3f7; border-radius:4px; transition:width 0.3s; }
</style>
</head>
<body>
<h1>ROV MONITOR</h1>
<div class=\"grid\">

<div id=\"video-container\" class=\"card\">
  <img src=\"/video\" />
</div>

<div class=\"card\">
  <h2>ATTITUDE</h2>
  <div class=\"val\">Roll: <span id=\"roll\">-</span> deg</div>
  <div class=\"val\">Pitch: <span id=\"pitch\">-</span> deg</div>
  <div class=\"val\">Yaw: <span id=\"yaw\">-</span> deg</div>
</div>

<div class=\"card\">
  <h2>VIBRATION</h2>
  <div class=\"val\">Vib X: <span id=\"vx\">-</span></div>
  <div class=\"val\">Vib Y: <span id=\"vy\">-</span></div>
  <div class=\"val\">Vib Z: <span id=\"vz\">-</span></div>
</div>

<div class=\"card\">
  <h2>RAW IMU</h2>
  <div class=\"val\">Acc X: <span id=\"ax\">-</span></div>
  <div class=\"val\">Acc Y: <span id=\"ay\">-</span></div>
  <div class=\"val\">Acc Z: <span id=\"az\">-</span></div>
</div>

<div class=\"card\">
  <h2>MOTOR PWM (1-6)</h2>
  <div id=\"servos\"></div>
</div>

<div class=\"card\">
  <h2>SYSTEM</h2>
  <div class=\"val\">CPU Load: <span id=\"load\">-</span></div>
  <div class=\"val\">Voltage: <span id=\"volt\">-</span> mV</div>
</div>

<div class=\"card\" style=\"grid-column:span 3\">
  <h2>ALERTS</h2>
  <div class=\"alert-box\" id=\"alerts\"><span class=\"no-alert\">이상 없음</span></div>
</div>

</div>
<script>
function update() {
  fetch(\"/api\").then(r=>r.json()).then(d=>{
    document.getElementById(\"roll\").textContent = d.roll;
    document.getElementById(\"pitch\").textContent = d.pitch;
    document.getElementById(\"yaw\").textContent = d.yaw;
    document.getElementById(\"vx\").textContent = d.vib_x;
    document.getElementById(\"vy\").textContent = d.vib_y;
    document.getElementById(\"vz\").textContent = d.vib_z;
    document.getElementById(\"ax\").textContent = d.xacc;
    document.getElementById(\"ay\").textContent = d.yacc;
    document.getElementById(\"az\").textContent = d.zacc;
    document.getElementById(\"load\").textContent = d.load;
    document.getElementById(\"volt\").textContent = d.voltage;

    let s = \"\";
    d.servo.forEach((v,i)=>{
      let pct = Math.round((v-1100)/800*100);
      s += \"<div>M\"+(i+1)+\": \"+v+\"<div class=servo-bar><div class=servo-fill style=width:\"+pct+\"%></div></div></div>\";
    });
    document.getElementById(\"servos\").innerHTML = s;

    let ab = document.getElementById(\"alerts\");
    if(d.alerts && d.alerts.length > 0){
      ab.innerHTML = d.alerts.map(a=>\"<div class=alert-item>\"+a+\"</div>\").join(\"\");
    } else {
      ab.innerHTML = \"<span class=no-alert>이상 없음</span>\";
    }
  });
}
setInterval(update, 500);
update();
</script>
</body>
</html>'''
open('/home/mjtest/dashboard.html', 'w').write(content)
print('done')
"
python3 dashboard_server.py
python3 << 'PYEOF'
content = (
    "from flask import Flask, Response, jsonify\n"
    "from pymavlink import mavutil\n"
    "import cv2, threading, math\n\n"
    "app = Flask(__name__)\n"
    "master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)\n"
    "master.wait_heartbeat()\n"
    "camera = cv2.VideoCapture(0)\n"
    "data = {'roll':0,'pitch':0,'yaw':0,'vib_x':0,'vib_y':0,'vib_z':0,"
    "'xacc':0,'yacc':0,'zacc':0,'servo':[1500]*6,'load':0,'voltage':0,'alerts':[]}\n\n"
    "def mavlink_thread():\n"
    "    while True:\n"
    "        msg = master.recv_match(blocking=True, timeout=1)\n"
    "        if not msg: continue\n"
    "        t = msg.get_type()\n"
    "        alerts = []\n"
    "        if t == 'ATTITUDE':\n"
    "            data['roll'] = round(math.degrees(msg.roll),2)\n"
    "            data['pitch'] = round(math.degrees(msg.pitch),2)\n"
    "            data['yaw'] = round(math.degrees(msg.yaw),2)\n"
    "            if abs(data['roll'])>30: alerts.append('WARN: Roll 이상 '+str(data['roll'])+'deg')\n"
    "            if abs(data['pitch'])>30: alerts.append('WARN: Pitch 이상 '+str(data['pitch'])+'deg')\n"
    "        elif t == 'VIBRATION':\n"
    "            data['vib_x']=round(msg.vibration_x,4)\n"
    "            data['vib_y']=round(msg.vibration_y,4)\n"
    "            data['vib_z']=round(msg.vibration_z,4)\n"
    "            if max(data['vib_x'],data['vib_y'],data['vib_z'])>0.3: alerts.append('WARN: 진동 과다')\n"
    "        elif t == 'RAW_IMU':\n"
    "            data['xacc']=msg.xacc; data['yacc']=msg.yacc; data['zacc']=msg.zacc\n"
    "        elif t == 'SERVO_OUTPUT_RAW':\n"
    "            data['servo']=[msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]\n"
    "            for i,v in enumerate(data['servo']):\n"
    "                if v!=0 and (v<1100 or v>1900): alerts.append('WARN: 모터'+str(i+1)+' PWM 이상 '+str(v))\n"
    "        elif t == 'SYS_STATUS':\n"
    "            data['load']=msg.load; data['voltage']=msg.voltage_battery\n"
    "            if msg.load>800: alerts.append('WARN: CPU 과부하 '+str(msg.load))\n"
    "        if alerts: data['alerts']=alerts\n"
    "        else: data['alerts']=[]\n\n"
    "import threading\n"
    "threading.Thread(target=mavlink_thread,daemon=True).start()\n\n"
    "def gen_frames():\n"
    "    while True:\n"
    "        success,frame=camera.read()\n"
    "        if not success: continue\n"
    "        _,buffer=cv2.imencode('.jpg',frame)\n"
    "        yield b'--frame\r\nContent-Type: image/jpeg\r\n\r\n'+buffer.tobytes()+b'\r\n'\n\n"
    "@app.route('/video')\n"
    "def video(): return Response(gen_frames(),mimetype='multipart/x-mixed-replace; boundary=frame')\n\n"
    "@app.route('/api')\n"
    "def api(): return jsonify(data)\n\n"
    "@app.route('/')\n"
    "def index(): return open('/home/mjtest/dashboard.html').read()\n\n"
    "app.run(host='0.0.0.0',port=8080)\n"
)
open('/home/mjtest/dashboard_server.py','w').write(content)
print('done')
PYEOF

python3 dashboard_server.py
ls /home/mjtest
python3 /home/mjtest/dashboard_server.py
cd ~
python3 dashboard_server.py
cd ~
python3 dashboard_server.py
python3 << 'PYEOF'
lines = []
lines.append("from flask import Flask, Response, jsonify")
lines.append("from pymavlink import mavutil")
lines.append("import cv2, threading, math")
lines.append("")
lines.append("app = Flask(__name__)")
lines.append("master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)")
lines.append("master.wait_heartbeat()")
lines.append("camera = cv2.VideoCapture(0)")
lines.append("data = {'roll':0,'pitch':0,'yaw':0,'vib_x':0,'vib_y':0,'vib_z':0,'xacc':0,'yacc':0,'zacc':0,'servo':[1500]*6,'load':0,'voltage':0,'alerts':[]}")
lines.append("")
lines.append("def mavlink_thread():")
lines.append("    while True:")
lines.append("        msg = master.recv_match(blocking=True, timeout=1)")
lines.append("        if not msg: continue")
lines.append("        t = msg.get_type()")
lines.append("        alerts = []")
lines.append("        if t == 'ATTITUDE':")
lines.append("            data['roll'] = round(math.degrees(msg.roll),2)")
lines.append("            data['pitch'] = round(math.degrees(msg.pitch),2)")
lines.append("            data['yaw'] = round(math.degrees(msg.yaw),2)")
lines.append("            if abs(data['roll'])>30: alerts.append('WARN: Roll 이상')")
lines.append("            if abs(data['pitch'])>30: alerts.append('WARN: Pitch 이상')")
lines.append("        elif t == 'VIBRATION':")
lines.append("            data['vib_x']=round(msg.vibration_x,4)")
lines.append("            data['vib_y']=round(msg.vibration_y,4)")
lines.append("            data['vib_z']=round(msg.vibration_z,4)")
lines.append("            if max(data['vib_x'],data['vib_y'],data['vib_z'])>0.3: alerts.append('WARN: 진동 과다')")
lines.append("        elif t == 'RAW_IMU':")
lines.append("            data['xacc']=msg.xacc")
lines.append("            data['yacc']=msg.yacc")
lines.append("            data['zacc']=msg.zacc")
lines.append("        elif t == 'SERVO_OUTPUT_RAW':")
lines.append("            data['servo']=[msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]")
lines.append("            for i,v in enumerate(data['servo']):")
lines.append("                if v!=0 and (v<1100 or v>1900): alerts.append('WARN: 모터'+str(i+1)+' PWM이상')")
lines.append("        elif t == 'SYS_STATUS':")
lines.append("            data['load']=msg.load")
lines.append("            data['voltage']=msg.voltage_battery")
lines.append("            if msg.load>800: alerts.append('WARN: CPU 과부하')")
lines.append("        if alerts: data['alerts']=alerts")
lines.append("        else: data['alerts']=[]")
lines.append("")
lines.append("threading.Thread(target=mavlink_thread,daemon=True).start()")
lines.append("")
lines.append("def gen_frames():")
lines.append("    BOUNDARY = b'--frame\r\n'")
lines.append("    CTYPE = b'Content-Type: image/jpeg\r\n\r\n'")
lines.append("    while True:")
lines.append("        success,frame=camera.read()")
lines.append("        if not success: continue")
lines.append("        _,buffer=cv2.imencode('.jpg',frame)")
lines.append("        yield BOUNDARY + CTYPE + buffer.tobytes() + b'\r\n'")
lines.append("")
lines.append("@app.route('/video')")
lines.append("def video(): return Response(gen_frames(),mimetype='multipart/x-mixed-replace; boundary=frame')")
lines.append("")
lines.append("@app.route('/api')")
lines.append("def api(): return jsonify(data)")
lines.append("")
lines.append("@app.route('/')")
lines.append("def index(): return open('/home/mjtest/dashboard.html').read()")
lines.append("")
lines.append("app.run(host='0.0.0.0',port=8080)")

with open('/home/mjtest/dashboard_server.py','w') as f:
    f.write('\n'.join(lines))
print('done')
PYEOF

python3 dashboard_server.py
python3 << 'PYEOF'
lines = []
lines.append("from flask import Flask, Response, jsonify")
lines.append("from pymavlink import mavutil")
lines.append("import cv2, threading, math")
lines.append("")
lines.append("app = Flask(__name__)")
lines.append("master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)")
lines.append("master.wait_heartbeat()")
lines.append("camera = cv2.VideoCapture(0)")
lines.append("data = {'roll':0,'pitch':0,'yaw':0,'vib_x':0,'vib_y':0,'vib_z':0,'xacc':0,'yacc':0,'zacc':0,'servo':[1500]*6,'load':0,'voltage':0,'alerts':[]}")
lines.append("")
lines.append("def mavlink_thread():")
lines.append("    while True:")
lines.append("        msg = master.recv_match(blocking=True, timeout=1)")
lines.append("        if not msg: continue")
lines.append("        t = msg.get_type()")
lines.append("        alerts = []")
lines.append("        if t == 'ATTITUDE':")
lines.append("            data['roll'] = round(math.degrees(msg.roll),2)")
lines.append("            data['pitch'] = round(math.degrees(msg.pitch),2)")
lines.append("            data['yaw'] = round(math.degrees(msg.yaw),2)")
lines.append("            if abs(data['roll'])>30: alerts.append('WARN: Roll 이상')")
lines.append("            if abs(data['pitch'])>30: alerts.append('WARN: Pitch 이상')")
lines.append("        elif t == 'VIBRATION':")
lines.append("            data['vib_x']=round(msg.vibration_x,4)")
lines.append("            data['vib_y']=round(msg.vibration_y,4)")
lines.append("            data['vib_z']=round(msg.vibration_z,4)")
lines.append("            if max(data['vib_x'],data['vib_y'],data['vib_z'])>0.3: alerts.append('WARN: 진동 과다')")
lines.append("        elif t == 'RAW_IMU':")
lines.append("            data['xacc']=msg.xacc")
lines.append("            data['yacc']=msg.yacc")
lines.append("            data['zacc']=msg.zacc")
lines.append("        elif t == 'SERVO_OUTPUT_RAW':")
lines.append("            data['servo']=[msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]")
lines.append("            for i,v in enumerate(data['servo']):")
lines.append("                if v!=0 and (v<1100 or v>1900): alerts.append('WARN: 모터'+str(i+1)+' PWM이상')")
lines.append("        elif t == 'SYS_STATUS':")
lines.append("            data['load']=msg.load")
lines.append("            data['voltage']=msg.voltage_battery")
lines.append("            if msg.load>800: alerts.append('WARN: CPU 과부하')")
lines.append("        if alerts: data['alerts']=alerts")
lines.append("        else: data['alerts']=[]")
lines.append("")
lines.append("threading.Thread(target=mavlink_thread,daemon=True).start()")
lines.append("")
lines.append("def gen_frames():")
lines.append("    NL = b'\\r\\n'")
lines.append("    BD = b'--frame'")
lines.append("    CT = b'Content-Type: image/jpeg'")
lines.append("    while True:")
lines.append("        success,frame=camera.read()")
lines.append("        if not success: continue")
lines.append("        _,buffer=cv2.imencode('.jpg',frame)")
lines.append("        yield BD+NL+CT+NL+NL+buffer.tobytes()+NL")
lines.append("")
lines.append("@app.route('/video')")
lines.append("def video(): return Response(gen_frames(),mimetype='multipart/x-mixed-replace; boundary=frame')")
lines.append("")
lines.append("@app.route('/api')")
lines.append("def api(): return jsonify(data)")
lines.append("")
lines.append("@app.route('/')")
lines.append("def index(): return open('/home/mjtest/dashboard.html').read()")
lines.append("")
lines.append("app.run(host='0.0.0.0',port=8080)")
lines.append("")
with open('/home/mjtest/dashboard_server.py','w') as f:
    f.write('\n'.join(lines))
print('done')
PYEOF

python3 dashboard_server.py
python3 << 'PYEOF'
html = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ROV Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{background:#0a0f1e;color:#e0e8ff;font-family:monospace;font-size:13px;}
h1{text-align:center;padding:12px;color:#4fc3f7;letter-spacing:2px;}
.grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;padding:0 12px 12px;}
.card{background:#111827;border:1px solid #1e3a5f;border-radius:8px;padding:12px;}
.card h2{color:#4fc3f7;font-size:0.8em;margin-bottom:8px;border-bottom:1px solid #1e3a5f;padding-bottom:5px;}
.val{margin:3px 0;}
.val span{color:#00e5ff;font-weight:bold;}
.alert-box{background:#1a0a0a;border:1px solid #ff5252;border-radius:6px;padding:8px;min-height:36px;}
.alert-item{color:#ff5252;font-size:0.85em;margin:2px 0;}
.no-alert{color:#69f0ae;font-size:0.85em;}
.servo-bar{height:7px;background:#1e3a5f;border-radius:4px;margin:3px 0;}
.servo-fill{height:7px;background:#4fc3f7;border-radius:4px;transition:width 0.2s;}
canvas{max-width:100%;}
#c3d{width:100%;height:220px;display:block;}
</style>
</head>
<body>
<h1>ROV MONITOR</h1>
<div class="grid">

<div class="card">
  <h2>CAMERA</h2>
  <img src="/video" style="width:100%;border-radius:4px;border:1px solid #1e3a5f;">
</div>

<div class="card">
  <h2>3D ATTITUDE</h2>
  <canvas id="c3d"></canvas>
</div>

<div class="card">
  <h2>SYSTEM</h2>
  <div class="val">CPU Load: <span id="load">-</span></div>
  <div class="val">Voltage: <span id="volt">-</span> mV</div>
  <div class="val">Armed: <span id="armed">-</span></div>
  <br>
  <h2>RAW IMU</h2>
  <div class="val">Acc X: <span id="ax">-</span></div>
  <div class="val">Acc Y: <span id="ay">-</span></div>
  <div class="val">Acc Z: <span id="az">-</span></div>
</div>

<div class="card" style="grid-column:span 3;">
  <h2>ATTITUDE (Roll / Pitch / Yaw)</h2>
  <canvas id="chartRPY" height="80"></canvas>
</div>

<div class="card" style="grid-column:span 2;">
  <h2>VIBRATION</h2>
  <canvas id="chartVib" height="80"></canvas>
</div>

<div class="card">
  <h2>MOTOR PWM (1-6)</h2>
  <div id="servos"></div>
</div>

<div class="card" style="grid-column:span 3;">
  <h2>ALERTS</h2>
  <div class="alert-box" id="alerts"><span class="no-alert">이상 없음</span></div>
</div>

</div>
<script>
const MAX=60;
function mkBuf(){return Array(MAX).fill(0);}
const labels=Array(MAX).fill('');
const rpyData={roll:mkBuf(),pitch:mkBuf(),yaw:mkBuf()};
const vibData={x:mkBuf(),y:mkBuf(),z:mkBuf()};

const ctxRPY=document.getElementById('chartRPY').getContext('2d');
const chartRPY=new Chart(ctxRPY,{
  type:'line',
  data:{labels,datasets:[
    {label:'Roll',data:rpyData.roll,borderColor:'#ff6b6b',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Pitch',data:rpyData.pitch,borderColor:'#4fc3f7',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Yaw',data:rpyData.yaw,borderColor:'#69f0ae',tension:0.3,pointRadius:0,borderWidth:1.5}
  ]},
  options:{animation:false,scales:{x:{display:false},y:{ticks:{color:'#aaa'},grid:{color:'#1e3a5f'}}},plugins:{legend:{labels:{color:'#ccc'}}}}
});

const ctxVib=document.getElementById('chartVib').getContext('2d');
const chartVib=new Chart(ctxVib,{
  type:'line',
  data:{labels,datasets:[
    {label:'Vib X',data:vibData.x,borderColor:'#ff9800',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Vib Y',data:vibData.y,borderColor:'#e040fb',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Vib Z',data:vibData.z,borderColor:'#00bcd4',tension:0.3,pointRadius:0,borderWidth:1.5}
  ]},
  options:{animation:false,scales:{x:{display:false},y:{ticks:{color:'#aaa'},grid:{color:'#1e3a5f'}}},plugins:{legend:{labels:{color:'#ccc'}}}}
});

function push(arr,val){arr.shift();arr.push(val);}

// Three.js 3D
const renderer=new THREE.WebGLRenderer({canvas:document.getElementById('c3d'),alpha:true,antialias:true});
renderer.setClearColor(0x111827,1);
const scene=new THREE.Scene();
const camera3=new THREE.PerspectiveCamera(50,2,0.1,100);
camera3.position.set(0,1.5,3);
camera3.lookAt(0,0,0);

const geo=new THREE.BoxGeometry(2,0.25,1);
const mat=new THREE.MeshPhongMaterial({color:0x4fc3f7,opacity:0.85,transparent:true});
const body=new THREE.Mesh(geo,mat);
scene.add(body);

const arrowGeo=new THREE.ConeGeometry(0.15,0.5,8);
const arrowMat=new THREE.MeshPhongMaterial({color:0xff6b6b});
const arrow=new THREE.Mesh(arrowGeo,arrowMat);
arrow.position.set(1.1,0,0);
arrow.rotation.z=-Math.PI/2;
body.add(arrow);

const edges=new THREE.EdgesGeometry(geo);
const line=new THREE.LineSegments(edges,new THREE.LineBasicMaterial({color:0x00e5ff}));
body.add(line);

scene.add(new THREE.AmbientLight(0xffffff,0.6));
const dLight=new THREE.DirectionalLight(0xffffff,0.8);
dLight.position.set(2,4,3);
scene.add(dLight);

const gridHelper=new THREE.GridHelper(6,6,0x1e3a5f,0x1e3a5f);
scene.add(gridHelper);

function resizeCanvas(){
  const c=document.getElementById('c3d');
  renderer.setSize(c.clientWidth,c.clientHeight);
  camera3.aspect=c.clientWidth/c.clientHeight;
  camera3.updateProjectionMatrix();
}
resizeCanvas();
window.addEventListener('resize',resizeCanvas);

let curRoll=0,curPitch=0,curYaw=0;
function animate(){
  requestAnimationFrame(animate);
  body.rotation.x=curPitch;
  body.rotation.y=curYaw;
  body.rotation.z=curRoll;
  renderer.render(scene,camera3);
}
animate();

function update(){
  fetch('/api').then(r=>r.json()).then(d=>{
    const roll=d.roll*Math.PI/180;
    const pitch=d.pitch*Math.PI/180;
    const yaw=d.yaw*Math.PI/180;
    curRoll=roll; curPitch=pitch; curYaw=yaw;

    push(rpyData.roll,d.roll);
    push(rpyData.pitch,d.pitch);
    push(rpyData.yaw,d.yaw);
    chartRPY.update();

    push(vibData.x,d.vib_x);
    push(vibData.y,d.vib_y);
    push(vibData.z,d.vib_z);
    chartVib.update();

    document.getElementById('load').textContent=d.load;
    document.getElementById('volt').textContent=d.voltage===0?'미연결':d.voltage;
    document.getElementById('ax').textContent=d.xacc;
    document.getElementById('ay').textContent=d.yacc;
    document.getElementById('az').textContent=d.zacc;

    let s='';
    d.servo.forEach((v,i)=>{
      const pct=Math.round((v-1100)/800*100);
      s+='<div>M'+(i+1)+': '+v+'<div class="servo-bar"><div class="servo-fill" style="width:'+pct+'%"></div></div></div>';
    });
    document.getElementById('servos').innerHTML=s;

    const ab=document.getElementById('alerts');
    if(d.alerts&&d.alerts.length>0){
      ab.innerHTML=d.alerts.map(a=>'<div class="alert-item">'+a+'</div>').join('');
    }else{
      ab.innerHTML='<span class="no-alert">이상 없음</span>';
    }
  });
}
setInterval(update,500);
update();
</script>
</body>
</html>"""
open('/home/mjtest/dashboard.html','w').write(html)
print('done')
PYEOF

python3 dashboard_server.py
python3 << 'PYEOF'
with open('/home/mjtest/dashboard_server.py','r') as f:
    content = f.read()
content = content.replace('app.run(host="0.0.0.0",port=8080)', 'app.run(host="0.0.0.0",port=8080,threaded=True)')
with open('/home/mjtest/dashboard_server.py','w') as f:
    f.write(content)
print('done')
PYEOF

python3 dashboard_server.py
sudo fuser /dev/video0
ls /dev/video*
sudo fuser /dev/video0
python3 dashboard_server.py
python3 << 'PYEOF'
html = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ROV Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#0a0f1e;color:#e0e8ff;font-family:monospace;font-size:12px;overflow:hidden;}
#root{width:100vw;height:100vh;display:grid;grid-template-rows:36px 1fr 1fr;grid-template-columns:1fr 1fr 1fr 1fr;}
h1{grid-column:span 4;text-align:center;line-height:36px;color:#4fc3f7;letter-spacing:3px;font-size:1em;background:#080d1a;border-bottom:1px solid #1e3a5f;}
.card{background:#111827;border:1px solid #1e3a5f;overflow:hidden;display:flex;flex-direction:column;}
.card-title{color:#4fc3f7;font-size:0.75em;padding:4px 8px;border-bottom:1px solid #1e3a5f;background:#0d1526;flex-shrink:0;}
.card-body{flex:1;overflow:hidden;display:flex;flex-direction:column;justify-content:center;padding:6px;}
#cam-card{grid-column:span 2;grid-row:2;}
#cam-card img{width:100%;height:100%;object-fit:cover;}
#d3-card{grid-column:span 2;grid-row:2;}
#rpy-card{grid-column:span 2;grid-row:3;}
#vib-card{grid-column:span 1;grid-row:3;}
#motor-card{grid-column:span 1;grid-row:3;}
canvas{width:100%!important;height:100%!important;}
#c3d{width:100%;height:100%;display:block;}
.val{margin:2px 0;font-size:0.85em;}
.val span{color:#00e5ff;font-weight:bold;}
.alert-ok{color:#69f0ae;font-size:0.8em;}
.alert-warn{color:#ff5252;font-size:0.8em;}
#motor-svg{width:100%;height:100%;}
</style>
</head>
<body>
<div id="root">
<h1>ROV MONITOR</h1>

<div class="card" id="cam-card">
  <div class="card-title">CAMERA</div>
  <div class="card-body" style="padding:0;">
    <img src="/video" style="width:100%;height:100%;object-fit:cover;">
  </div>
</div>

<div class="card" id="d3-card">
  <div class="card-title">3D ATTITUDE &nbsp; Roll(X/red) Pitch(Y/blue) Yaw(Z/green) &nbsp; [deg]</div>
  <div class="card-body" style="padding:0;position:relative;">
    <canvas id="c3d"></canvas>
    <div style="position:absolute;bottom:6px;left:8px;font-size:0.75em;">
      <span style="color:#ff6b6b">Roll: <b id="rv">0</b>°</span> &nbsp;
      <span style="color:#4fc3f7">Pitch: <b id="pv">0</b>°</span> &nbsp;
      <span style="color:#69f0ae">Yaw: <b id="yv">0</b>°</span>
    </div>
    <div style="position:absolute;top:6px;right:8px;font-size:0.75em;" id="alertbox">
      <span class="alert-ok">정상</span>
    </div>
  </div>
</div>

<div class="card" id="rpy-card">
  <div class="card-title">ATTITUDE HISTORY &nbsp; Roll / Pitch [deg] &nbsp; Yaw [deg]</div>
  <div class="card-body" style="padding:4px;">
    <canvas id="chartRPY"></canvas>
  </div>
</div>

<div class="card" id="vib-card">
  <div class="card-title">VIBRATION &nbsp; [m/s²]</div>
  <div class="card-body" style="padding:4px;">
    <canvas id="chartVib"></canvas>
  </div>
</div>

<div class="card" id="motor-card">
  <div class="card-title">MOTOR LAYOUT &nbsp; PWM [μs] &nbsp; 1100=정지 1500=중립 1900=최대</div>
  <div class="card-body" style="padding:4px;">
    <svg id="motor-svg" viewBox="0 0 300 260">
      <rect width="300" height="260" fill="#0d1526"/>
      <!-- frame body -->
      <rect x="90" y="80" width="120" height="100" rx="6" fill="#1e3a5f" stroke="#4fc3f7" stroke-width="1.5"/>
      <text x="150" y="134" text-anchor="middle" fill="#4fc3f7" font-size="9">BODY</text>
      <!-- forward arrow -->
      <polygon points="150,75 145,85 155,85" fill="#ff6b6b"/>
      <text x="150" y="70" text-anchor="middle" fill="#ff6b6b" font-size="8">FWD</text>

      <!-- M1 전방우측 대각 -->
      <g id="m1g" transform="translate(220,60) rotate(45)">
        <rect x="-18" y="-6" width="36" height="12" rx="3" fill="#1a2a3a" stroke="#4fc3f7" stroke-width="1"/>
        <text x="0" y="4" text-anchor="middle" fill="#4fc3f7" font-size="8">M1</text>
      </g>
      <text id="m1v" x="234" y="52" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- M2 전방좌측 대각 -->
      <g id="m2g" transform="translate(80,60) rotate(-45)">
        <rect x="-18" y="-6" width="36" height="12" rx="3" fill="#1a2a3a" stroke="#4fc3f7" stroke-width="1"/>
        <text x="0" y="4" text-anchor="middle" fill="#4fc3f7" font-size="8">M2</text>
      </g>
      <text id="m2v" x="66" y="52" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- M3 후방우측 대각 -->
      <g id="m3g" transform="translate(220,180) rotate(-45)">
        <rect x="-18" y="-6" width="36" height="12" rx="3" fill="#1a2a3a" stroke="#4fc3f7" stroke-width="1"/>
        <text x="0" y="4" text-anchor="middle" fill="#4fc3f7" font-size="8">M3</text>
      </g>
      <text id="m3v" x="234" y="195" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- M4 후방좌측 대각 -->
      <g id="m4g" transform="translate(80,180) rotate(45)">
        <rect x="-18" y="-6" width="36" height="12" rx="3" fill="#1a2a3a" stroke="#4fc3f7" stroke-width="1"/>
        <text x="0" y="4" text-anchor="middle" fill="#4fc3f7" font-size="8">M4</text>
      </g>
      <text id="m4v" x="66" y="195" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- M5 우측 수직 -->
      <g transform="translate(255,130)">
        <circle cx="0" cy="0" r="14" fill="#1a2a3a" stroke="#e040fb" stroke-width="1.5"/>
        <text x="0" y="4" text-anchor="middle" fill="#e040fb" font-size="8">M5</text>
      </g>
      <text id="m5v" x="255" y="155" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- M6 좌측 수직 -->
      <g transform="translate(45,130)">
        <circle cx="0" cy="0" r="14" fill="#1a2a3a" stroke="#e040fb" stroke-width="1.5"/>
        <text x="0" y="4" text-anchor="middle" fill="#e040fb" font-size="8">M6</text>
      </g>
      <text id="m6v" x="45" y="155" text-anchor="middle" fill="#00e5ff" font-size="7">1500</text>

      <!-- 범례 -->
      <rect x="8" y="230" width="8" height="8" fill="#4fc3f7"/>
      <text x="20" y="238" fill="#aaa" font-size="7">수평추진기</text>
      <circle cx="100" cy="234" r="4" fill="#e040fb"/>
      <text x="108" y="238" fill="#aaa" font-size="7">수직추진기</text>
      <text x="170" y="238" fill="#aaa" font-size="7">CPU: <tspan id="cpuv" fill="#00e5ff">-</tspan></text>
      <text x="230" y="238" fill="#aaa" font-size="7">V: <tspan id="vv" fill="#00e5ff">-</tspan></text>
    </svg>
  </div>
</div>

</div>

<script>
const MAX=80;
function mkBuf(){return Array(MAX).fill(0);}
const labels=Array(MAX).fill('');
const rpyData={roll:mkBuf(),pitch:mkBuf(),yaw:mkBuf()};
const vibData={x:mkBuf(),y:mkBuf(),z:mkBuf()};

const ctxRPY=document.getElementById('chartRPY').getContext('2d');
const chartRPY=new Chart(ctxRPY,{
  type:'line',
  data:{labels,datasets:[
    {label:'Roll [deg]',data:rpyData.roll,borderColor:'#ff6b6b',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Pitch [deg]',data:rpyData.pitch,borderColor:'#4fc3f7',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Yaw [deg]',data:rpyData.yaw,borderColor:'#69f0ae',tension:0.3,pointRadius:0,borderWidth:1.5}
  ]},
  options:{animation:false,responsive:true,maintainAspectRatio:false,
    scales:{
      x:{display:false},
      y:{ticks:{color:'#aaa',font:{size:10}},grid:{color:'#1e3a5f'},title:{display:true,text:'deg',color:'#aaa',font:{size:10}}}
    },
    plugins:{legend:{labels:{color:'#ccc',font:{size:10}}}}}
});

const ctxVib=document.getElementById('chartVib').getContext('2d');
const chartVib=new Chart(ctxVib,{
  type:'line',
  data:{labels,datasets:[
    {label:'X [m/s²]',data:vibData.x,borderColor:'#ff9800',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Y [m/s²]',data:vibData.y,borderColor:'#e040fb',tension:0.3,pointRadius:0,borderWidth:1.5},
    {label:'Z [m/s²]',data:vibData.z,borderColor:'#00bcd4',tension:0.3,pointRadius:0,borderWidth:1.5}
  ]},
  options:{animation:false,responsive:true,maintainAspectRatio:false,
    scales:{
      x:{display:false},
      y:{ticks:{color:'#aaa',font:{size:10}},grid:{color:'#1e3a5f'},title:{display:true,text:'m/s²',color:'#aaa',font:{size:10}}}
    },
    plugins:{legend:{labels:{color:'#ccc',font:{size:10}}}}}
});

function push(arr,val){arr.shift();arr.push(val);}

// Three.js
const renderer=new THREE.WebGLRenderer({canvas:document.getElementById('c3d'),alpha:true,antialias:true});
renderer.setClearColor(0x0d1526,1);
const scene=new THREE.Scene();
const cam3=new THREE.PerspectiveCamera(45,2,0.1,100);
cam3.position.set(0,2,4);
cam3.lookAt(0,0,0);

const bodyGeo=new THREE.BoxGeometry(2.4,0.28,1.2);
const bodyMat=new THREE.MeshPhongMaterial({color:0x1e5080,opacity:0.9,transparent:true});
const body=new THREE.Mesh(bodyGeo,bodyMat);
scene.add(body);
const edges=new THREE.EdgesGeometry(bodyGeo);
body.add(new THREE.LineSegments(edges,new THREE.LineBasicMaterial({color:0x4fc3f7})));

// 전방 화살표
const arrowGeo=new THREE.ConeGeometry(0.12,0.4,8);
const arrowMesh=new THREE.Mesh(arrowGeo,new THREE.MeshPhongMaterial({color:0xff6b6b}));
arrowMesh.position.set(1.3,0,0);
arrowMesh.rotation.z=-Math.PI/2;
body.add(arrowMesh);

// 축 표시
const axMat=c=>new THREE.LineBasicMaterial({color:c});
function axLine(x1,y1,z1,x2,y2,z2,c){
  const g=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(x1,y1,z1),new THREE.Vector3(x2,y2,z2)]);
  scene.add(new THREE.Line(g,axMat(c)));
}
axLine(-3,0,0,3,0,0,0xff4444);
axLine(0,-3,0,0,3,0,0x44ff44);
axLine(0,0,-3,0,0,3,0x4444ff);

scene.add(new THREE.GridHelper(6,6,0x1e3a5f,0x1e3a5f));
scene.add(new THREE.AmbientLight(0xffffff,0.5));
const dl=new THREE.DirectionalLight(0xffffff,0.9);
dl.position.set(3,5,4);
scene.add(dl);

function resizeRenderer(){
  const c=document.getElementById('c3d');
  const w=c.clientWidth,h=c.clientHeight;
  renderer.setSize(w,h,false);
  cam3.aspect=w/h;
  cam3.updateProjectionMatrix();
}
resizeRenderer();
window.addEventListener('resize',resizeRenderer);

let cr=0,cp=0,cy=0;
function animate(){requestAnimationFrame(animate);body.rotation.set(cp,cy,cr);renderer.render(scene,cam3);}
animate();

function motorColor(v){
  if(v===1500)return'#1e3a5f';
  if(v>1500)return'#00e5ff';
  return'#ff6b6b';
}

function update(){
  fetch('/api').then(r=>r.json()).then(d=>{
    cr=d.roll*Math.PI/180;
    cp=d.pitch*Math.PI/180;
    cy=d.yaw*Math.PI/180;

    document.getElementById('rv').textContent=d.roll;
    document.getElementById('pv').textContent=d.pitch;
    document.getElementById('yv').textContent=d.yaw;

    push(rpyData.roll,d.roll);
    push(rpyData.pitch,d.pitch);
    push(rpyData.yaw,d.yaw);
    chartRPY.update();

    push(vibData.x,d.vib_x);
    push(vibData.y,d.vib_y);
    push(vibData.z,d.vib_z);
    chartVib.update();

    const mv=['m1v','m2v','m3v','m4v','m5v','m6v'];
    const mg=['m1g','m2g','m3g','m4g'];
    d.servo.forEach((v,i)=>{
      const el=document.getElementById(mv[i]);
      if(el){el.textContent=v;el.setAttribute('fill',v===1500?'#888':v>1500?'#00e5ff':'#ff6b6b');}
      if(i<4){
        const g=document.getElementById(mg[i]);
        if(g)g.querySelector('rect').setAttribute('fill',v===1500?'#1a2a3a':v>1500?'#0a3050':'#3a0a0a');
      }
    });

    document.getElementById('cpuv').textContent=d.load;
    document.getElementById('vv').textContent=d.voltage===0?'미연결':d.voltage+'mV';

    const ab=document.getElementById('alertbox');
    if(d.alerts&&d.alerts.length>0){
      ab.innerHTML=d.alerts.map(a=>'<div class="alert-warn">⚠ '+a+'</div>').join('');
    }else{
      ab.innerHTML='<span class="alert-ok">● 정상</span>';
    }
  }).catch(()=>{});
}
setInterval(update,400);
update();
</script>
</body>
</html>"""
open('/home/mjtest/dashboard.html','w').write(html)
print('done')
PYEOF

python3 dasbboard_server.py
python3 dashboard_server.py
python3 << 'PYEOF'
with open('/home/mjtest/dashboard_server.py','r') as f:
    c = f.read()
c = c.replace("app.run(host='0.0.0.0',port=8080,threaded=True)", 
"""
import threading as _t

def run_video():
    from flask import Flask as _F, Response as _R
    import cv2 as _cv
    vapp = _F('video')
    vcam = _cv.VideoCapture(0)
    def gen():
        NL=b'\\r\\n'; BD=b'--frame'; CT=b'Content-Type: image/jpeg'
        while True:
            ok,fr=vcam.read()
            if not ok: continue
            _,buf=_cv.imencode('.jpg',fr)
            yield BD+NL+CT+NL+NL+buf.tobytes()+NL
    @vapp.route('/stream')
    def stream(): return _R(gen(),mimetype='multipart/x-mixed-replace; boundary=frame')
    vapp.run(host='0.0.0.0',port=8081,threaded=False)

_t.Thread(target=run_video,daemon=True).start()
app.run(host='0.0.0.0',port=8080,threaded=True)
""")
with open('/home/mjtest/dashboard_server.py','w') as f:
    f.write(c)
print('done')
PYEOF

python3 << 'PYEOF'
with open('/home/mjtest/dashboard.html','r') as f:
    c = f.read()
c = c.replace('src="/video"', 'src="http://192.168.0.42:8081/stream"')
with open('/home/mjtest/dashboard.html','w') as f:
    f.write(c)
print('done')
PYEOF

python3 dashboard_server.py
python3 << 'PYEOF'
lines = []
lines.append("from flask import Flask, Response, jsonify")
lines.append("from pymavlink import mavutil")
lines.append("import cv2, threading, math")
lines.append("")
lines.append("app = Flask(__name__)")
lines.append("master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)")
lines.append("master.wait_heartbeat()")
lines.append("data = {'roll':0,'pitch':0,'yaw':0,'vib_x':0,'vib_y':0,'vib_z':0,'xacc':0,'yacc':0,'zacc':0,'servo':[1500]*6,'load':0,'voltage':0,'alerts':[]}")
lines.append("")
lines.append("def mavlink_thread():")
lines.append("    while True:")
lines.append("        msg = master.recv_match(blocking=True, timeout=1)")
lines.append("        if not msg: continue")
lines.append("        t = msg.get_type()")
lines.append("        alerts = []")
lines.append("        if t == 'ATTITUDE':")
lines.append("            data['roll'] = round(math.degrees(msg.roll),2)")
lines.append("            data['pitch'] = round(math.degrees(msg.pitch),2)")
lines.append("            data['yaw'] = round(math.degrees(msg.yaw),2)")
lines.append("            if abs(data['roll'])>30: alerts.append('WARN: Roll 이상')")
lines.append("            if abs(data['pitch'])>30: alerts.append('WARN: Pitch 이상')")
lines.append("        elif t == 'VIBRATION':")
lines.append("            data['vib_x']=round(msg.vibration_x,4)")
lines.append("            data['vib_y']=round(msg.vibration_y,4)")
lines.append("            data['vib_z']=round(msg.vibration_z,4)")
lines.append("            if max(data['vib_x'],data['vib_y'],data['vib_z'])>0.3: alerts.append('WARN: 진동 과다')")
lines.append("        elif t == 'RAW_IMU':")
lines.append("            data['xacc']=msg.xacc")
lines.append("            data['yacc']=msg.yacc")
lines.append("            data['zacc']=msg.zacc")
lines.append("        elif t == 'SERVO_OUTPUT_RAW':")
lines.append("            data['servo']=[msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]")
lines.append("            for i,v in enumerate(data['servo']):")
lines.append("                if v!=0 and (v<1100 or v>1900): alerts.append('WARN: 모터'+str(i+1)+' PWM이상')")
lines.append("        elif t == 'SYS_STATUS':")
lines.append("            data['load']=msg.load")
lines.append("            data['voltage']=msg.voltage_battery")
lines.append("            if msg.load>800: alerts.append('WARN: CPU 과부하')")
lines.append("        if alerts: data['alerts']=alerts")
lines.append("        else: data['alerts']=[]")
lines.append("")
lines.append("threading.Thread(target=mavlink_thread,daemon=True).start()")
lines.append("")
lines.append("camera = cv2.VideoCapture(0)")
lines.append("")
lines.append("def gen_frames():")
lines.append("    NL=b'\\r\\n'")
lines.append("    BD=b'--frame'")
lines.append("    CT=b'Content-Type: image/jpeg'")
lines.append("    while True:")
lines.append("        ok,frame=camera.read()")
lines.append("        if not ok: continue")
lines.append("        _,buf=cv2.imencode('.jpg',frame)")
lines.append("        yield BD+NL+CT+NL+NL+buf.tobytes()+NL")
lines.append("")
lines.append("@app.route('/video')")
lines.append("def video(): return Response(gen_frames(),mimetype='multipart/x-mixed-replace; boundary=frame')")
lines.append("")
lines.append("@app.route('/api')")
lines.append("def api(): return jsonify(data)")
lines.append("")
lines.append("@app.route('/')")
lines.append("def index(): return open('/home/mjtest/dashboard.html').read()")
lines.append("")
lines.append("app.run(host='0.0.0.0',port=8080,threaded=True)")
with open('/home/mjtest/dashboard_server.py','w') as f:
    f.write('\n'.join(lines))
print('done')
PYEOF

python3 << 'PYEOF'
with open('/home/mjtest/dashboard.html','r') as f:
    c = f.read()
c = c.replace('src="http://192.168.0.42:8081/stream"', 'src="/video"')
with open('/home/mjtest/dashboard.html','w') as f:
    f.write(c)
print('done')
PYEOF

python3 dashboard_server.py
python3 << 'PYEOF'
lines = []
lines.append("from pymavlink import mavutil")
lines.append("import csv, time, math")
lines.append("")
lines.append("master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)")
lines.append("master.wait_heartbeat()")
lines.append("print('Connected. Logging...')")
lines.append("")
lines.append("filename = 'vib_log_' + str(int(time.time())) + '.csv'")
lines.append("f = open(filename, 'w', newline='')")
lines.append("w = csv.writer(f)")
lines.append("w.writerow(['timestamp','vib_x','vib_y','vib_z','vib_total','roll_deg','pitch_deg','yaw_deg','servo1','servo2','servo3','servo4','servo5','servo6'])")
lines.append("")
lines.append("vib = [0,0,0]")
lines.append("att = [0,0,0]")
lines.append("srv = [1500]*6")
lines.append("")
lines.append("while True:")
lines.append("    msg = master.recv_match(blocking=True, timeout=1)")
lines.append("    if not msg: continue")
lines.append("    t = msg.get_type()")
lines.append("    if t == 'VIBRATION':")
lines.append("        vib = [msg.vibration_x, msg.vibration_y, msg.vibration_z]")
lines.append("        total = (vib[0]**2+vib[1]**2+vib[2]**2)**0.5")
lines.append("        w.writerow([round(time.time(),3), round(vib[0],5), round(vib[1],5), round(vib[2],5), round(total,5), att[0], att[1], att[2], srv[0],srv[1],srv[2],srv[3],srv[4],srv[5]])")
lines.append("        f.flush()")
lines.append("        print(f'Vib total={total:.4f} Roll={att[0]} Pitch={att[1]}')")
lines.append("    elif t == 'ATTITUDE':")
lines.append("        att = [round(math.degrees(msg.roll),2), round(math.degrees(msg.pitch),2), round(math.degrees(msg.yaw),2)]")
lines.append("    elif t == 'SERVO_OUTPUT_RAW':")
lines.append("        srv = [msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]")
with open('/home/mjtest/vib_logger.py','w') as f:
    f.write('\n'.join(lines))
print('done')
PYEOF

python3 vib_logger.py
ls vib_log_*.csv
ls vib_log_*.csv
python3 -c "
f1=open('vib_log_1782419368.csv').readlines()
f2=open('vib_log_1782419624.csv').readlines()
print('모터OFF:', len(f1)-1, '행')
print('모터ON:', len(f2)-1, '행')
"
cd /path/to/your/csv/folder
ls
nano vibration_analysis.py
python3 vibration_analysis.py
pip3 install pandas matplotlib
python3 vibration_analysis.py
sudo apt update && sudo apt install python3-pandas python3-matplotlib -y
python3 vibration_analysis.py
ls
scp mjtest@192.168.0.42:/home/mjtest/*.* .
cd ~
cd ~/mjtest
python vib_logger.py
ls -lt *.csv
python vib_logger.py
ls -lt *.csv
scp mjtest@192.168.0.42:*.csv C:\Users\User\mjtest\
scp mjtest@192.168.0.42:*.csv /Users/User/mjtest/
scp mjtest@192.168.0.42:*.csv /User/User/mjtest/
nano pwm_test.py
python3 pwm_test.py
ls /dev/ttyACM* /dev/ttyUSB*
dmesg | tail -n 20
pkill -f python
pkill -f mavproxy
ls /dev/ttyACM* /dev/ttyUSB*
nano plot_vib.py
python3 plot_vib.py
nano plot_vib.py
python3 plot_vib.py
nano plot_vib.py
python3 plot_vib.py
nano plot_vib.py
python3 plot_vib.py
nano plot_vib.py
python3 plot_vib.py
