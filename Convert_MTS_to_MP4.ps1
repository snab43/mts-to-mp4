# =====================================================
# GLOBAL VARIABLES
# =====================================================

# Import the Stopwatch class for timing the script execution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Define output variables
$colorSecondary = "Gray"
$colorHighlight = "Yellow"
$colorWarning = "Yellow"
$colorError = "Red"
$colorSuccess = "Green"
$line = "====================================================="

# =====================================================
# USER INPUT
# =====================================================

Write-Host "$line" -ForegroundColor $colorHighlight
Write-Host "`n MTS to MP4 Bulk Converter" -ForegroundColor $colorHighlight
Write-Host "`n$line" -ForegroundColor $colorHighlight

# Get input folder
Write-Host "`nEnter the input folder path" -ForegroundColor $colorHighlight
Write-Host "Default: '.'" -ForegroundColor $colorSecondary
$inputFolder = Read-Host "Input folder path"
if (-not $inputFolder) {
	$inputFolder = "."
	Write-Host "Using default value of '.'" -ForegroundColor $colorSuccess
}

# Get output folder
Write-Host "`nEnter the output folder path" -ForegroundColor $colorHighlight
Write-Host "Default: './output'" -ForegroundColor $colorSecondary
$outputFolder = Read-Host "Output folder path"
if (-not $outputFolder) {
	$outputFolder = "./output"
	Write-Host "Using default value of './output'" -ForegroundColor $colorSuccess
}

# Get video quality (CRF value)
Write-Host "`nEnter the Constant Rate Factor (CRF) for video quality" -ForegroundColor $colorHighlight
Write-Host "The scale is 0 to 51 where 0 is lossless and 51 is worst quality possible. The recommended range is 17-28." -ForegroundColor $colorSecondary
Write-Host "Default: '23'" -ForegroundColor $colorSecondary
$crfValue = Read-Host "CRF"
if (-not $crfValue) {
	$crfValue = 23
	Write-Host "Using default value of '23'" -ForegroundColor $colorSuccess
} elseif (-not [int]::TryParse($crfValue, [ref]$null) -or $crfValue -lt 0 -or $crfValue -gt 51) {
	Write-Host "Invalid CRF value entered. Defaulting to 23." -ForegroundColor $colorError
	$crfValue = 23
}

# Get audio quality
Write-Host "`nChoose the audio bitrate for audio quality" -ForegroundColor $colorHighlight
Write-Host "Audio is compressed to AC3 format." -ForegroundColor $colorSecondary
Write-Host "  1)  96 kbps - Low quality, smaller files"
Write-Host "  2) 128 kbps"
Write-Host "  3) 192 kbps"
Write-Host "  4) 256 kbps (default)"
Write-Host "  5) 320 kbps - Maximum quality, largest files"
Write-Host "Default: '4'" -ForegroundColor $colorSecondary
$audioBitrateChoice = Read-Host "Enter 1 to 5"
if (-not $audioBitrateChoice) {
	$audioBitrateChoice = 4
	Write-Host "Using default value of '256 kbps' audio bitrate." -ForegroundColor $colorSuccess
}

$audioBitratePreset = ""
switch ($audioBitrateChoice) {
	1 { $audioBitratePreset = "96k" }
	2 { $audioBitratePreset = "128k" }
	3 { $audioBitratePreset = "192k" }
	4 { $audioBitratePreset = "256k" }
	5 { $audioBitratePreset = "320k" }
	default { $audioBitratePreset = "256k"; Write-Host "Invalid option. Defaulting to '256 kbps' bitrate." -ForegroundColor $colorError }
}

# Get encoding method
Write-Host "`nChoose the encoding method" -ForegroundColor $colorHighlight
Write-Host "It's recommended to use CPU encoding (1). NVIDIA GPU encoding is faster but the quality can be worse." -ForegroundColor $colorSecondary
Write-Host "`t1) CPU (libx264)"
Write-Host "`t2) NVIDIA GPU (h264_nvenc)"
Write-Host "Default: '1'" -ForegroundColor $colorSecondary
$encodingChoice = Read-Host "Enter 1 or 2"
if (-not $encodingChoice) {
	$videoCodec = "libx264"
	Write-Host "Using default value of 'CPU (libx264)' encoding." -ForegroundColor $colorSuccess
} elseif ($encodingChoice -eq 1) {
	$videoCodec = "libx264"
} elseif ($encodingChoice -eq 2) {
	$videoCodec = "h264_nvenc"
} else {
	$videoCodec = "libx264"
	Write-Host "Invalid option. Defaulting to 'CPU (libx264)' encoding." -ForegroundColor $colorError
}

