//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-07-22 17:46:42
create_clock -name tmds_clk -period 13.468 -waveform {0 6.734} [get_pins {u_clkdiv/CLKOUT}]
create_clock -name serial_clk -period 10 -waveform {0 5} [get_ports {serial_dat_clk}]
create_clock -name I_clk -period 37.04 -waveform {0 18.52} [get_ports {I_clk}] -add
