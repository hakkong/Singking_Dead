import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 1. 라즈베리파이 홈 경로 설정
data_dir = "/home/mjtest"

# 수집된 파일과 실제 모터 출력(%) 매칭
data_files = {
    100: "vib_log_1782422175.csv",
    80:  "vib_log_1782422215.csv",
    60:  "vib_log_1782422241.csv",
    50:  "vib_log_1782422268.csv",
    40:  "vib_log_1782422297.csv",
    20:  "vib_log_1782422324.csv",
    0:   "vib_log_1782422348.csv"
}

pwm_outputs = []
v_x_rms, v_y_rms, v_z_rms = [], [], []
v_total_mean = []

print("📈 모터 출력별 진동 트렌드 분석 시작...")

# 2. 파일 정렬 및 데이터 통계 계산
for pwr, filename in sorted(data_files.items()):
    filepath = os.path.join(data_dir, filename)
    
    if not os.path.exists(filepath):
        print(f"❌ 파일을 찾을 수 없습니다: {filepath}")
        continue
        
    # CSV 파일 로드
    df = pd.read_csv(filepath)
    
    # 컬럼명 공백 제거 및 모두 대문자로 변경 (매칭 정확도를 위해)
    df.columns = df.columns.str.strip().str.upper()
    
    # 3축 컬럼명 자동 매칭 (VIB_X 또는 X_AXIS 등 유연하게 대응)
    col_x = [c for c in df.columns if 'X' in c][0]
    col_y = [c for c in df.columns if 'Y' in c][0]
    col_z = [c for c in df.columns if 'Z' in c][0]
    
    # RMS(실효값) 계산 함수
    def rms(series):
        return np.sqrt(np.mean(series**2))
    
    # 리스트에 통계치 추가
    pwm_outputs.append(pwr)
    v_x_rms.append(rms(df[col_x]))
    v_y_rms.append(rms(df[col_y]))
    v_z_rms.append(rms(df[col_z]))
    
    # 종합 진동 컬럼 매칭 (TOTAL 단어가 들어간 컬럼 찾기)
    total_cols = [c for c in df.columns if 'TOTAL' in c]
    if total_cols:
        v_total_mean.append(df[total_cols[0]].mean())
    else:
        # 없으면 3축 합성치 직접 계산
        total_vec = np.sqrt(df[col_x]**2 + df[col_y]**2 + df[col_z]**2)
        v_total_mean.append(total_vec.mean())
        
    print(f"   [완료] {pwr}% 출력 ➔ {filename}")

if not pwm_outputs:
    print("❌ 분석할 수 있는 CSV 파일이 하나도 없습니다.")
    exit()

# 3. Matplotlib 시각화 그래프 그리기
plt.figure(figsize=(10, 6))

# 각 축별 RMS 선 그래프
plt.plot(pwm_outputs, v_x_rms, marker='o', color='crimson', linewidth=2, label='X-axis Vibration (RMS)')
plt.plot(pwm_outputs, v_y_rms, marker='s', color='forestgreen', linewidth=2, label='Y-axis Vibration (RMS)')
plt.plot(pwm_outputs, v_z_rms, marker='^', color='royalblue', linewidth=2, label='Z-axis Vibration (RMS)')

# 종합 진동 평균 (검은색 두꺼운 점선)
plt.plot(pwm_outputs, v_total_mean, marker='x', color='black', linewidth=2, linestyle='--', label='Total Vibration (Mean)')

# 그래프 스타일 설정
plt.title("Motor 1 Output Intensity vs Vibration Level", fontsize=14, fontweight='bold', pad=15)
plt.xlabel("Motor Output Speed (%)", fontsize=12, labelpad=10)
plt.ylabel("Vibration Amplitude (g)", fontsize=12, labelpad=10)
plt.xticks(pwm_outputs)
plt.grid(True, linestyle=':', alpha=0.6)
plt.legend(fontsize=11, loc='upper left')

# 라즈베리파이 경로에 이미지 저장
save_path = os.path.join(data_dir, "motor1_vibration_trend.png")
plt.savefig(save_path, dpi=300, bbox_inches='tight')
print(f"\n🎉 성공! 그래프 이미지가 저장되었습니다:\n➔ {save_path}")
