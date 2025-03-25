# CamBridge

A lightweight framework for streaming video frames from a Python-based server to an iOS/macOS app over UDP. The server captures webcam footage, processes it into PNG images, and sends it to the client, which uses Combine to publish received `UIImage` objects.

[![GitHub](https://img.shields.io/github/stars/tinyprocessing/CamBridge?style=social)](https://github.com/tinyprocessing/CamBridge)

## Overview

- **Server (Python):** Captures video frames using OpenCV, crops and converts them to PNG with Pillow, and sends them over UDP to `127.0.0.1:5005`.
- **Client (Swift):** An iOS/macOS app that listens on UDP port 5005 using `Network.framework`, reconstructs PNG images into `UIImage` objects, and publishes them via a Combine `AnyPublisher`.

## Features

- Real-time video streaming over UDP.
- Configurable screen sizes for cropping frames (via `displays.csv`).
- Combine integration for reactive image handling in Swift.
- Command-line options for verbose mode and device selection.

## Prerequisites

### Server (Python)
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
- A webcam (or modify `server.py` to use a video file).

### Client (Swift)
- Xcode 12+ (for `Network.framework` and Combine support)
- iOS 13+ or macOS 10.15+
- Swift 5+

## Project Structure

- `CamBridge/`: iOS/macOS app directory with Swift source files and assets.
- `resources/`: Contains `displays.csv` for screen size configurations.
- `server.py`: Python script for streaming video frames.
- `README.md`: This file.

## Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/tinyprocessing/CamBridge.git
   cd CamBridge
   ```

2. **Prepare the Server:**
   - Ensure `displays.csv` is in the `resources/` directory with columns: `device,width,height` (e.g., `11,414,896` for iPhone 11).

3. **Prepare the Client:**
   - Open `CamBridge.xcodeproj` in Xcode.
   - Build the project for your target (iOS Simulator or device).

## Usage

### Running the Server (Python)
1. Navigate to the project root:
   ```bash
   cd CamBridge
   ```
2. Run the server:
   ```bash
   python server.py
   ```
3. Optional arguments:
   - `-v` or `--verbose`: Enable verbose logging.
   - `-h` or `--help`: Show help and exit.
   - `<device>`: Specify a device name (e.g., `11` for iPhone 11 screen size).

   Example:
   ```bash
   python server.py --verbose 11
   ```

4. Press `q` to stop the server.

### Running the Client (Swift)
1. In `ViewController.swift` (or another appropriate file), set up the communicator:
   ```swift
   import UIKit
   import Combine

   class ViewController: UIViewController {
       @IBOutlet weak var imageView: UIImageView!
       private var communicator: InterProcessCommunicator?
       private var cancellables = Set<AnyCancellable>()

       override func viewDidLoad() {
           super.viewDidLoad()
           communicator = InterProcessCommunicator()
           communicator?.connect()
           communicator?.imagePublisher
               .receive(on: DispatchQueue.main)
               .sink { [weak self] image in
                   self?.imageView.image = image
               }
               .store(in: &cancellables)
       }

       override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           communicator?.detachConnection()
       }
   }
   ```
2. Connect an `UIImageView` in your storyboard to the `@IBOutlet`.
3. Build and run the app in Xcode.

## How It Works

1. **Server:**
   - Captures frames from the webcam.
   - Crops frames to the specified screen size (from `displays.csv`).
   - Converts frames to PNG and sends them over UDP with a `.` delimiter between images.

2. **Client:**
   - Listens on UDP port 5005.
   - Buffers incoming packets until a `.` delimiter is received.
   - Publishes reconstructed `UIImage` objects via a Combine `PassthroughSubject`.

## Troubleshooting

### "Too Many Open Files" Error
- **Symptoms:** `nw_listener_inbox_accept_udp socket() failed [24: Too many open files]`.
- **Fixes:**
  - Ensure `server.py` reuses a single socket (fixed in the provided code).
  - Call `detachConnection()` when the Swift app stops (e.g., in `viewWillDisappear`).
  - Check `ulimit -n` (increase if needed: `ulimit -n 4096`).

### No Images Displayed
- Verify both server and client are running simultaneously.
- Ensure UDP port 5005 isn’t blocked by a firewall.
- Add logging in `InterProcessCommunicator.receive(on:)` to debug packet reception.

### Performance Issues
- Add a delay in `server.py` (e.g., `cv2.waitKey(33)` for ~30 FPS).
- Adjust `screen_size` in `displays.csv` to reduce data size.

## Contributing

Contributions are welcome! Please:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

Ideas for improvement:
- Add TCP support as an alternative protocol.
- Implement error handling for network interruptions.
- Support dynamic frame rate control.

## License

This project is unlicensed—use it freely at your own risk!

---

### Notes
- I assumed `command_help.txt` isn’t critical for now, so it’s omitted from the README. If you want it included, let me know its contents!
- The GitHub badge is a suggestion—remove it if you don’t want it.
- Save this as `README.md` in the `CamBridge/` root directory.

Let me know if you need further adjustments!
