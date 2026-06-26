import time
import sys
from pymavlink import mavutil

def set_motor_pwm(master, servo_no, pwm_value):
    """
    MAVLink MAV_CMD_DO_SET_SERVO 명령을 사용하여 
    지정한 핀(servo_no)에 정확한 PWM 값을 출력합니다.
    """
    master.mav.command_long_send(
        master.target_system,
        master.target_component,
        mavutil.mavlink.MAV_CMD_DO_SET_SERVO,
        0,
        servo_no,    # 모터 핀 번호 (예: 1번 모터 -> 1)
        pwm_value,   # 출력할 정확한 PWM 값 (1100 ~ 1900)
        0, 0, 0, 0, 0
    )
    print(f"📥 [MAVLink] Motor {servo_no} -> PWM {pwm_value}us 송신 완료")

def main():
    # 1. 픽스호크 연결 (기존 포트 및 보드레이트 확인 필요)
    # 일반적으로 USB 연결 시 '/dev/ttyACM0' 사용
    connection_port = '/dev/ttyACM0'
    baud_rate = 115200
    
    print(f"🔄 Pixhawk 연결 중... ({connection_port})")
    try:
        master = mavutil.mavlink_connection(connection_port, baud=baud_rate)
        master.wait_heartbeat()
        print("✅ Pixhawk 연결 성공! Heartbeat 수신 완료.")
    except Exception as e:
        print(f"❌ 연결 실패: {e}")
        sys.exit(1)

    # 2. 제어할 모터 번호 및 테스트할 PWM 단계 정의
    MOTOR_NO = 1  # 테스트할 모터 번호 (Motor 1)
    
    # 안전을 위해 1100(정지/정방향 최소)부터 1500(중립 또는 최대)까지 단계별 설정
    # 기체 및 ESC 세팅에 따라 최대 범위를 조절하세요 (보통 1100 ~ 1900)
    pwm_stages = [1100, 1200, 1300, 1400, 1500] 
    
    try:
        for pwm in pwm_stages:
            print("\n" + "="*40)
            print(f"🚀 현재 단계: PWM {pwm} 테스트 시작")
            print("="*40)
            
            # PWM 주입
            set_motor_pwm(master, MOTOR_NO, pwm)
            
            # 각 단계별 유지 시간 (예: 10초 동안 모터를 돌리며 진동 관측)
            # 이 시간 동안 기존에 만들어둔 'vib_logger.py'를 다른 터미널에서 실행하면 됩니다.
            maintain_seconds = 10
            for i in range(maintain_seconds, 0, -1):
                print(f"⏱️ {pwm}us 출력 유지 중... ({i}초 남음)", end='\r')
                time.sleep(1)
            print(f"\n✅ {pwm}us 테스트 완료")

    except KeyboardInterrupt:
        print("\n⚠️ 사용자에 의해 테스트가 중단되었습니다.")
        
    finally:
        # 3. 안전을 위한 모터 정지 (안전 종료 처리)
        print("\n🛑 안전을 위해 모터를 초기 상태(PWM 1100)로 되돌립니다.")
        set_motor_pwm(master, MOTOR_NO, 1100)
        print("🏁 테스트 프로그램이 안전하게 종료되었습니다.")

if __name__ == "__main__":
    main()
