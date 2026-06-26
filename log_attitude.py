from pymavlink import mavutil
import csv
import time

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)

print("Waiting heartbeat...")
master.wait_heartbeat()
print("Connected!")

with open("attitude_log.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "time",
        "roll",
        "pitch",
        "yaw"
    ])

    while True:
        msg = master.recv_match(
            type='ATTITUDE',
            blocking=True
        )

        writer.writerow([
            time.time(),
            msg.roll,
            msg.pitch,
            msg.yaw
        ])

        print(
            f"Roll={msg.roll:.3f} "
            f"Pitch={msg.pitch:.3f} "
            f"Yaw={msg.yaw:.3f}"
        )
