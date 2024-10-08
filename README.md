# MTS to MP4 Bulk Converter

**Powershell Script - Windows Only**

This script was created to help me bulk convert my camcorder's `.MTS` files to `.MP4` while preserving some **EXIF** metadata. This should allow the output to be properly organized by photo software (iCloud Photos, Google Photos, etc).

I added in some user prompts and options just to make it more interactive and customizable. You can select the input, output, file size, quality, and if you want to encode using your **CPU** or **NVIDIA GPU**.

There's a `Defaults` script version if you don't want any prompts, just a one click run with some recommended defaults.

This script has only been tested on **Windows 10**.

### Disclaimer

ChatGPT 4o was used in writing this script.

Also, always be careful running scripts on your device. This script is intended to be non-destructive (it won't delete your original files), but I have no idea how your system will respond to it. Take caution and backup your files!

## Features

- Converts `.MTS` files to `.MP4` while preserving some original EXIF metadata.
- Offers choices for CRF, Quality, and encoding method (**Software/CPU** or **Hardware/NVIDIA GPU**).
- Carries over important **EXIF** metadata like Record Date and attempts to carry over camera info into XMP.
- Automatically names output files based on the **Recorded Date** in the format `YYYY-MM-DD_HH-MM-SS.mp4`.

## Prerequisites

Before using this script, ensure you have the following tools installed and added to your system's **PATH**:

1. [**FFmpeg**](https://ffmpeg.org/)  
   FFmpeg is a complete, cross-platform solution to record, convert, and stream audio and video.  
   Download it [here](https://ffmpeg.org/download.html).

2. [**ExifTool**](https://exiftool.org/)  
   ExifTool is a platform-independent Perl library plus a command-line application for reading, writing, and editing meta-information in a wide variety of files.  
   Download it [here](https://exiftool.org/#downloads).

### Adding FFmpeg and ExifTool to PATH

To ensure that `FFmpeg` and `ExifTool` can be accessed globally by this script, you need to add them to your system’s PATH:

1. Right-click on **This PC** and select **Properties**.
2. Select **Advanced system settings**.
3. Click the **Environment Variables** button.
4. In the **System variables** section, find the `PATH` variable, select it, and click **Edit**.
5. Click **New**, and add the directory paths where `FFmpeg` and `ExifTool` are located.
6. Click **OK** to save and close all windows.

## Usage

1. Clone or download this repository (or just download the `.ps1` file).
2. Ensure you have **FFmpeg** and **ExifTool** installed and added to your system PATH.
3. Run the script through Powershell or by right-clicking on the script file and selecting **Run with PowerShell** (Use the `Defaults` version if you want a no-prompt experience, just a one click run with some recommended defaults).
4. Follow the on-screen prompts to select input/output folders (they can be relative to your script location), video quality, and encoding method.

## Acknowledgements

- **ExifTool** by Phil Harvey  
  [ExifTool Website](https://exiftool.org/)  
  Author: Phil Harvey

- **FFmpeg**  
  [FFmpeg Website](https://ffmpeg.org/)  
  FFmpeg is developed by the FFmpeg team.
