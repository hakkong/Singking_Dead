from pymavlink import mavutil
import csv, time, math

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)
master.wait_heartbeat()
print('Connected. Logging...')

filename = 'vib_log_' + str(int(time.time())) + '.csv'
f = open(filename, 'w', newline='')
w = csv.writer(f)
w.writerow(['timestamp','vib_x','vib_y','vib_z','vib_total','roll_deg','pitch_deg','yaw_deg','servo1','servo2','servo3','servo4','servo5','servo6'])

vib = [0,0,0]
att = [0,0,0]
srv = [1500]*6

while True:
    msg = master.recv_match(blocking=True, timeout=1)
    if not msg: continue
    t = msg.get_type()
    if t == 'VIBRATION':
        vib = [msg.vibration_x, msg.vibration_y, msg.vibration_z]
        total = (vib[0]**2+vib[1]**2+vib[2]**2)**0.5
        w.writerow([round(time.time(),3), round(vib[0],5), round(vib[1],5), round(vib[2],5), round(total,5), att[0], att[1], att[2], srv[0],srv[1],srv[2],srv[3],srv[4],srv[5]])
        f.flush()
        print(f'Vib total={total:.4f} Roll={att[0]} Pitch={att[1]}')
    elif t == 'ATTITUDE':
        att = [round(math.degrees(msg.roll),2), round(math.degrees(msg.pitch),2), round(math.degrees(msg.yaw),2)]
    elif t == 'SERVO_OUTPUT_RAW':
        srv = [msg.servo1_raw,msg.servo2_raw,msg.servo3_raw,msg.servo4_raw,msg.servo5_raw,msg.servo6_raw]