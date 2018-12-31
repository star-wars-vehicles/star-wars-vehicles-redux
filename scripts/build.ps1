
# Create the build directory
If (!(Test-Path -PathType Container -Path .\build)) {
  New-Item -ItemType Directory -Force -Path .\build
}

Get-ChildItem -Recurse -File "lua" |
  ForEach-Object {
  # Create the subdirectory in the build lua directory for the current lua subdirectory
  If (!(Test-Path -PathType Container -Path (".\build\lua\" + $_.Directory.Name))) {
    New-Item -ItemType Directory -Force -Path (".\build\lua\" + $_.Directory.Name)
  }

  $outdir = (Get-Item -Path ".\").FullName + "\build\lua\" + $_.Directory.Name + "\" + $_
  LuaSrcDiet --none --opt-comments --opt-emptylines $_.FullName -o $outdir
}

# Copy the other resources to the build directory

If ((Test-Path -PathType Container -Path .\materials)) {
  Copy-Item ".\materials" -Destination .\build\materials -Recurse
}

If ((Test-Path -PathType Container -Path .\models)) {
  Copy-Item ".\models" -Destination .\build\models -Recurse
}

If ((Test-Path -PathType Container -Path .\sound)) {
  Copy-Item ".\sound" -Destination .\build\sound -Recurse
}

# Compress the build directory

Get-ChildItem ".\build" -Directory |
  ForEach-Object {
  Compress-Archive -Path $_ -DestinationPath ".\star-wars-vehicles-redux.zip" -Update
}

# Cleanup the build directory

Remove-Item ".\build" -Force  -Recurse -ErrorAction SilentlyContinue
