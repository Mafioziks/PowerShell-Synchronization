$sourceFolder=$args[0]
$destinationFolder=$args[1]
$logLocation=$args[2]
$logFile="$logLocation\sync.log"

if (-NOT(Test-Path $sourceFolder)) {
    Write-Host "Source folder does not exist!"
    exit
}

if (-NOT(Test-Path $destinationFolder)) {
    Write-Host "Destination folder does not exists!"
    exit
}

if (-NOT(Test-Path $logLocation)) {
    Write-Host "Log folder does not exists!"
    exit
}

function Write-Log($action, $content) {
    Add-Content -Path $logFile -Value ((Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz") + " $action`: `t$content")
}

function Update-FilesAndFolders ($sourcePath, $destinationPath) {
    foreach ($item in (Get-ChildItem $sourcePath)) {
        $sourceItem="$sourcePath\" + $item.Name
        $destinationItem="$destinationPath\" + $item.Name

        if (-NOT(Test-Path "$destinationItem")) {
            Copy-Item "$sourceItem" -Recurse -Destination "$destinationItem"
            Write-Log "ADDED" $destinationItem
            continue
        } 

        if (Test-Path $item.FullName -PathType Leaf) {
            if (-NOT((Get-FileHash $item.FullName).Hash -eq (Get-FileHash "$destinationItem").Hash)) {
                Copy-Item "$sourceItem" -Recurse -Destination "$destinationItem"
                Write-Log "UPDATED" $destinationItem
            }
            continue
        }

        Update-FilesAndFolders $sourceItem "$destinationItem"
    }
}

function Update-ClearRemoved($sourcePath, $destinationPath) {
    foreach ($item in (Get-ChildItem $destinationPath)) {
        $sourceItem="$sourcePath\" + $item.Name
        $destinationItem="$destinationPath\" + $item.Name

        if (-NOT(Test-Path $sourceItem)) {
            Remove-Item $destinationItem -Recurse
            Write-Log "REMOVED" $destinationItem
            continue
        }

        if (Test-Path $item.FullName -PathType Container) {
            Update-ClearRemoved $sourceItem $destinationItem
        }
    }
}

function Synchronyze($sourcePath, $destinationPath) {
    Update-ClearRemoved $sourcePath $destinationPath 
    Update-FilesAndFolders $sourcePath $destinationPath
} 

Synchronyze $sourceFolder $destinationFolder
Write-Host "Synchronization finished"
