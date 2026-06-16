import serial
import time

# !!! CHANGE 'COM3' to whatever your port was in the Arduino IDE !!!
SERIAL_PORT = 'COM3' 
BAUD_RATE = 115200

try:
    print(f"Opening port {SERIAL_PORT}...")
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(2) # Give the hardware a second to reset
    print("Connected successfully! Start blowing to test readings...")
    
    # Read 50 lines of data to verify it works
    for _ in range(50):
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            print(f"Data from hardware: {line}")
            
    ser.close()
    print("\nConnection test passed perfectly!")

except Exception as e:
    print(f"\nError: Could not connect to the device. Check your COM port settings.\nDetails: {e}")