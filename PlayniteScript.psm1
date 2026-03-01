function Get-ConfigFilePath {
    $configDir = Join-Path $env:APPDATA "Playnite\ExtensionsData\LudusaviHelper"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    return Join-Path $configDir "manifest_path.txt"
}

function SetManifestPath {
    param($scriptGameMenuItemActionArgs)
    
    $configFile = Get-ConfigFilePath
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "YAML Files (*.yaml;*.yml)|*.yaml;*.yml|All Files (*.*)|*.*"
    $dialog.Title = $PlayniteApi.Resources.GetString("LOC_Ludu_SelectManifestTitle")
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $dialog.FileName
        Set-Content -Path $configFile -Value $selectedPath -Encoding UTF8
        
        $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_LinkSuccessMsg") -f $selectedPath
        $title = $PlayniteApi.Resources.GetString("LOC_Ludu_SetupComplete")
        $PlayniteApi.Dialogs.ShowMessage($msg, $title)
    }
}

function AddToManifest {
    param($scriptGameMenuItemActionArgs)

    $configFile = Get-ConfigFilePath
    if (-not (Test-Path $configFile)) {
        $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_ErrNotConfiguredMsg")
        $title = $PlayniteApi.Resources.GetString("LOC_Ludu_NotConfigured")
        $PlayniteApi.Dialogs.ShowErrorMessage($msg, $title)
        return
    }
    
    $manifestPath = (Get-Content -Path $configFile -Raw).Trim()
    
    if ([string]::IsNullOrEmpty($manifestPath) -or -not (Test-Path $manifestPath)) {
         $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_ErrMissingMsg") -f $manifestPath
         $title = $PlayniteApi.Resources.GetString("LOC_Ludu_FileMissing")
         $PlayniteApi.Dialogs.ShowErrorMessage($msg, $title)
         return
    }

    $game = $PlayniteApi.MainView.SelectedGames[0]
    if ($null -eq $game) { return }
    $gameName = $game.Name
    $installDir = $game.InstallDirectory

    $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_SelectTypeMsg")
    $title = $PlayniteApi.Resources.GetString("LOC_Ludu_SelectType")
    $choice = $PlayniteApi.Dialogs.ShowMessage($msg, $title, [System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
    
    if ($choice -eq "Cancel") { return }
    
    $selectedPath = ""
    $defaultWildcard = "*"
    
    if ($choice -eq "Yes") {
        $selectedPath = $PlayniteApi.Dialogs.SelectFolder()
        if ([string]::IsNullOrEmpty($selectedPath)) { return }
        $defaultWildcard = "*" 
    }
    else {
        $selectedPath = $PlayniteApi.Dialogs.SelectFile("All Files|*.*")
        if ([string]::IsNullOrEmpty($selectedPath)) { return }
        $defaultWildcard = [System.IO.Path]::GetFileName($selectedPath)
        $selectedPath = [System.IO.Path]::GetDirectoryName($selectedPath)
    }

    $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_SetWildcardMsg") -f $selectedPath
    $title = $PlayniteApi.Resources.GetString("LOC_Ludu_SetWildcard")
    $patternResult = $PlayniteApi.Dialogs.SelectString($msg, $title, $defaultWildcard)
    if ($patternResult.Result -eq $false) { return }
    $globPattern = $patternResult.SelectedString

    $docs = [Environment]::GetFolderPath("MyDocuments")
    $appData = [Environment]::GetFolderPath("ApplicationData")
    $localAppData = [Environment]::GetFolderPath("LocalApplicationData")
    
    function Get-LudusaviPath ($fullPath, $basePath, $placeholder) {
        if ([string]::IsNullOrEmpty($basePath)) { return $null }
        if ($fullPath.StartsWith($basePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $rel = $fullPath.Substring($basePath.Length).TrimStart('\', '/')
            if ($rel -eq "") { return $placeholder }
            return "$placeholder/$rel"
        }
        return $null
    }
    
    $finalPath = $selectedPath
    $converted = Get-LudusaviPath $selectedPath $installDir "<base>"
    if ($null -eq $converted) { $converted = Get-LudusaviPath $selectedPath $docs "<winDocuments>" }
    if ($null -eq $converted) { $converted = Get-LudusaviPath $selectedPath $appData "<winAppData>" }
    if ($null -eq $converted) { $converted = Get-LudusaviPath $selectedPath $localAppData "<winLocalAppData>" }
    if ($null -ne $converted) { $finalPath = $converted }
    
    $finalPath = $finalPath -replace "\\", "/"
    if (-not $finalPath.EndsWith("/")) { $finalPath += "/" }
    $finalEntry = "$finalPath$globPattern"

    $yamlEntry = @"
"$gameName":
  files:
    "$finalEntry":
      tags:
        - save
      when:
        - os: windows
"@

    try {
        Add-Content -Path $manifestPath -Value $yamlEntry -Encoding UTF8
        $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_SuccessMsg") -f $manifestPath, $finalEntry
        $title = $PlayniteApi.Resources.GetString("LOC_Ludu_Success")
        $PlayniteApi.Dialogs.ShowMessage($msg, $title)
    }
    catch {
        $msg = $PlayniteApi.Resources.GetString("LOC_Ludu_WriteFailMsg") -f $_
        $title = $PlayniteApi.Resources.GetString("LOC_Ludu_Error")
        $PlayniteApi.Dialogs.ShowErrorMessage($msg, $title)
    }
}

function GetGameMenuItems {
    param($getGameMenuItemsArgs)

    $btnLink = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $btnLink.Description = $PlayniteApi.Resources.GetString("LOC_Ludu_MenuLink")
    $btnLink.FunctionName = "SetManifestPath"
    $btnLink.MenuSection = "Ludusavi"

    $btnAdd = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $btnAdd.Description = $PlayniteApi.Resources.GetString("LOC_Ludu_MenuAdd")
    $btnAdd.FunctionName = "AddToManifest"
    $btnAdd.MenuSection = "Ludusavi"
    
    return $btnLink, $btnAdd
}