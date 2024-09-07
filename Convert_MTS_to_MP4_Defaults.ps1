# =====================================================
# GLOBAL VARIABLES
# =====================================================

# Import the Stopwatch class for timing the script execution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Define output variables
$colorHighlight = "Yellow"
$colorError = "Red"
$colorSuccess = "Green"
$line = "====================================================="

# Default options
$inputFolder = "."
$outputFolder = "./output"
$crfValue = 23
$videoCodec = "libx264"
$speedPreset = "medium"

# =====================================================
# START ENCODING
# =====================================================

Write-Host "$line" -ForegroundColor $colorHighlight
Write-Host "`n MTS to MP4 Bulk Converter" -ForegroundColor $colorHighlight
Write-Host "`n$line" -ForegroundColor $colorHighlight

# Create the output folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
	New-Item -ItemType Directory -Path $outputFolder
}

# Get all .MTS files in the input folder
$inputFiles = Get-ChildItem -Path $inputFolder -Filter *.MTS
$outputFiles = @()

# Initialize lists for file sizes
$inputSizes = @()
$outputSizes = @()

# Total number of files
$totalFiles = $inputFiles.Count
$currentFile = 0

foreach ($inputFile in $inputFiles) {
	$currentFile++
	
	# Get the full path of the .MTS file
	$filePath = $inputFile.FullName

	# Record the input file size in megabytes
	$inputSize = [math]::round(($inputFile.Length / 1MB), 2)
	$inputSizes += $inputSize

	# Extract the metadata from the original file using exiftool
	Write-Host "`n[$currentFile/$totalFiles] Extracting metadata for $($inputFile.Name)..." -ForegroundColor $colorHighlight
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

	# Record the output file size in megabytes
	$outputSize = [math]::round((Get-Item $outputFile).Length / 1MB, 2)
	$outputSizes += $outputSize

	Write-Host "[$currentFile/$totalFiles] Finished processing $($inputFile.Name). Output saved as $formattedDate.mp4" -ForegroundColor $colorSuccess
	Write-Host "`n$line"
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

# Settings summary
Write-Host "`nSettings`n" -ForegroundColor $colorHighlight
Write-Host "Input folder: $inputFolder"
Write-Host "Output folder: $outputFolder"
Write-Host "CRF value: $crfValue"
Write-Host "Encoding method: $videoCodec"
Write-Host "Encoding speed preset: $speedPreset"

# Individual file summary
Write-Host "`nIndividual Files" -ForegroundColor $colorHighlight
for ($i = 0; $i -lt $inputFiles.Count; $i++) {
    Write-Host "`n$($inputFiles[$i].Name) > $($outputFiles[$i])"
	Write-Host "Input Size: $($inputSizes[$i]) MB | Output Size: $($outputSizes[$i]) MB | Change: $([math]::round((($outputSizes[$i] - $inputSizes[$i]) / $inputSizes[$i]) * 100, 2))%"
}

# Total file summary
Write-Host "`nTotals`n" -ForegroundColor $colorHighlight

$inputTotal = [math]::round(($inputSizes | Measure-Object -Sum | Select-Object -ExpandProperty Sum), 2)
$outputTotal = [math]::round(($outputSizes | Measure-Object -Sum | Select-Object -ExpandProperty Sum), 2)
$sizeChange = [math]::round((($outputTotal - $inputTotal) / $inputTotal) * 100, 2)

Write-Host "Total Input Size: $inputTotal MB"
Write-Host "Total Output Size: $outputTotal MB"
Write-Host "Overall File Size Change: $sizeChange%"

Write-Host "`nTotal time taken: $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s"

Write-Host "`n$line" -ForegroundColor $colorHighlight

# End
Write-Host "`nAll files processed. Press any key to close the window..." -ForegroundColor $colorSuccess

# Wait for user to press any key before exiting
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
