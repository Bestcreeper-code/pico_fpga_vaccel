#!/usr/bin/env python3

import pygame
import serial
import time

# ---------------- Configuration ----------------

SERIAL_PORT = "/dev/ttyACM0"   # Change as needed
BAUDRATE = 115200

DEADZONE = 0.35
POLL_HZ = 60

# ------------------------------------------------

pygame.init()
pygame.joystick.init()

if pygame.joystick.get_count() == 0:
    raise RuntimeError("No controller found.")

js = pygame.joystick.Joystick(0)
js.init()

print(f"Using controller: {js.get_name()}")

ser = serial.Serial(SERIAL_PORT, BAUDRATE)
time.sleep(2)

last_left = 0
last_right = 0

period = 1.0 / POLL_HZ

while True:
    pygame.event.pump()

    left = js.get_axis(1)
    right = js.get_axis(4)

    if left < -DEADZONE:
        ser.write(b'z')
    elif left > DEADZONE:
        ser.write(b's')

    if right < -DEADZONE:
        ser.write(b'o')
    elif right > DEADZONE:
        ser.write(b'l')

    time.sleep(1.0 / POLL_HZ)
