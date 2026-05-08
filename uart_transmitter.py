import serial
import time
import uart_receiver_test as rx

#funtion to ask the user for a message to send, and then send it over the serial port
def transmit_data(message):
    port_name = 'COM16'
    baud_rate = 9600

    try:
        # Open the serial port
        ser = serial.Serial(port_name, baud_rate, timeout=1)
        print(f"Connected to {port_name} at {baud_rate} baud rate.")
   
        # Send the message over the serial port
        for byte in message:
            ser.write(byte.to_bytes(1, byteorder='big'))
            print(f"Byte sent: {byte.to_bytes(1, byteorder='big')}")
            time.sleep(.01) # Add a small delay between bytes to ensure proper transmission

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("Exiting program.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")

if __name__ == "__main__":  
        
    # Ask the user for a message to send. continually ask until a valid message is entered
    looping = True
    while looping == True:
        message = input("Enter the message to send: \n") + "\0" #add null terminator to the end of the message
        to_send = message.encode('utf-8')
        if len(to_send) == 0:
            print("No message entered.\n")
        elif len(to_send) > 128:
            print("Message too long. Please enter a message of 128 bytes or less.\n")
        else:
            looping = False

    print(f"length of message in bytes: {len(to_send)}")

    #send to FPGA
    transmit_data(to_send)

    #wait for response from FPGA
    data = rx.receive_data()

    bit_array = ''.join(format(byte, '08b') for byte in data)   
    #print(f"Bit array: {bit_array}")
    print(f"Bit array length: {len(bit_array)}")

    num_errors = 10
    corrupted_bit_array = rx.induce_errors(bit_array, num_errors)

    print(f"Corrupted bit array: {corrupted_bit_array}")
    
    #convert the corrupted bit array back to bytes
    corrupted_bytes = bytes(int(corrupted_bit_array[i:i+8], 2) for i in range(0, len(corrupted_bit_array), 8))
    transmit_data(corrupted_bytes)

    corrupted_loop_back = rx.receive_data()
    print(f"Corrupted loop back: {corrupted_loop_back}")
