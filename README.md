# Singking Dead - ROV Monitoring System

## 프로젝트 개요
Pixhawk 2.4.8 + Raspberry Pi 4B 기반 ROV 실시간 모니터링 시스템

## 하드웨어 구성
- Pixhawk 2.4.8 PRO Clone (ArduSub 4.5.7)
- Raspberry Pi 4B (Debian Trixie Lite 64bit)
- BLDC 모터 x6 + 30A ESC x6
- USB Webcam

## 통신 구조
PC (QGroundControl)

↕ USB

Pixhawk (ArduSub)

↕ UART TELEM2 (921600 baud)

Raspberry Pi 4B

↕ WiFi (Flask HTTP)

브라우저 대시보드




## 주요 기능
- 실시간 웹 대시보드 (Flask + Three.js + Chart.js)
- MAVLink 데이터 수신 (ATTITUDE, VIBRATION, SERVO_OUTPUT_RAW, SYS_STATUS 등)
- 3D 자세 시각화 (Roll/Pitch/Yaw)
- 실시간 그래프 (자세각, 진동)
- 모터 배치도 및 PWM 상태 표시
- 이상징후 경고 시스템
- USB 웹캠 실시간 스트리밍

## 파일 구성
| 파일 | 설명 |
|------|------|
| dashboard_server.py | Flask 기반 메인 서버 |
| dashboard.html | 대시보드 UI |
| vib_logger.py | 진동 데이터 CSV 로거 |
| vibration_analysis.py | 진동 분석 스크립트 |
| vib_log_*.csv | 진동 실험 데이터 |

## 실행 방법
```bash
python3 dashboard_server.py
# 브라우저: http://192.168.0.42:8080
```

## 진동 분석 결과
모터 OFF/ON 상태별 X/Y/Z축 진동 비교 실험 수행
- 모터 OFF 기준 노이즈: ~0.03 m/s²
- 모터 ON 피크: 최대 1.5 m/s² (특정 모터 이상 시)