# Get encoding speed
Write-Host "`nChoose the encoding speed (affects file size and quality):" -ForegroundColor $colorHighlight
Write-Host "  1) Very slow - Best quality, smallest files"
Write-Host "  2) Slower"
Write-Host "  3) Slow"
Write-Host "  4) Medium (default)"
Write-Host "  5) Fast"
Write-Host "  6) Faster"
Write-Host "  7) Very fast"
Write-Host "  8) Super fast"
Write-Host "  9) Ultra fast - Lower quality, largest files"
Write-Host "Default: '4'" -ForegroundColor $colorSecondary
$encodingSpeed = Read-Host "Enter 1 to 9"
if (-not $encodingSpeed) {
	$encodingSpeed = 4
	Write-Host "Using default value of 'Medium' encoding speed." -ForegroundColor $colorSuccess
}

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
	default { $speedPreset = "medium"; Write-Host "Invalid option. Defaulting to 'Medium' encoding speed." -ForegroundColor $colorError }
}

# Settings summary
Write-Host "`n`nHere are your settings, does everything look correct?" -ForegroundColor $colorHighlight
Write-Host "Input folder: $inputFolder"
Write-Host "Output folder: $outputFolder"
Write-Host "CRF value: $crfValue"
Write-Host "Audio bitrate: $audioBitratePreset"
Write-Host "Encoding method: $videoCodec"
Write-Host "Encoding speed: $speedPreset"

Write-Host "`nPress any key to continue..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# =====================================================
# START ENCODING
# =====================================================

Write-Host "`n$line" -ForegroundColor $colorHighlight
Write-Host "`n Starting Encode" -ForegroundColor $colorHighlight
Write-Host "`n$line`n" -ForegroundColor $colorHighlight

# Create the output folder if it doesn't exist
Write-Host "Looking for output folder..."
if (-not (Test-Path $outputFolder)) {
	Write-Host "Output folder doesn't exist, creating it...." -ForegroundColor $colorWarning
	$null = New-Item -ItemType Directory -Path $outputFolder
	Write-Host "Output folder created.`n" -ForegroundColor $colorSuccess
} else {
	Write-Host "Found output folder.`n" -ForegroundColor $colorSuccess
}

# Create variables
$inputFiles = Get-ChildItem -Path $inputFolder -Filter *.MTS
$outputFiles = @()

$inputSizes = @()
$outputSizes = @()

$totalFiles = $inputFiles.Count
$currentFile = 0

