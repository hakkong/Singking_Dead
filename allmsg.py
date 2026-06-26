from pymavlink import mavutil

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)
master.wait_heartbeat()

seen = set()

while True:
    msg = master.recv_match(blocking=True)

    if not msg:
        continue

    name = msg.get_type()

    if name not in seen:
        seen.add(name)
        print(name)
