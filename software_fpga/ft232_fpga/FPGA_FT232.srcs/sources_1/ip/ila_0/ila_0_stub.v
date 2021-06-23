// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Mon Feb 15 11:50:30 2021
// Host        : Yonxiner-Sonys running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Working/FT232ALL/FPGA_FT232/FPGA_FT232.srcs/sources_1/ip/ila_0/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2018.3" *)
module ila_0(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[255:0],probe1[7:0],probe2[7:0],probe3[0:0],probe4[0:0],probe5[0:0],probe6[511:0]" */;
  input clk;
  input [255:0]probe0;
  input [7:0]probe1;
  input [7:0]probe2;
  input [0:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
  input [511:0]probe6;
endmodule
