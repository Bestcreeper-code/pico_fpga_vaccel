//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sun Sep  6 17:13:32 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    framebuffer_sdpb your_instance_name(
        .dout(dout), //output [15:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [8:0] ada
        .din(din), //input [31:0] din
        .adb(adb) //input [9:0] adb
    );

//--------Copy end-------------------
