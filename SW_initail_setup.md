# ROV 시스템 구축 기술 매뉴얼
## Pixhawk 2.4.8 + Raspberry Pi 4B + ArduSub

---

# 목차

1. [사전 준비](#1-사전-준비)
2. [Pixhawk 펌웨어 플래싱](#2-pixhawk-펌웨어-플래싱)
3. [Pixhawk 초기 설정 (QGroundControl)](#3-pixhawk-초기-설정)
4. [ESC 및 모터 테스트](#4-esc-및-모터-테스트)
5. [Raspberry Pi OS 설치](#5-raspberry-pi-os-설치)
6. [Raspberry Pi 초기 설정](#6-raspberry-pi-초기-설정)
7. [UART 통신 설정](#7-uart-통신-설정)
8. [Pixhawk SERIAL2 파라미터 설정](#8-pixhawk-serial2-파라미터-설정)
9. [MAVLink 통신 구축](#9-mavlink-통신-구축)
10. [USB 웹캠 연결](#10-usb-웹캠-연결)
11. [웹 대시보드 구축](#11-웹-대시보드-구축)
12. [진동 데이터 수집 및 분석](#12-진동-데이터-수집-및-분석)
13. [GitHub 업로드](#13-github-업로드)
14. [자주 발생하는 오류 총정리](#14-자주-발생하는-오류-총정리)

---

# 1. 사전 준비

## 1-1. 필요 하드웨어

| 장비 | 사양 | 비고 |
|------|------|------|
| Pixhawk | 2.4.8 PRO Clone | ArduSub 호환 |
| Raspberry Pi | 4B (RAM 4GB 권장) | |
| ESC | 30A 2-4S | 6개 |
| BLDC 모터 | D4018 등 | 6개 |
| 배터리 | 3S 5200mAh LiPo | 2개 권장 |
| microSD | 32GB 이상 | RPi용 |
| USB-C 케이블 | 데이터 전송 가능한 것 | Pixhawk-PC 연결용 |
| USB-C 충전기 | RPi 4B 전용 (5V 3A) | RPi 전원용 |
| 점퍼 케이블 | 암수 | TELEM2-RPi GPIO 연결용 |

> ⚠️ USB-C 케이블은 반드시 데이터 전송 지원 가능 제품이어야 한다.
> 충전 전용 케이블로는 Pixhawk가 PC에 인식되지 않을 수 있다.

## 1-2. 필요 소프트웨어 (Windows PC)

- **QGroundControl (QGC)**: https://qgroundcontrol.com
- **Raspberry Pi Imager**: https://www.raspberrypi.com/software/
- **Windows PowerShell** (기본 설치됨)
- **Python 3.x** (진동 분석용, Windows에 별도 설치)

## 1-3. 네트워크 환경

- RPi와 PC가 **같은 WiFi 네트워크**에 연결되어야 SSH 접속 가능
- 개인 핫스팟 사용 시: iPhone의 경우 **WiFi 호환성 최대화** 옵션 활성화 필요
- 학교/공용 WiFi는 기기 간 통신이 막혀있을 수 있으므로 전용 공유기 또는 개인 핫스팟 권장

---
>RPi imager로 쓰기 시작 전 세팅에서 ssh 키기
<img width="835" height="581" alt="image" src="https://github.com/user-attachments/assets/e9226638-7cc0-4be0-b8c8-4c1543a04eee" />


# 2. Pixhawk 펌웨어 플래싱

## 2-1. 개요

Pixhawk를 처음 구매하면 기본 펌웨어가 설치되어 있거나 비어 있을 수 있다.
수중 ROV 용도로는 반드시 **ArduSub** 펌웨어를 설치해야 한다.

## 2-2. 순서

1. **QGroundControl 실행** (먼저 실행)
2. **Pixhawk USB-C 케이블로 PC에 직접 연결**
   - 라즈베리파이 거치지 말고 PC에 직접 연결
3. **QGC → Vehicle Setup (기어 아이콘) → Firmware 탭**
4. **USB 케이블 분리 후 재연결** → 펌웨어 설치 팝업 자동 등장
5. **ArduPilot → ArduSub 선택**
6. **Standard Version (stable)** 선택 후 OK
7. 보드 선택 화면에서 **Pixhawk 1** 선택 (2.4.8은 Pixhawk 1 계열)
8. 버전 선택: **ArduSub 4.5.7** (suffix 없는 것)
   - `1M` 버전: 플래시 메모리 제한 버전, 기능 축소 → 선택 X
   - `bdshot` 버전: BLHeli_32 ESC 전용 → 수중 ESC에 해당 없음 → 선택 X
9. 플래싱 완료까지 대기 (2~3분) — **절대 케이블 분리 금지**
10. 재부팅 완료 후 QGC 상단에 Vehicle 인식되면 성공

<img width="354" height="679" alt="image" src="https://github.com/user-attachments/assets/7682d742-f3f2-4a16-961e-2a97062e0dc7" />
<img width="964" height="1021" alt="image" src="https://github.com/user-attachments/assets/ee32cbdc-5dbe-41e1-9df3-213d370c1b51" />


## 2-3. 정상 결과

```
QGC 상단에 "ArduSub" 차량 인식됨
LED: FMU 초록불, ACT 파랑 깜빡
부저에서 부팅음 발생
```
<img width="954" height="1020" alt="image" src="https://github.com/user-attachments/assets/37a1e2cb-aa4e-4d8d-b37e-945136b30f71" />

## 2-4. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| 펌웨어 팝업이 안 뜸 | Firmware 탭 들어간 상태에서 케이블 재연결 안 함 | Firmware 탭 열고 케이블 뽑았다 꽂기 |
| Vehicle 인식 안 됨 | USB 케이블이 충전 전용 | 데이터 전송 지원 케이블로 교체 |
| 장치관리자에서 노란 느낌표 | 드라이버 미설치 | QGC 설치 폴더에서 드라이버 수동 설치 |
| BlueOS로 설치 실패 | 2.4.8에서 검증 미지원 | 반드시 PC QGC 직접 플래싱만 사용 |
| SERIAL2_BAUD가 안 바뀜 | COM4를 NMEA GPS로 등록해둔 경우 | QGC Comm Links에서 COM4 → disabled로 변경 |

> ⚠️ 중요!! QGC의 Comm Links 설정에서 특정 포트를 NMEA GPS로 등록해두면
> 해당 포트가 Pixhawk 포트와 충돌하여 차량 인식이 안 된다.
> Application Settings → Comm Links에서 NMEA GPS 장치를 **disabled**로 변경해야 한다.

---

# 3. Pixhawk 초기 설정

## 3-1. 센서 캘리브레이션

QGC → Vehicle Setup → Sensors 탭에서 순서대로 진행

### Accelerometer (가속도 센서)

1. Sensors → Accelerometer 클릭
2. 비행 컨트롤러 회전 설정: **None** (기본값 유지)
3. OK 클릭
4. 화면 안내에 따라 Pixhawk를 **6방향**으로 차례로 놓기
   - 정면, 뒤집기, 왼쪽, 오른쪽, 위, 아래
5. 완료 후 **기체 리부팅** (USB 뽑았다 꽂기)

> ⚠️ 캘리브레이션 도중 탭을 이동하면 다시 처음부터 해야 한다.
> 캘리브레이션은 언제든 덮어쓰기 가능하므로 실수 시 다시 시작하면 된다.
> 일단 한번 캘리브레이션 한 뒤에 재작성하는 방향으로 진행해야 한다.
<img width="1919" height="1012" alt="image" src="https://github.com/user-attachments/assets/82dda18d-9c0d-4fbf-a397-405cbc7939fc" />

### Compass (지자기 센서)

1. Sensors → Compass 클릭
2. Fast Calibration 체크 해제
3. OK 클릭
4. Pixhawk를 **철제 물체에서 최대한 멀리** 떨어진 곳에서 모든 방향으로 회전
5. 바 색상 확인:
   - 초록: 정상
   - 노랑: 캘리브레이션 불완전 (재시도 권장)
   - 빨강: 사용 불가
6. OK → 기체 리부팅

   <img width="1918" height="1005" alt="image" src="https://github.com/user-attachments/assets/09372ddd-d56b-415c-b479-1a74ed9f3843" />


**캘리브레이션 실패가 반복될 경우:**
수중 환경에서는 모터/프레임의 자기 간섭으로 Compass 정확도가 떨어지므로
Parameters에서 `COMPASS_ENABLE = 0`으로 비활성화하고 진행 가능.

### Gyroscope

1. Sensors → Gyroscope 클릭
2. Pixhawk를 움직이지 않고 정지 상태 유지
3. 자동 완료

## 3-2. Frame 설정

QGC → Vehicle Setup → 프레임 탭

| 프레임 선택 | 조건 |
|------------|------|
| BlueROV2/Vectored | 수평 4개 대각선 + 수직 2개 (본 프로젝트) |
| Vectored-6DOF | 수평 4개 + 수직 4개 |
| SimpleROV-3/4/5 | 단순 구성 |

> 프레임 변경 후 반드시 **기체 리부팅** 필요
<img width="1918" height="898" alt="image" src="https://github.com/user-attachments/assets/240bc6cf-4d34-4682-b1cc-5a4811205f83" />


## 3-3. 주요 파라미터 설정

QGC → Vehicle Setup → 파라미터 탭에서 검색 후 변경

| 파라미터 | 값 | 설명 |
|---------|-----|------|
| SERIAL2_PROTOCOL | 2 | MAVLink 2 통신 |
| SERIAL2_BAUD | 921 | 921600 baud |
| ARMING_CHECK | 0 | 초기 테스트 시 비활성화 (실운용 시 복원) |
| JS_GAIN_DEFAULT | 0.5 | 조이스틱 기본 게인 |
| PILOT_SPEED_UP | 50 | 수직 상승 속도 cm/s |
| PILOT_SPEED_DN | 50 | 수직 하강 속도 cm/s |
| BRD_SER2_RTSCTS | 0 | RTS/CTS 비활성화 (3선 연결 시 필수) |
| COMPASS_ENABLE | 0 | 수중 환경에서 Compass 비활성화 |

> ⚠️ 파라미터 변경 후 반드시 **Pixhawk 재부팅** (USB 뽑았다 꽂기)

## 3-4. LED 상태 해석

| LED | 상태 | 의미 |
|-----|------|------|
| FMU 초록 | 두 개 모두 | 펌웨어 정상 실행 |
| ACT 파랑 | 깜빡임 | Disarmed 대기 (정상) |
| B/E 주황 | 하나만 | 부저/전원 관련 경고 (큰 문제 아님) |
| Safety Switch | 깜빡임 | Disarmed 상태 (정상) |

## 3-5. 오류 및 해결

| 오류 메시지 | 원인 | 해결 |
|------------|------|------|
| PreArm: IOMCU is unhealthy | IO 코프로세서 통신 문제 | USB 뽑았다 꽂기로 재부팅 |
| Internal errors 0x3000 | 펌웨어 내부 오류 | 재부팅으로 대부분 해결 |
| Compass calibrated requires reboot | 캘리브레이션 후 재부팅 안 함 | USB 뽑았다 꽂기 |
| Compass performance degraded | 주변 자기 간섭 | 철제 물체에서 멀리 이동 후 재시도 |
| Backup location parameters are missing | GPS 미연결 | 수중 ROV는 정상 (무시 가능) |

---

# 4. ESC 및 모터 테스트

## 4-1. 물리 배선

Pixhawk MAIN OUT 핀 순서 (BlueROV2/Vectored 기준):

| MAIN OUT | 추진기 위치 |
|----------|------------|
| 1 | 전방 우측 대각선 수평 |
| 2 | 전방 좌측 대각선 수평 |
| 3 | 후방 우측 대각선 수평 |
| 4 | 후방 좌측 대각선 수평 |
| 5 | 우측 수직 |
| 6 | 좌측 수직 |

## 4-2. ESC 캘리브레이션

ESC는 배터리 연결할 때마다 스로틀 범위를 인식시켜야 한다.
이 과정을 ESC 캘리브레이션이라 한다.

**순서 (ESC 1개씩):**

1. 배터리 분리 상태에서 ESC 1번만 Pixhawk MAIN OUT 1번에 연결
2. QGC → Vehicle Setup → 모터 탭
3. 토글(스위치) 켜기
4. 슬라이더 1번 **최대로** 올린 상태 유지
5. 배터리 연결 → 삐~ 소리
6. 슬라이더 **최저로** 내리기 → 삐삐 소리 → 캘리브레이션 완료
7. 배터리 빼고 다음 ESC 반복

> ⚠️ 6개 동시에 연결한 상태에서 개별 캘리브레이션 시
> 배터리 전류가 부족하여 일부 ESC만 반응할 수 있다.
> 개별 캘리브레이션 후 6개 동시 연결 테스트 진행 권장.

<img width="1918" height="998" alt="image" src="https://github.com/user-attachments/assets/f540df94-0349-4513-8714-ec7e77acc61d" />


## 4-3. 모터 테스트

**배터리 연결 전 주의:**
- 모터/프로펠러 주변에 손/물건 없애기
- 프로펠러 미장착 상태 권장

**테스트 순서:**
1. 배터리 연결
2. 모터 탭 토글 켜기
3. 모든 슬라이더를 한 번씩 **최저로 내렸다가 올리기** (ESC 시동 신호)
4. 슬라이더 1번만 올려서 어떤 위치 모터가 도는지 확인
5. 프레임 그림과 비교하여 위치 일치 여부 확인
6. 예상과 다르면 ESC 신호선 핀 번호 교체

**슬라이더 기능:**
- 위로 올리기: 정방향 회전
- 아래로 내리기: 역방향 회전
- 놓으면 자동 정지 (안전장치)
- 체크박스: 회전 방향 반전 (적용 후 재부팅 필요)

## 4-4. 회전 방향 기준 (BlueROV2/Vectored)

| 모터 | 정방향 |
|------|--------|
| 1 (전방 우측) | 시계방향 |
| 2 (전방 좌측) | 반시계방향 |
| 3 (후방 우측) | 반시계방향 |
| 4 (후방 좌측) | 시계방향 |
| 5, 6 (수직) | 방향 무관 |

## 4-5. 오류 및 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| 슬라이더 올려도 모터 안 돌아감 | ESC 캘리브레이션 미완료 | ESC 캘리브레이션 재수행 |
| 일부 모터만 덜덜거림 | 해당 ESC 캘리브레이션 실패 | 해당 ESC만 개별 재캘리브레이션 |
| 슬라이더 내렸다 올려야만 작동 | 정상 동작 (ESC 시동 신호) | 매 배터리 연결 시 정상 절차 |
| 토글 꺼도 모터 안 멈춤 | ESC가 신호를 못 받는 상태 | 배터리 즉시 분리 |
| 3번 모터만 과다 회전 | ESC 캘리브레이션 불균형 | 해당 ESC 재캘리브레이션 |

---

# 5. Raspberry Pi OS 설치

## 5-1. 개요

Raspberry Pi는 모니터/키보드 없이 **헤드리스 설치**가 가능하다.
Raspberry Pi Imager의 고급 설정에서 WiFi와 SSH를 미리 설정하면
Windows PC에서 바로 SSH로 접속할 수 있다.

## 5-2. 설치 순서

1. **Raspberry Pi Imager 실행**
2. 기기 선택: **Raspberry Pi 4**
3. OS 선택: **Raspberry Pi OS Lite (64-bit)**
   - Desktop 버전은 불필요한 GUI 포함 → Lite 권장
   - Lite는 모니터 없이 SSH로만 운용하는 경우에 최적
4. 저장 장치: microSD 카드 선택
5. **고급 설정 (Ctrl+Shift+X 또는 ⚙️ 아이콘)** 진입

**고급 설정 항목:**

| 항목 | 설정값 |
|------|--------|
| 호스트명 | mjtest (또는 원하는 이름) |
| 사용자명 | mjtest |
| 비밀번호 | 기억하기 쉬운 값 |
| WiFi SSID | 연결할 네트워크 이름 |
| WiFi 비밀번호 | 네트워크 비밀번호 |
| WiFi 국가 | **KR** (필수 — 없으면 WiFi 연결 안 됨) |
| SSH 활성화 | ✅ 체크 (비밀번호 인증) |

6. 저장 → 쓰기 시작
7. 완료 후 microSD RPi에 삽입
8. RPi 전용 USB-C 충전기로 전원 공급
9. 1~2분 부팅 대기

## 5-3. SSH 접속 (Windows PowerShell)

```powershell
ssh 사용자명@호스트명.local
# 예시
ssh mjtest@mjtest.local
```

비밀번호 입력 시 화면에 아무것도 표시되지 않는 것이 정상.

**접속 성공 시:**
```
mjtest@mjtest:~ $
```
> mjtest로 진행하였음.

## 5-4. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| Could not resolve hostname | RPi가 WiFi에 연결 안 됨 | WiFi 국가(KR) 설정 확인 후 재플래싱 |
| Connection refused | SSH 비활성화 상태 | Imager 고급 설정에서 SSH 활성화 확인 |
| RPi가 공유기 목록에 안 뜸 | iPhone 핫스팟 WiFi 꺼짐 | 핫스팟 설정 → 호환성 최대화 활성화 |
| 호스트명.local로 접속 불가 | IP로 직접 접속 | 공유기/핫스팟에서 RPi IP 확인 후 사용 |

---

# 6. Raspberry Pi 초기 설정

## 6-1. 패키지 업데이트

SSH 접속 후:

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

<img width="1170" height="841" alt="image" src="https://github.com/user-attachments/assets/32eda809-5985-4f7b-ae0e-970f8634417f" />


## 6-2. 필수 패키지 설치

```bash
sudo apt-get install python3-pip python3-dev screen -y
```
<img width="1108" height="525" alt="image" src="https://github.com/user-attachments/assets/814a597e-d527-4880-acec-0e9217ab18c4" />


## 6-3. Python 패키지 설치

```bash
pip3 install future pymavlink MAVProxy --break-system-packages
```

> ⚠️ `--break-system-packages` 옵션이 없으면 오류 발생
> 최신 Debian(Trixie)은 시스템 Python 환경을 보호하므로 이 옵션이 필요하다.

<img width="1173" height="720" alt="image" src="https://github.com/user-attachments/assets/ca397485-e41f-4306-a13e-3e0293306cdf" />

**오류 발생 시:**

| 오류 | 원인 | 해결 |
|------|------|------|
| externally-managed-environment | --break-system-packages 옵션 누락 | 옵션 추가 후 재실행 |
| incomplete-download | 네트워크 불안정 | --resume-retries 5 옵션 추가 후 재실행 |
| ModuleNotFoundError: No module named 'serial' | pyserial 미설치 | `pip3 install pyserial --break-system-packages` |

## 6-4. OpenCV 설치

```bash
sudo apt install python3-opencv -y
```

## 6-5. Flask 설치

```bash
pip3 install flask --break-system-packages
```

---

# 7. UART 통신 설정

## 7-1. 개요

Raspberry Pi 4B는 기본적으로 GPIO UART(ttyAMA0)를 블루투스가 사용한다.
Pixhawk와 통신하려면 블루투스를 비활성화하여 ttyAMA0를 확보해야 한다.

## 7-2. raspi-config에서 시리얼 포트 활성화

```bash
sudo raspi-config
```

1. **3 Interface Options** (버전에 따라 5 Interfacing Options)
2. **I6 Serial Port** (버전에 따라 P6 Serial)
3. "Would you like a login shell to be accessible over serial?" → **No**
4. "Would you like the serial port hardware to be enabled?" → **Yes**
5. OK → Finish → 재부팅 보류 (No)

<img width="1163" height="1002" alt="image" src="https://github.com/user-attachments/assets/ace32d53-b19b-4658-b850-1c028daab4f2" />

## 7-3. 블루투스 비활성화

```bash
sudo nano /boot/firmware/config.txt
```

> ⚠️ 구버전 OS는 `/boot/config.txt`, 최신 Bookworm/Trixie는 `/boot/firmware/config.txt`

파일 맨 아래에 추가:

```
enable_uart=1
dtoverlay=disable-bt
```

> `enable_uart=1`이 이미 있으면 `dtoverlay=disable-bt`만 추가

저장: **Ctrl+O → Enter → Ctrl+X**

```bash
sudo systemctl disable hciuart
sudo systemctl disable bluetooth
sudo reboot
```

> `Failed to disable unit: Unit hciuart.service does not exist`는 정상 (최신 OS에서 없는 경우)

## 7-4. ttyAMA0 포트 확인

재부팅 후 SSH 재접속:

```bash
ls -l /dev/ttyAMA0
```

**정상 출력:**
```
crw-rw---- 1 root dialout 204, 64 Jun 26 00:04 /dev/ttyAMA0
```
<img width="1170" height="458" alt="image" src="https://github.com/user-attachments/assets/24ffef6f-b90b-4915-a2f6-d94fe6ab7e93" />

## 7-5. TELEM2 ↔ Raspberry Pi 배선

| Pixhawk TELEM2 핀 | Raspberry Pi GPIO 핀 |
|-------------------|---------------------|
| Pin 2 (TX) | GPIO 15 (RX, 물리 핀 10번) |
| Pin 3 (RX) | GPIO 14 (TX, 물리 핀 8번) |
| Pin 6 (GND) | GND (물리 핀 6번) |
| Pin 1 (VCC 5V) | **연결하지 않음** |

**TELEM2 커넥터 핀 배열 (왼쪽부터):**
```
(1)VCC  (2)TX  (3)RX  (4)CTS  (5)RTS  (6)GND
```

> ⚠️ **TX-RX는 반드시 교차 연결** — Pixhawk TX → RPi RX, Pixhawk RX → RPi TX
> 같은 방향으로 연결(TX→TX)하면 통신이 되지 않는다.
>
> ⚠️ **VCC(5V) 절대 연결 금지** — RPi와 Pixhawk가 각각 별도 전원을 사용하므로
> VCC를 연결하면 전원 레일이 섞여 이상 동작 및 기기 손상 가능
> RPi가 Pixhawk에서만 전원 공급을 받을 경우 연결

## 7-6. 오류 및 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| ttyAMA0 없음 | BT 비활성화 미완료 | raspi-config 및 config.txt 재확인 후 재부팅 |
| 통신은 되는데 데이터 없음 | TX-RX 방향 잘못 연결 | 핀 8번과 10번 선 교체 |
| I/O Error, 명령어 안 먹힘 | VCC 연결로 인한 전원 충돌 | VCC 선 제거 후 재부팅 |
| SSH Connection reset | RPi 파일시스템 손상 | 전원 완전 제거 후 재부팅 |

---

# 8. Pixhawk SERIAL2 파라미터 설정

Pixhawk를 PC에 USB 직결한 상태에서 QGC → 파라미터 탭에서 설정:

| 파라미터 | 값 | 설명 |
|---------|-----|------|
| SERIAL2_PROTOCOL | 2 | MAVLink 2 |
| SERIAL2_BAUD | 921 | 921600 baud |
| BRD_SER2_RTSCTS | 0 | RTS/CTS 비활성화 |

설정 후 Pixhawk 재부팅 (USB 뽑았다 꽂기)

<img width="1120" height="812" alt="image" src="https://github.com/user-attachments/assets/7fd6089b-8dcc-40b6-b393-b7e2a3d83a98" />

---

# 9. MAVLink 통신 구축

## 9-1. UART 포트 권한 설정

```bash
sudo chmod 666 /dev/ttyAMA0
```

## 9-2. UART 데이터 수신 확인 (Raw)

```bash
sudo apt install xxd -y
timeout 5 cat /dev/ttyAMA0 | xxd
```

**정상 출력 (데이터가 들어오는 경우):**
```
00000000: 00ff 94ff f1fc a700 ...
```

출력이 없으면 배선 또는 파라미터 문제.

## 9-3. pymavlink Heartbeat 수신 확인

```bash
python3
```

Python 인터랙티브 모드에서:

```python
from pymavlink import mavutil

master = mavutil.mavlink_connection('/dev/ttyAMA0', baud=921600)
master.wait_heartbeat()
print("HEARTBEAT OK")
```

**정상:** 몇 초 내에 `HEARTBEAT OK` 출력
**비정상:** 계속 멈춰있음 → 배선 또는 BRD_SER2_RTSCTS 문제

## 9-4. 데이터 수신 확인

```python
msg = master.recv_match(type='ATTITUDE', blocking=True)
print(msg.roll, msg.pitch, msg.yaw)

msg = master.recv_match(type='SYS_STATUS', blocking=True)
print(msg.voltage_battery)
```

## 9-5. 수신 가능한 MAVLink 메시지 목록

| 메시지 | 내용 |
|--------|------|
| ATTITUDE | Roll, Pitch, Yaw (라디안) |
| VIBRATION | 진동 X, Y, Z |
| RAW_IMU | 가속도, 자이로, 자기 |
| SERVO_OUTPUT_RAW | 모터 1~6 PWM 값 |
| SYS_STATUS | CPU 부하, 배터리 전압 |
| RC_CHANNELS | RC 입력 채널 |
| HEARTBEAT | 연결 상태 확인 |

## 9-6. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| ModuleNotFoundError: No module named 'serial' | pyserial 미설치 | `pip3 install pyserial --break-system-packages` |
| wait_heartbeat() 무한 대기 | 배선 TX-RX 방향 오류 또는 BRD_SER2_RTSCTS=Auto | 배선 교차 확인, BRD_SER2_RTSCTS=0으로 변경 |
| voltage_battery = 0 | 배터리 모니터 모듈 미연결 | 전원 모듈 POWER 포트 연결 필요 |

---

# 10. USB 웹캠 연결

## 10-1. 카메라 인식 확인

```bash
v4l2-ctl --list-devices
```

USB 웹캠은 다음과 같이 표시됨:
```
HD Camera: HD Camera (usb-...):
    /dev/video0
    /dev/video1
```

나머지 `/dev/video10` 이상은 RPi 내부 ISP 장치이므로 무시.

## 10-2. OpenCV 카메라 테스트

```bash
python3
```

```python
import cv2

cap = cv2.VideoCapture(0)
print(cap.isOpened())  # True이면 성공

ret, frame = cap.read()
print(ret)             # True이면 성공
print(frame.shape)     # (480, 640, 3) 등

cv2.imwrite("test.jpg", frame)
cap.release()
```

> ⚠️ SSH 환경에서는 `cv2.imshow()`가 동작하지 않는다.
> 반드시 `cv2.imwrite()`로 파일 저장 후 확인해야 한다.

## 10-3. 파일 Windows로 전송

Windows PowerShell에서:

```powershell
scp mjtest@192.168.0.42:/home/mjtest/test.jpg .
```

## 10-4. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| cap.isOpened() = False | 카메라 인식 안 됨 | USB 뽑았다 꽂기 후 재시도 |
| can't open camera by index | 이전 프로세스가 카메라 점유 | 서버 재시작 또는 `sudo fuser /dev/video0` 확인 |
| imwrite 실패 (img.empty) | frame이 비어있음 | cap.release() 후 다시 VideoCapture(0) |

---

# 11. 웹 대시보드 구축

## 11-1. 구조

```
Pixhawk (ArduSub)
    ↕ UART MAVLink
Raspberry Pi
    ├── dashboard_server.py (Flask, port 8080)
    │       ├── /        → dashboard.html
    │       ├── /api     → JSON 데이터
    │       └── /video   → MJPEG 스트리밍
    └── dashboard.html (Three.js, Chart.js)

PC 브라우저 → http://192.168.0.42:8080
```

## 11-2. 대시보드 서버 실행

```bash
python3 dashboard_server.py
```

**정상 출력:**
```
* Running on http://0.0.0.0:8080
* Running on http://192.168.0.42:8080
```

## 11-3. 브라우저 접속

```
http://192.168.0.42:8080
```

## 11-4. 대시보드 기능

| 기능 | 내용 |
|------|------|
| CAMERA | USB 웹캠 실시간 영상 |
| 3D ATTITUDE | Three.js 기반 Roll/Pitch/Yaw 3D 시각화 |
| ATTITUDE HISTORY | Roll/Pitch/Yaw 실시간 그래프 [deg] |
| VIBRATION | 진동 X/Y/Z 실시간 그래프 [m/s²] |
| MOTOR LAYOUT | BlueROV2 Vectored 모터 배치도 + PWM 상태 |
| SYSTEM | CPU 부하, 배터리 전압 |
| ALERTS | 이상징후 경고 (진동 과다, 자세 이상 등) |

## 11-5. 경고 임계값

| 항목 | 임계값 | 경고 |
|------|--------|------|
| Roll | ±30° 초과 | WARN: Roll 이상 |
| Pitch | ±30° 초과 | WARN: Pitch 이상 |
| Vibration | 0.3 m/s² 초과 | WARN: 진동 과다 |
| Motor PWM | 1100 미만 또는 1900 초과 | WARN: 모터 PWM 이상 |
| CPU Load | 800 초과 | WARN: CPU 과부하 |

## 11-6. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| 영상 안 나옴 | 카메라 인식 실패 | USB 뽑았다 꽂기 후 서버 재시작 |
| ERR_CONNECTION_REFUSED | 서버가 실행 안 됨 | SSH에서 서버 실행 상태 확인 |
| /api만 응답, /video 없음 | Flask 단일 스레드 충돌 | threaded=True 확인 |
| 브라우저에서 접속 안 됨 | IP 주소 오류 | `hostname -I`로 실제 IP 확인 |

---

# 12. 진동 데이터 수집 및 분석

## 12-1. 진동 로거 실행

```bash
python3 vib_logger.py
```

**실험 순서:**
1. 실행 후 **30초**: 모터 OFF (베이스라인)
2. 배터리 연결 + QGC 모터 탭 토글 ON + 슬라이더 중간
3. **30초**: 모터 ON 상태 유지
4. **Ctrl+C**로 종료

**저장 파일:** `vib_log_타임스탬프.csv`

## 12-2. CSV 컬럼 구성

| 컬럼 | 내용 |
|------|------|
| timestamp | Unix 타임스탬프 |
| vib_x | X축 진동 m/s² |
| vib_y | Y축 진동 m/s² |
| vib_z | Z축 진동 m/s² |
| vib_total | 총 진동 (√(x²+y²+z²)) |
| roll_deg | Roll 각도 |
| pitch_deg | Pitch 각도 |
| yaw_deg | Yaw 각도 |
| servo1~6 | 각 모터 PWM 값 |

## 12-3. Windows에서 분석

CSV 파일 Windows로 복사:

```powershell
scp mjtest@192.168.0.42:/home/mjtest/vib_log_*.csv .
```

Python 설치 후 분석:

```powershell
pip install matplotlib pandas
python plot_vib.py
```

## 12-4. 분석 기준

- **RMS(Root Mean Square)**: 순간 최댓값보다 안정적인 진동 지표
- X/Y/Z 각 축 RMS 계산 후 전체 평균으로 진동 세기 정의
- 산업 표준 회전체 진동 분석에서 일반적으로 사용

## 12-5. 실험 결과 해석

| 출력 구간 | 진동 특성 |
|----------|----------|
| 0~40% | Z축 진동 높음 |
| 50~60% | 진동 최저 구간 |
| 80% | 진동 재증가 |
| 100% | 안정화 경향 |

Z축 진동이 전체 진동 특성에 가장 큰 영향을 미치며,
50~60% 출력에서 진동이 최저인 현상은 추진기 공진 특성 또는 구조적 진동 특성과 관련 가능성 있음.

---

# 13. GitHub 업로드

## 13-1. Git 초기 설정

```bash
git config --global user.email "이메일"
git config --global user.name "깃허브ID"
```

## 13-2. .gitignore 설정

업로드하면 안 되는 파일 목록 (.gitignore):

```
.cache/
.local/
.config/
.ssh/
.bash_history
.python_history
*.pyc
__pycache__/
.git-credentials
```

> ⚠️ `.git-credentials`에는 GitHub 토큰이 저장되어 있다.
> 이 파일이 업로드되면 GitHub이 자동으로 감지하여 푸시를 차단한다.
> 반드시 .gitignore에 포함시켜야 한다.

## 13-3. 업로드 순서

```bash
git init
git remote add origin https://github.com/계정명/레포이름.git
git add 파일1 파일2 ...
git commit -m "커밋 메시지"
git push -u origin master
```

## 13-4. GitHub 기본 브랜치 설정

GitHub 레포에서 master 브랜치가 보이지 않는 경우:
- 레포 → Code 탭 → 브랜치 드롭다운 → `master` 선택

## 13-5. 오류 및 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| push declined: contains secrets | .git-credentials 포함됨 | git rm --cached .git-credentials 후 orphan 브랜치로 재시작 |
| src refspec main does not match | 브랜치가 master인데 main으로 푸시 시도 | `git push origin master` |
| 히스토리에 토큰 남아있음 | 이전 커밋에 포함 | orphan 브랜치로 히스토리 초기화 |

**히스토리 초기화 (토큰 유출 시):**

```bash
git checkout --orphan newmaster
git add 파일들...
git commit -m "초기 커밋"
git branch -D master
git branch -m master
git push origin master --force
```

---

# 14. 자주 발생하는 오류 총정리

## Pixhawk 관련

| 증상 | 해결 |
|------|------|
| QGC에서 Vehicle 인식 안 됨 | USB 케이블 교체 (데이터 전송 지원 확인) |
| 펌웨어 플래싱 팝업 안 뜸 | Firmware 탭 열고 케이블 뽑았다 꽂기 |
| 캘리브레이션 후 적용 안 됨 | USB 뽑았다 꽂기로 재부팅 |
| COM 포트 인식 안 됨 | QGC Comm Links에서 NMEA GPS → disabled |

## Raspberry Pi 관련

| 증상 | 해결 |
|------|------|
| SSH 접속 불가 | WiFi 국가(KR) 설정 확인, 재플래싱 |
| 명령어가 갑자기 안 먹힘 | 전원 뽑았다 꽂기 (파일시스템 일시 오류) |
| nano 명령어 I/O Error | 전원 재부팅으로 해결 |
| pip 설치 오류 | --break-system-packages 추가 |

## MAVLink 통신 관련

| 증상 | 해결 |
|------|------|
| wait_heartbeat() 무한 대기 | BRD_SER2_RTSCTS=0, TX-RX 방향 확인 |
| xxd에서 데이터 나오지만 Heartbeat 없음 | Baud rate 불일치 (921600 재확인) |
| ttyAMA0 없음 | BT 비활성화 및 raspi-config 재설정 |
| VCC 연결 후 I/O Error 폭발 | VCC 선 제거 후 재부팅 |

## 웹캠/대시보드 관련

| 증상 | 해결 |
|------|------|
| 영상 안 나옴 | USB 재연결 후 서버 재시작 |
| ERR_CONNECTION_REFUSED | 서버 실행 여부 확인 |
| 브라우저 접속 안 됨 | IP 주소 확인 (`hostname -I`) |

---

*본 매뉴얼은 Pixhawk 2.4.8 PRO Clone + Raspberry Pi 4B + ArduSub 4.5.7 환경 기준으로 작성되었다.*
*작성: Team ZG0 / KUCIRA 수중로봇팀*
