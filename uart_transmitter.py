import serial
import time
import uart_receiver_test as rx

source_port = 'COM16' #COM16 is the right com port. COM17 is left com port.
sink_port = 'COM17'

#funtion to ask the user for a message to send, and then send it over the serial port
def transmit_data(message, port_name):
    baud_rate = 9600

    try:
        # Open the serial port
        ser = serial.Serial(port_name, baud_rate, timeout=1)
        print(f"\n------TRANSMITTING DATA TO FPGA ON PORT: {port_name}------")
   
        # Send the message over the serial port
        for byte in message:
            ser.write(byte.to_bytes(1, byteorder='big'))
            #print(f"Byte sent: {byte.to_bytes(1, byteorder='big')}")
            time.sleep(.01) # Add a small delay between bytes to ensure proper transmission

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("Exiting program.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print(f"------CLOSED PORT: {port_name}------")

if __name__ == "__main__":  
        
    # Ask the user for a message to send. continually ask until a valid message is entered
    looping = True
    while looping == True:
        message = input("Enter the message to send: \n")# + "\0" #add null terminator to the end of the message
        to_send = message.encode('utf-8')
        if len(to_send) == 0:
            print("No message entered.\n")
        elif len(to_send) > 128:
            print("Message too long. Please enter a message of 128 bytes or less.\n")
        else:
            looping = False

    print(f"length of message in bytes: {len(to_send)}")

    

    #send to FPGA from source
    transmit_data(to_send, source_port)

    #sink waits for response from FPGA
    data = rx.receive_data(sink_port)

    bit_array = ''.join(format(byte, '08b') for byte in data)   
    #print(f"Bit array: {bit_array}")
    print(f"------INDUCE ERRORS IN ENCODED MESSAGE------\n")
    print(f"Bit array length: {len(bit_array)}")

    #switch around bit array. put message in front of the array
    bit_array = list(bit_array)
    #print(bit_array)
    encoded_bytes = len(to_send)*2 #number of encoded bytes
    num_bits = encoded_bytes * 8 #number of bits in the encoded message
    start_of_message = 2047 - num_bits
    for i in range(num_bits):
        #swap the first 8 bits with the second 8 bits
        bit_array[i] = bit_array[start_of_message + i]
        bit_array[start_of_message + i] = 0

    #convert the bit array back to a string
    bit_array = ''.join(bit_array)
    num_errors = 0
    corrupted_bit_array = rx.induce_errors(bit_array, num_errors)

    print(f"Corrupted bit array: {corrupted_bit_array}")
    
    #convert the corrupted bit array back to bytes
    corrupted_bytes = bytes(int(corrupted_bit_array[i:i+8], 2) for i in range(0, len(corrupted_bit_array), 8))
    #transmit corrupted message back to the FPGA from sink
    transmit_data(corrupted_bytes, sink_port)

    #source receives decoded message from FPGA
    decoded_msg = rx.receive_data(source_port)
    print(f"Decoded message: {decoded_msg.decode('utf-8', errors='replace')}")
