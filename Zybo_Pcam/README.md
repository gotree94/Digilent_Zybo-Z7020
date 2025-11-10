# Digilent Zybo Z7-20 Pcam5C

1. Digilent IP 설치 (선택사항 - HDMI 원하면)
```bash
cd C:/Users/Administrator/zybo_pcam_hdmi
git clone https://github.com/Digilent/vivado-library.git ./digilent_ip/vivado-library
```
2. Automation 버튼 무시하고 바로 진행
Tcl Console에서:
```tcl
# Wrapper 생성 (이미 되어있을 수 있음)
set_property top system_wrapper [current_fileset]

# Synthesis & Implementation
launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
```

* Run Block Automation/Run Connection Automation 클릭하지 마세요!

* TCL이 이미 모든 연결을 완료했습니다
* Automation 실행하면 연결이 중복되거나 꼬일 수 있습니다


