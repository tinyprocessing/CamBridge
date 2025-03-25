import numpy as np
import cv2
import socket
import io
import math
import sys
import os
import pandas as pd
from PIL import Image

dirname = os.path.dirname(os.path.abspath(__file__)) + '/resources/'

verbose = False
camera_mode = False

UDP_IP = '127.0.0.1'
UDP_PORT = 5005
MAX_PACKET = 9216  # Adjust based on your environment

screen_size = (414, 896)  # Default

# Utility Functions
def launch_logo():
    print("tinyprocessing")

def verbose_print(text):
    if verbose:
        print(text)

def organize_color(image_array):
    return cv2.cvtColor(image_array, cv2.COLOR_BGR2RGB)

def image_to_bytes(image: Image):
    imgByteArr = io.BytesIO()
    image.save(imgByteArr, format='PNG')
    return imgByteArr.getvalue()

def crop_image(image: Image):
    center_x = int(image.width / 2)
    center_y = int(image.height / 2)
    screen_width, screen_height = screen_size
    left_upper = (center_x - screen_width // 2, center_y - screen_height // 2)
    right_lower = (center_x + screen_width // 2, center_y + screen_height // 2)
    return image.crop(left_upper + right_lower)

# Argument Parsing
def load_argument():
    global screen_size, verbose, camera_mode

    def verbose_on():
        verbose = True
        print(' ~ verbose mode ~ ')

    def camera_on():
        camera_mode = True
        print(' ~ camera mode ~ ')

    def print_help():
        with open(dirname + 'command_help.txt', 'r') as file:
            print(file.read())
        exit()

    arguments = sys.argv
    patterns = {'verbose': verbose_on, 'camera': camera_on, 'help': print_help}

    for arg in arguments:
        for target, func in patterns.items():
            for fmt in ['-', '--']:
                if arg in (fmt + target, fmt + target[0]):
                    func()

    print('Checking the screen size of iOS Simulator...')
    display_sizes = pd.read_csv(dirname + 'displays.csv')
    for row in display_sizes.itertuples():
        device_name = row.device.lower()
        if any(arg.lower() in [device_name, 'iphone' + device_name] for arg in arguments):
            screen_size = (row.width, row.height)
            print(f'Screen Size: {screen_size[0]}x{screen_size[1]}')
            return
    print(f'Screen Size: {screen_size[0]}x{screen_size[1]}')

# Capture and Send
def capture(sock):
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture frame.")
                break

            image = Image.fromarray(organize_color(frame))
            image = crop_image(image)
            raw_data = image_to_bytes(image)
            verbose_print(f'\nCaptured: ImageSize → {len(raw_data)} bytes')

            # Send delimiter and data
            sock.sendto(b'.', (UDP_IP, UDP_PORT))
            for i in range(math.ceil(len(raw_data) / MAX_PACKET)):
                sock.sendto(raw_data[i * MAX_PACKET:(i + 1) * MAX_PACKET], (UDP_IP, UDP_PORT))

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    finally:
        cap.release()
        print("Camera released.")

def get_max_packet(sock):
    for i in range(9216, 100000):
        try:
            sock.sendto(b"a" * i, (UDP_IP, UDP_PORT))
        except OSError:
            return i - 1
    return 9216

def main():
    launch_logo()
    load_argument()

    print('\nIf you need some help, use command \'-h\'. \n\nChecking your environment...')
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        global MAX_PACKET
        MAX_PACKET = get_max_packet(sock)
        print(f'The maximum length of data that can be sent over UDP is {MAX_PACKET} bytes. \n\nRunning...')
        capture(sock)

if __name__ == '__main__':
    main()