foreach ($inputFile in $inputFiles) {
	$currentFile++
	
	# Starting
	Write-Host "`n[$currentFile/$totalFiles] $($inputFile.Name)`n" -ForegroundColor $colorHighlight

	# Get the full path of the .MTS file
	$filePath = $inputFile.FullName

	# Record the input file size in megabytes
	$inputSize = [math]::round(($inputFile.Length / 1MB), 2)
	$inputSizes += $inputSize

	# Extract the metadata from the original file using exiftool
	Write-Host "Extracting metadata for $($inputFile.Name)..."
	$exifData = & exiftool -json "$filePath" | ConvertFrom-Json

	# Extract relevant metadata from the JSON object
	$recordedDate = $exifData.DateTimeOriginal
	$make = $exifData.Make
	$model = $exifData.Model
	$fNumber = $exifData.FNumber
	$exposureTime = $exifData.ExposureTime
	$whiteBalance = $exifData.WhiteBalance
	$exposureProgram = $exifData.ExposureProgram

	if (-not $recordedDate) {
		Write-Host "Error: Could not extract 'Recorded date'. Skipping $($inputFile.Name)" -ForegroundColor $colorError
		continue
	}

	# Use regex to remove the timezone (e.g., "-05:00") from the date string
	$cleanedDate = $recordedDate -replace "-\d{2}:\d{2}$", ""

	# Replace colons with dashes in the time portion
	$formattedDate = $cleanedDate -replace ":", "-" -replace " ", "_"

	# Set the output file name based on the formatted date
	$outputFile = Join-Path $outputFolder "$formattedDate.mp4"
	$outputFiles += "$formattedDate.mp4"

	# Check if the video is interlaced
	Write-Host "Checking for interlaced footage..."
	$isInterlaced = & ffprobe -v error -select_streams v:0 -show_entries stream=field_order -of default=noprint_wrappers=1:nokey=1 "$filePath"

	# Prepare the base FFmpeg command
	$ffmpegCommand = "ffmpeg -loglevel warning -stats -i `"$filePath`" -c:v $videoCodec -preset $speedPreset -crf $crfValue -c:a ac3 -b:a $audioBitratePreset"

	# Add de-interlacing filter if the video is interlaced
	if ($isInterlaced -eq "tt" -or $isInterlaced -eq "tb" -or $isInterlaced -eq "bt" -or $isInterlaced -eq "bb") {
		Write-Host "Video is interlaced. Adding de-interlacing filter (yadif)." -ForegroundColor $colorWarning
		$ffmpegCommand += " -vf yadif"
	} else {
		Write-Host "Video is not interlaced. No de-interlacing needed."
	}

	# Add the output file to the command
	$ffmpegCommand += " `"$outputFile`""

	# Run the FFmpeg command
	Write-Host "Converting $($inputFile.Name) to $formattedDate.mp4..."
	Invoke-Expression $ffmpegCommand

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
	if ($exposureProgram) { $command += "-XMP:ExposureProgram=$exposureProgram" }

	# Add the output file path to the command
	$command += "$outputFile"

	Write-Host "Writing EXIF and XMP metadata..."

	# Apply the metadata using exiftool
	& exiftool @command

	# Record the output file size in megabytes
	$outputSize = [math]::round((Get-Item $outputFile).Length / 1MB, 2)
	$outputSizes += $outputSize

	# Finished
	Write-Host "Finished processing $($inputFile.Name). Output saved as $($outputFile)." -ForegroundColor $colorSuccess
	Write-Host "Input Size: $($inputSize) MB | Output Size: $($outputSize) MB | Change: $([math]::round((($outputSize - $inputSize) / $inputSize) * 100, 2))%`n" -ForegroundColor $colorSecondary
}

# =====================================================
# COMPLETE
# =====================================================

# Stop the stopwatch to measure the time taken
$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed

# Summary Section
Write-Host "`n$line" -ForegroundColor $colorHighlight
Write-Host "`n Summary" -ForegroundColor $colorHighlight
Write-Host "`n$line" -ForegroundColor $colorHighlight

# Settings
Write-Host "`nSettings`n" -ForegroundColor $colorHighlight
Write-Host "Input folder: $inputFolder"
Write-Host "Output folder: $outputFolder"
Write-Host "CRF value: $crfValue"
Write-Host "Audio bitrate: $audioBitratePreset"
Write-Host "Encoding method: $videoCodec"
Write-Host "Encoding speed preset: $speedPreset"

# Individual files
Write-Host "`nFiles`n" -ForegroundColor $colorHighlight
for ($i = 0; $i -lt $inputFiles.Count; $i++) {
	Write-Host "$($inputFiles[$i].Name) ($($inputSizes[$i]) MB) > $($outputFiles[$i]) ($($outputSizes[$i]) MB) [$([math]::round((($outputSizes[$i] - $inputSizes[$i]) / $inputSizes[$i]) * 100, 2))%]"
}

# Total files
Write-Host "`nTotals`n" -ForegroundColor $colorHighlight

$inputTotal = [math]::round(($inputSizes | Measure-Object -Sum | Select-Object -ExpandProperty Sum), 2)
$outputTotal = [math]::round(($outputSizes | Measure-Object -Sum | Select-Object -ExpandProperty Sum), 2)
$sizeChange = [math]::round((($outputTotal - $inputTotal) / $inputTotal) * 100, 2)

Write-Host "Total Input Size: $inputTotal MB"
Write-Host "Total Output Size: $outputTotal MB"
Write-Host "Overall File Size Change: $sizeChange%"

Write-Host "`nTotal time taken: $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s"

# End
Write-Host "`nAll files processed. Press any key to close the window..." -ForegroundColor $colorSuccess
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
