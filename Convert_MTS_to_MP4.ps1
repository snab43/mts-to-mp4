# Define colors for output messages
$colorDefault = "White"
$colorHighlight = "Yellow"
$colorError = "Red"
$colorSuccess = "Green"

# Define the input and output folders with default values
Write-Host "Enter the input folder path" -ForegroundColor $colorHighlight
$inputFolder = Read-Host "Input folder path (Default: '.')"
if (-not $inputFolder) {
    $inputFolder = "."
    Write-Host "Using default value of '.'" -ForegroundColor $colorSuccess
}

Write-Host "`nEnter the output folder path" -ForegroundColor $colorHighlight
$outputFolder = Read-Host "Output folder path (Default: './output')"
if (-not $outputFolder) {
    $outputFolder = "./output"
    Write-Host "Using default value of './output'" -ForegroundColor $colorSuccess
}

# Prompt for video quality (CRF value)
Write-Host "`nEnter the Constant Rate Factor (CRF) for video quality. The scale is 0 to 51 where 0 is lossless and 51 is worst quality possible" -ForegroundColor $colorHighlight
$crfValue = Read-Host "CRF (Default: '23')"

# Check if CRF value is valid or blank
if (-not $crfValue) {
    $crfValue = 23
    Write-Host "Using default value of '23'" -ForegroundColor $colorSuccess
} elseif (-not [int]::TryParse($crfValue, [ref]$null) -or $crfValue -lt 0 -or $crfValue -gt 51) {
    Write-Host "Invalid CRF value entered. Defaulting to 23." -ForegroundColor $colorError
    $crfValue = 23
}

# Ask the user to choose the encoding method with Intel CPU as the default
Write-Host "`nChoose the encoding method" -ForegroundColor $colorHighlight
Write-Host "t1) Intel CPU (x264) - (Slower, smaller files, higher quality)" -ForegroundColor $colorDefault
Write-Host "t2) NVIDIA GPU (NVENC) - (Faster, bigger files, lower quality)" -ForegroundColor $colorDefault
$encodingChoice = Read-Host "Enter 1 or 2 (Default: '1')"
if (-not $encodingChoice) {
    $videoCodec = "libx264"
    Write-Host "Using default value of 'Intel CPU (x264) encoding'" -ForegroundColor $colorSuccess
} elseif ($encodingChoice -eq 1) {
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
Write-Host "t1) Very slow - Best quality, smallest files"
Write-Host "t2) Slower"
Write-Host "t3) Slow"
Write-Host "t4) Medium (default)"
Write-Host "t5) Fast"
Write-Host "t6) Faster"
Write-Host "t7) Very fast"
Write-Host "t8) Super fast"
Write-Host "t9) Ultra fast - Lower quality, largest files"
$encodingSpeed = Read-Host "Enter 1 to 8 (default is 4)"
if (-not $encodingSpeed) {
    $encodingSpeed = 4
    Write-Host "Using default value of 'Medium' encoding speed" -ForegroundColor $colorSuccess
}

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
	8 { $speedPreset = "superfast" }
	9 { $speedPreset = "ultrafast" }
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

	# Extract the metadata from the original file using exiftool
	Write-Host "`n[$currentFile/$totalFiles] Extracting metadata for $($file.Name)..." -ForegroundColor $colorHighlight
	$exifData = & exiftool -json "$filePath" | ConvertFrom-Json

	# Extract relevant metadata from the JSON object
	$recordedDate = $exifData.DateTimeOriginal
	$make = $exifData.Make
	$model = $exifData.Model
	$fNumber = $exifData.FNumber
	$exposureTime = $exifData.ExposureTime
	$whiteBalance = $exifData.WhiteBalance
	$gain = $exifData.Gain
	$exposureProgram = $exifData.ExposureProgram
	$focus = $exifData.Focus
	$imageStabilization = $exifData.ImageStabilization

	if (-not $recordedDate) {
		Write-Host "Error: Could not extract 'Recorded date'. Skipping $($file.Name)" -ForegroundColor $colorError
		continue
	}

	# Use regex to remove the timezone (e.g., "-05:00") from the date string
	$cleanedDate = $recordedDate -replace "-\d{2}:\d{2}$", ""

	# Replace colons with dashes in the time portion
	$formattedDate = $cleanedDate -replace ":", "-" -replace " ", "_"

	# Set the output file name based on the formatted date
	$outputFile = Join-Path $outputFolder "$formattedDate.mp4"

	Write-Host "[$currentFile/$totalFiles] Converting $($file.Name) to MP4 using $videoCodec with CRF=$crfValue and preset=$speedPreset..." -ForegroundColor $colorHighlight

	# Convert the .MTS file to .MP4 using ffmpeg with either NVIDIA or Intel CPU encoding
	& ffmpeg -i "$filePath" -c:v $videoCodec -preset $speedPreset -crf $crfValue -c:a ac3 -b:a 256k "$outputFile"

	# Prepare the command to add metadata to the MP4 file
	$command = @(
		"-overwrite_original",
		"-CreateDate=$recordedDate",
		"-ModifyDate=$recordedDate",
		"-QuickTime:CreateDate=$recordedDate",
		"-QuickTime:ModifyDate=$recordedDate"
	)

	# Only add non-empty metadata values
	if ($make) { $command += "-XMP:Make=$make" }
	if ($model) { $command += "-XMP:Model=$model" }
	if ($fNumber) { $command += "-XMP:FNumber=$fNumber" }
	if ($exposureTime) { $command += "-XMP:ExposureTime=$exposureTime" }
	if ($whiteBalance) { $command += "-XMP:WhiteBalance=$whiteBalance" }
	if ($gain) { $command += "-XMP:Gain=$gain" }
	if ($exposureProgram) { $command += "-XMP:ExposureProgram=$exposureProgram" }
	if ($focus) { $command += "-XMP:Focus=$focus" }
	if ($imageStabilization) { $command += "-XMP:ImageStabilization=$imageStabilization" }

	# Add the output file path to the command
	$command += "$outputFile"

	Write-Host "[$currentFile/$totalFiles] Writing XMP and QuickTime metadata to $($outputFile)..." -ForegroundColor $colorHighlight

	# Apply the metadata using exiftool
	& exiftool @command

	Write-Host "[$currentFile/$totalFiles] Finished processing $($file.Name). Output saved as $formattedDate.mp4" -ForegroundColor $colorSuccess
	Write-Host "-----------------------------------------------------------"
}

Write-Host "All files processed. Press any key to close the window..." -ForegroundColor $colorSuccess

# Wait for user to press any key before exiting
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
