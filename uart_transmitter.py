import serial
import time

#funtion to ask the user for a message to send, and then send it over the serial port
def transmit_data():
    port_name = 'COM16'
    baud_rate = 9600

    try:
        # Open the serial port
        ser = serial.Serial(port_name, baud_rate, timeout=1)
        print(f"Connected to {port_name} at {baud_rate} baud rate.")

        # Ask the user for a message to send. continually ask until a valid message is entered
        looping = True
        while looping == True:
            message = input("Enter the message to send: \n")
            to_send = message.encode('utf-8')
            if len(to_send) == 0:
                print("No message entered.\n")
            elif len(to_send) > 1024:
                print("Message too long. Please enter a message of 1024 bytes or less.\n")
            else:
                looping = False

        # Send the message over the serial port
        ser.write(to_send)
        print(f"Message sent: {message}")

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("Exiting program.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")