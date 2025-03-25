# VideoStreamUDP

A cross-platform project for streaming video frames from a Python-based sender to a Swift-based receiver over UDP. The sender captures video from a webcam, converts frames to PNG images, and sends them to the receiver, which reconstructs and processes the images.

## Overview

- **Sender (Python):** Captures video frames using OpenCV, processes them with Pillow, and sends them over UDP to `127.0.0.1:5005`.
- **Receiver (Swift):** Listens on UDP port 5005 using Network.framework, reconstructs PNG images into `UIImage` objects, and passes them to a handler for further processing (e.g., display).

## Features

- Real-time video frame streaming over UDP.
- Configurable screen size for cropping frames.
- Command-line options for verbose mode and camera preview.
- Automatic cleanup of resources to prevent file descriptor leaks.

## Prerequisites

### Sender (Python)
- Python 3.6+
- Libraries:
  - `numpy`
  - `opencv-python`
  - `pillow`
  - `pandas`
- Install dependencies:
  ```bash
  pip install numpy opencv-python pillow pandas
  ```
- A webcam (or adjust the code to use a video file).

### Receiver (Swift)
- Xcode 12+ (for Network.framework support)
- iOS 13+ or macOS 10.15+ target
- Swift 5+

## Project Structure

```
CamBridge/
├── sender/
│   ├── server.py              # Python script for sending video frames
│   ├── resources/
│   │   ├── displays.csv     # CSV file with device screen sizes
│   │   └── command_help.txt # Help text for command-line options
├── receiver/
│   └── InterProcessCommunicator.swift # Swift class for receiving frames
└── README.md
```

## Setup

1. **Clone the Repository:**
   ```bash
   git clone <repository-url>
   cd CamBridge
   ```

2. **Prepare the Sender:**
   - Ensure `displays.csv` exists in `sender/resources/` with columns: `device,width,height` (e.g., `11,414,896` for iPhone 11).
   - Create `command_help.txt` in `sender/resources/` with usage instructions (optional).

3. **Prepare the Receiver:**
   - Add `InterProcessCommunicator.swift` to your Xcode project.

## Usage

### Running the Sender (Python)
1. Navigate to the `sender` directory:
   ```bash
   cd sender
   ```
2. Run the script:
   ```bash
   python main.py
   ```
3. Optional arguments:
   - `-v` or `--verbose`: Enable verbose logging.
   - `-c` or `--camera`: (Not implemented in preview; reserved for future use.)
   - `-h` or `--help`: Show help and exit.
   - `<device>`: Specify a device name (e.g., `11` for iPhone 11 screen size).

   Example:
   ```bash
   python main.py --verbose 11
   ```

4. Press `q` to stop the sender.

### Running the Receiver (Swift)
1. Integrate `InterProcessCommunicator` into your app:
   ```swift
   let communicator = InterProcessCommunicator()
   communicator.connect { image in
       DispatchQueue.main.async {
           // Example: Display the image in a UIImageView
           yourImageView.image = image
       }
   }
   ```
2. Build and run your app in Xcode.

3. To stop receiving:
   ```swift
   communicator.detachConnection()
   ```

## How It Works

1. **Sender:**
   - Captures frames from the webcam.
   - Crops frames to the specified screen size.
   - Converts frames to PNG and sends them over UDP with a `.` delimiter between images.

2. **Receiver:**
   - Listens on UDP port 5005.
   - Buffers incoming packets until a `.` delimiter is received.
   - Constructs a `UIImage` from the buffered data and passes it to the handler.

## Troubleshooting

### "Too Many Open Files" Error
- **Symptoms:** `nw_listener_inbox_accept_udp socket() failed [24: Too many open files]` (Swift) or similar (Python).
- **Fixes:**
  - Ensure the Python script reuses a single socket (fixed in the provided code).
  - Verify `detachConnection()` is called in Swift when stopping the receiver.
  - Check file descriptor limits: `ulimit -n` (increase to 4096 if needed: `ulimit -n 4096`).

### No Images Received
- Ensure both sender and receiver are running simultaneously.
- Verify the UDP port (5005) isn’t blocked by a firewall.
- Add logging in Swift’s `receive(on:handler:)` to debug packet reception.

### Performance Issues
- Reduce frame rate in Python by adding a delay (e.g., `cv2.waitKey(33)` for ~30 FPS).
- Lower the resolution in `screen_size` to reduce data size.

## Contributing

Feel free to submit issues or pull requests for improvements, such as:
- Adding TCP support as an alternative.
- Implementing camera preview in Python.
- Enhancing error handling.

## License

This project is unlicensed—use it freely at your own risk!

---

Let me know if you’d like to tweak this further or add specific details (e.g., your GitHub repo URL)! You can save this as `README.md` in your project root directory.
