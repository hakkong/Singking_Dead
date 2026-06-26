import os
import pandas as pd
import matplotlib.pyplot as plt

def analyze_rov_vibration():
    # 현재 폴더에 있는 파일 이름 정의
    file_off = 'vib_log_1782419368.csv'
    file_on = 'vib_log_1782419624.csv'

    if not os.path.exists(file_off) or not os.path.exists(file_on):
        print("❌ 에러: CSV 파일 명을 다시 확인해주세요!")
        return

    # 데이터 로드
    df_off = pd.read_csv(file_off)
    df_on = pd.read_csv(file_on)

    # 시간 축 정규화 (시작 시간을 0초로 맞춤)
    df_off['timestamp'] = pd.to_datetime(df_off['timestamp'])
    df_on['timestamp'] = pd.to_datetime(df_on['timestamp'])
    
    df_off['t'] = (df_off['timestamp'] - df_off['timestamp'].iloc[0]).dt.total_seconds()
    df_on['t'] = (df_on['timestamp'] - df_on['timestamp'].iloc[0]).dt.total_seconds()

    # 텍스트로 표준편차(진동폭) 먼저 출력
    print("\n" + "="*50)
    print("📊 [Motor OFF] 각 축별 진동 표준편차")
    print(df_off[['vib_x', 'vib_y', 'vib_z']].std())
    print("-"*50)
    print("🔥 [Motor ON] 각 축별 진동 표준편차")
    print(df_on[['vib_x', 'vib_y', 'vib_z']].std())
    print("="*50 + "\n")

    # 차트 그리기 (3행 2열 구조)
    fig, axes = plt.subplots(3, 2, figsize=(14, 9), sharex=True)
    fig.suptitle('ROV Vibration Analysis: Motor OFF vs ON', fontsize=16, fontweight='bold')
    
    color_off, color_on = '#4fc3f7', '#ff7043'

    # X, Y, Z축 데이터 플롯 루프
    for i, axis in enumerate(['vib_x', 'vib_y', 'vib_z']):
        # Motor OFF (하늘색)
        axes[i, 0].plot(df_off['t'], df_off[axis], color=color_off, linewidth=1)
        axes[i, 0].set_title(f'Motor OFF - {axis.upper()}')
        axes[i, 0].grid(True, linestyle='--')
        
        # Motor ON (주황색)
        axes[i, 1].plot(df_on['t'], df_on[axis], color=color_on, linewidth=1)
        axes[i, 1].set_title(f'Motor ON - {axis.upper()}')
        axes[i, 1].grid(True, linestyle='--')

    axes[2, 0].set_xlabel('Time (seconds)')
    axes[2, 1].set_xlabel('Time (seconds)')
    
    plt.tight_layout()
    
    # 이미지 파일 저장 (SSH 환경용)
    output_img = 'vibration_result.png'
    plt.savefig(output_img, dpi=150)
    print(f"💾 시각화 차트가 '{output_img}' 파일로 저장되었습니다.")

if __name__ == "__main__":
    analyze_rov_vibration()
