from pymavlink import mavutil

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)

print("Waiting heartbeat...")
master.wait_heartbeat()

print("Connected!")

while True:
    msg = master.recv_match(type='ATTITUDE', blocking=True)

    print(
        f"Roll={msg.roll:.3f} "
        f"Pitch={msg.pitch:.3f} "
        f"Yaw={msg.yaw:.3f}"
    )
