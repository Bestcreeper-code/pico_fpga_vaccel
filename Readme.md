# Pico FPGA Video Accelerator

#### A hardware video accelerator using a microcontroller and a Gowin FPGA.

The current implementation uses a Raspberry Pi Pico to communicate with the FPGA through a 4-bit serial bus.

*The microcontroller is not a fundamental requirement: the communication layer can be ported to other microcontrollers by adapting the bus initialization and word I/O implementation.*

*The FPGA design can also technically be ported to other FPGAs. Without code changes, the device must support the required Gowin IPs (such as DVI TX, clock and memory IPs) and provide sufficient resources. Alternatively, these IPs can be replaced with compatible implementations.*

## Dependencies(assuming no source code changes)

|            |
| ---------- |
| Pico SDK   |
| Gowin IDE* |

* Other tools capable of synthesizing SystemVerilog and Gowin FPGA IPs may also work.
