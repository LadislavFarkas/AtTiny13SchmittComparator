import sys
import os
import serial

def printdata(data):
	if len(data)!=6:
		print("INVALID DATA")
	else:
		input_u = (data[0] << 8) | data[1]
		lower_u = (data[2] << 8) | data[3]
		upper_u = (data[4] << 8) | data[5]

		if input_u:
			input_u = (input_u / 1023.0) * 5.0

		if lower_u:
			lower_u = (lower_u / 1023.0) * 5.0

		if upper_u:
			upper_u = (upper_u / 1023.0) * 5.0

		t = "INPUT %.2f" % input_u, "LOWER %.2f" % lower_u, "UPPER %.2f" % upper_u

		sys.stdout.write(str(t)+"\r")
		sys.stdout.flush()
		

	return


com = serial.Serial(port="COM8", baudrate=9600, bytesize=8, timeout=3, write_timeout=1, stopbits=1)

state = "init"
header = []
data = []
data_size = 6

try:
	while True:
		b = com.read(1)

		if state == "data":
			data.append(int.from_bytes(b, "big"))

			data_size -= 1

			if data_size == 0:
				state = "finit_e"

		elif state == "finit_e":
			if b == b'E':
				state = "finit_d"
			else:
				state = "init"
				header.clear()

		elif state == "finit_d":
			if b == b'D':
				printdata(data)

			state = "init"
			header.clear()

		if state == "init":
			if len(header) == 2:
				header.pop(0)

			header.append(b)

			if len(header) == 2 and header[0] == b'B' and header[1] == b'E':
				state = "data"
				data_size = 6
				data.clear()
except Exception as e:
	print(str(e))
	pass

com.close()
