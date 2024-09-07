# Define colors for output messages
$colorDefault = "White"
$colorHighlight = "Yellow"
$colorError = "Red"
$colorSuccess = "Green"

# Define the input and output folders with default values
$inputFolder = Read-Host "Enter the input folder path (default is current folder '.')"
if (-not $inputFolder) { $inputFolder = "." }

$outputFolder = Read-Host "Enter the output folder path (default is './output')"
if (-not $outputFolder) { $outputFolder = "./output" }

# Prompt for video quality (CRF value)
$crfValue = Read-Host "Enter the CRF value for video quality (lower is better, default is 18)"
if (-not $crfValue) { $crfValue = 18 }

# Ask the user to choose the encoding method with Intel CPU as the default
Write-Host "`nChoose the encoding method:" -ForegroundColor $colorHighlight
Write-Host "`t1) Intel CPU (x264) - (Slower, smaller files, higher quality)" -ForegroundColor $colorDefault
Write-Host "`t2) NVIDIA GPU (NVENC) - (Faster, bigger files, lower quality)" -ForegroundColor $colorDefault
$encodingChoice = Read-Host "Enter 1 or 2 (default is Intel CPU)"
if (-not $encodingChoice) { $encodingChoice = 1 }

# Set the video codec based on the user's choice or default to Intel CPU
$videoCodec = ""
if ($encodingChoice -eq 1) {
	$videoCodec = "libx264"
	Write-Host "You chose Intel CPU encoding (x264)." -ForegroundColor $colorSuccess
} elseif ($encodingChoice -eq 2) {
	$videoCodec = "h264_nvenc"
	Write-Host "You chose NVIDIA GPU encoding (NVENC)." -ForegroundColor $colorSuccess
} else {
	Write-Host "Invalid option. Defaulting to Intel CPU (x264) encoding." -ForegroundColor $colorError
	$videoCodec = "libx264"
}

# Prompt for encoding speed (preset)
Write-Host "`nChoose the encoding speed (affects file size and quality):" -ForegroundColor $colorHighlight
Write-Host "`t1) Very slow - Best quality, smallest files"
Write-Host "`t2) Slower"
Write-Host "`t3) Slow"
Write-Host "`t4) Medium (default)"
Write-Host "`t5) Fast"
Write-Host "`t6) Faster"
Write-Host "`t7) Very fast"
Write-Host "`t8) Ultra fast - Lower quality, largest files"
$encodingSpeed = Read-Host "Enter 1 to 8 (default is 4)"
if (-not $encodingSpeed) { $encodingSpeed = 4 }

# Map the speed option to ffmpeg presets
$speedPreset = ""
switch ($encodingSpeed) {
	1 { $speedPreset = "veryslow" }
	2 { $speedPreset = "slower" }
	3 { $speedPreset = "slow" }
	4 { $speedPreset = "medium" }
	5 { $speedPreset = "fast" }
	6 { $speedPreset = "faster" }
	7 { $speedPreset = "veryfast" }
	8 { $speedPreset = "ultrafast" }
	default { $speedPreset = "medium"; Write-Host "Invalid option. Defaulting to medium preset." -ForegroundColor $colorError }
}

# Create the output folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
	New-Item -ItemType Directory -Path $outputFolder
}

# Get all .MTS files in the input folder
$files = Get-ChildItem -Path $inputFolder -Filter *.MTS

# Total number of files
$totalFiles = $files.Count
$currentFile = 0

foreach ($file in $files) {
	$currentFile++
	
	# Get the full path of the .MTS file
	$filePath = $file.FullName

	# Extract the "Recorded date" using exiftool
	Write-Host "`n[$currentFile/$totalFiles] Extracting 'Recorded date' for $($file.Name)..." -ForegroundColor $colorHighlight
	$recordedDate = & exiftool -DateTimeOriginal -s3 $filePath

	if (-not $recordedDate) {
		Write-Host "Error: Could not extract 'Recorded date'. Skipping $($file.Name)" -ForegroundColor $colorError
		continue
	}

	# Format the date to "YYYY-MM-DD_HH-MM-SS"
	$formattedDate = $recordedDate -replace ":", "-" -replace " ", "_"

	# Set the output file name based on the formatted date
	$outputFile = Join-Path $outputFolder "$formattedDate.mp4"

	Write-Host "[$currentFile/$totalFiles] Converting $($file.Name) to MP4 using $videoCodec with CRF=$crfValue and preset=$speedPreset..." -ForegroundColor $colorHighlight

	# Convert the .MTS file to .MP4 using ffmpeg with either NVIDIA or Intel CPU encoding
	& ffmpeg -i "$filePath" -c:v $videoCodec -preset $speedPreset -crf $crfValue -c:a ac3 -b:a 256k "$outputFile"

	if (-not (Test-Path $outputFile)) {
		Write-Host "Error: Conversion failed for $($file.Name)" -ForegroundColor $colorError
		continue
	}

	Write-Host "[$currentFile/$totalFiles] Copying EXIF metadata to $($outputFile)..." -ForegroundColor $colorHighlight

	# Copy the EXIF metadata from the original .MTS to the new .MP4 file
	& exiftool -overwrite_original -tagsFromFile "$filePath" -all:all "$outputFile"

	Write-Host "[$currentFile/$totalFiles] Finished processing $($file.Name). Output saved as $formattedDate.mp4" -ForegroundColor $colorSuccess
	Write-Host "-----------------------------------------------------------"
}

Write-Host "All files processed. Press any key to close the window..." -ForegroundColor $colorSuccess

# Wait for user to press any key before exiting
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
