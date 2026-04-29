#this program reads incoming data from the FPGA serial port and prints it.
import serial
import time
import random

port_name = 'COM16' 
baud_rate = 9600

#this function opens the port, receives the data, prints it and the closes the port. It also prints the number of bytes received.
def receive_data():
    try:
        #Open the serial port
        ser = serial.Serial(port_name, baud_rate, timeout=1)
        print(f"Connected to {port_name} at {baud_rate} baud rate. Waiting to receive data...")
        
        #Continuously read data from the serial port
        while True:
            if ser.in_waiting > 0:
                data = ser.readline() #.decode('utf-8').rstrip()
                print(f"Received: {data}")
                #print number of bytes received
                print(f"Bytes received: {len(data)}")
                break
            
            time.sleep(0.1)

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("Exiting program.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")

    return data

#this function generates num_errors random indicies within the range of the bit array length, and flips the bits
def induce_errors(bit_array, num_errors):
    #generate random indices within the range of the bit array length
    random_indices = random.sample(range(len(bit_array)), num_errors)
    print(f"Inducing {num_errors} errors at the following random indices: {random_indices}")

    #create a list from the bit array to allow for mutation
    bit_array = list(bit_array)
    for index in random_indices:
        #flip the bit at the specified index
        if bit_array[index] == '0':
            bit_array[index] = '1'
        else:
            bit_array[index] = '0'

    #return it as a string
    return ''.join(bit_array)
    

if __name__ == "__main__":    
    
    data = receive_data()
    #convert received bytes to hexadecimal string
    hex_string = data.hex()
    #print(f"Hexadecimal: {hex_string}")

    #create bit array from the received data
    bit_array = ''.join(format(byte, '08b') for byte in data)   
    #print(f"Bit array: {bit_array}")
    print(f"Bit array length: {len(bit_array)}")

    #corrupt the bit array by inducing random errors
    num_errors = 10
    corrupted_bit_array = induce_errors(bit_array, num_errors)

    #print(f"Corrupted bit array: {corrupted_bit_array}")


