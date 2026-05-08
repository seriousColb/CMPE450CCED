#receive 
import serial
import time


# BEGIN RECEIVING

ser = serial.Serial('COM3', 9600)
time.sleep(2)

user_input = input("Enter text: ")  # e.g. "hi"

for char in user_input:
    ser.write(char.encode())   # sends 1 byte per character
    time.sleep(0.001)

ser.close()

# BEGIN TRANSMITTING

port_name = 'COM3'
baud_rate = 9600

try:
    #Open the serial port
    ser = serial.Serial(port_name, baud_rate, timeout=1)
    print(f"Connected to {port_name} at {baud_rate} baud rate.")

    # for i in range(128):
    #   if ser.in_waiting > 0:
    #       data = ser.read(ser.in_waiting)
    #       print(f"Received: {data}")
        
    # time.sleep(0.01)

    
    #Continuously read data from the serial port
    count = 0

    buffer = bytearray()

    while count < 256:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            buffer.extend(data)
            print(f"Received: {data.hex()}")
            count += 1
            
        
        time.sleep(0.01)

    print("Final 256 bytes:", buffer)
    
    for byte in buffer:
        for i in range(7, -1, -1):   # from bit 7 down to bit 0
            bit = (byte >> i) & 1
            print(bit, end='')

except serial.SerialException as e:
    print(f"Serial error: {e}")
except KeyboardInterrupt:
    print("Exiting program.")
finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()
        print("Serial port closed.")
