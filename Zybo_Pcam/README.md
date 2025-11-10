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


아래의 에러 발생하여 핀 미설정 부분 설정 후 다시 implementation
```
[DRC UCIO-1] Unconstrained Logical Port: 6 out of 14 logical ports have no user assigned specific location constraint (LOC). This may cause I/O contention or incompatibility with the board power or connectivity affecting performance, signal integrity or in extreme cases cause damage to the device or the components to which it is connected. To correct this violation, specify all pin locations. This design will fail to generate a bitstream unless all logical ports have a user specified site LOC constraint defined.  To allow bitstream creation with unspecified pin locations (not recommended), use this command: set_property SEVERITY {Warning} [get_drc_checks UCIO-1].  NOTE: When using the Vivado Runs infrastructure (e.g. launch_runs Tcl command), add this command to a .tcl file and add that file as a pre-hook for write_bitstream step for the implementation run.  Problem ports: mipi_phy_if_data_hs_n[1:0], mipi_phy_if_data_hs_p[1:0], mipi_phy_if_clk_hs_n, and mipi_phy_if_clk_hs_p.
```

```
set_property PACKAGE_PIN Y18 [get_ports mipi_phy_if_clk_hs_n]
set_property PACKAGE_PIN Y19 [get_ports mipi_phy_if_clk_hs_p]
set_property PACKAGE_PIN W18 [get_ports mipi_phy_if_data_hs_n[0]]
set_property PACKAGE_PIN W19 [get_ports mipi_phy_if_data_hs_p[0]]
set_property PACKAGE_PIN V17 [get_ports mipi_phy_if_data_hs_n[1]]
set_property PACKAGE_PIN V18 [get_ports mipi_phy_if_data_hs_p[1]]

save_constraints

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
```
