# highspeed_fpga_ft232

## 简介
USB high-speed communication. FT232 act as an intermediary, and the PC communicates with the FPGA.
通过FT232将PC与FPGA进行通信，速度高达40MB/S。
## 平台说明
1. PC电脑（windows系统）
2. FPGA（赛灵思的ZYNQ7010开发板，其他FPGA也可以）
3. FT232模块
## 功能说明
PC端进行USB数据发送，FPGA收到数据进行数据缓存，然后将数据回发给PC