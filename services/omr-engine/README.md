# OMR Processing Engine Microservice

High-precision Computer Vision and Machine Learning microservice for Optical Mark Recognition (OMR) sheet processing, template calibration, and bubble evaluation.

## Features
- **FastAPI REST API**: High-throughput endpoints for image alignment, bubble evaluation, and health monitoring.
- **OpenCV Computer Vision Pipeline**: Perspective transformation, fiducial marker discovery, and Otsu thresholding.
- **PyTorch Micro-CNN**: Ultra-compact 4-class neural network classifier for bubble state classification.
- **Pre-calibrated Templates**: Universal 200Q, NEET 180Q/200Q, and Standard 20Q/50Q/100Q formats.

## Setup & Testing
```bash
pip install -e .[dev]
pytest tests/ -v
```
