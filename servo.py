from pymavlink import mavutil

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)
master.wait_heartbeat()

while True:
    msg = master.recv_match(type='SERVO_OUTPUT_RAW', blocking=True)

    if msg:
        print(msg)
