#this program reads incoming data from the FPGA serial port and prints it.
import serial
import time

port_name = 'COM16' 
baud_rate = 9600

#this function opens the port, receives the data, prints it and the closes the port. It also prints the number of bytes received.
def receive_data():
    try:
        #Open the serial port
        ser = serial.Serial(port_name, baud_rate, timeout=1)
        print(f"Connected to {port_name} at {baud_rate} baud rate.")
        
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

if __name__ == "__main__":    
    
    data = receive_data()
    #convert received bytes to hexadecimal string
    hex_string = data.hex()
    print(f"Hexadecimal: {hex_string}")
