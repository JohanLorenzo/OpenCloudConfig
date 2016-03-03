<#
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
#>
Configuration CompilerToolChainConfig {
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  # log folder for installation logs
  File LogFolder {
    Type = 'Directory'
    DestinationPath = ('{0}\log' -f $env:SystemDrive)
    Ensure = 'Present'
  }
  
  Script DirectXSdkDownload {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\DXSDK_Jun10.exe' -f $env:Temp) -ErrorAction SilentlyContinue) } }
    SetScript = {
      (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/A/E/7/AE743F1F-632B-4809-87A9-AA1BB3458E31/DXSDK_Jun10.exe', ('{0}\DXSDK_Jun10.exe' -f $env:Temp))
      Unblock-File -Path ('{0}\DXSDK_Jun10.exe' -f $env:Temp)
    }
    TestScript = { if (Test-Path -Path ('{0}\DXSDK_Jun10.exe' -f $env:Temp) -ErrorAction SilentlyContinue) { $true } else { $false } }
  }
  Script DirectXSdkInstall {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\Microsoft DirectX SDK (June 2010)\system\uninstall\DXSDK_Jun10.exe' -f ${env:ProgramFiles(x86)}) -ErrorAction SilentlyContinue) } }
    SetScript = {
      # https://blogs.msdn.microsoft.com/chuckw/2011/12/09/known-issue-directx-sdk-june-2010-setup-and-the-s1023-error/
      Start-Process 'MsiExec.exe' -ArgumentList '/passive /X{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}' -Wait -NoNewWindow -PassThru -RedirectStandardOutput ('{0}\log\{1}.vcredist2010x86.uninstall.stdout.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss")) -RedirectStandardError ('{0}\log\{1}.vcredist2010x86.uninstall.stderr.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss"))
      Start-Process 'MsiExec.exe' -ArgumentList '/passive /X{1D8E6291-B0D5-35EC-8441-6616F567A0F7}' -Wait -NoNewWindow -PassThru -RedirectStandardOutput ('{0}\log\{1}.vcredist2010x64.uninstall.stdout.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss")) -RedirectStandardError ('{0}\log\{1}.vcredist2010x64.uninstall.stderr.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss"))
      Start-Process ('{0}\DXSDK_Jun10.exe' -f $env:Temp) -ArgumentList '/U' -Wait -NoNewWindow -PassThru -RedirectStandardOutput ('{0}\log\{1}.DXSDK_Jun10.exe.stdout.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss")) -RedirectStandardError ('{0}\log\{1}.DXSDK_Jun10.exe.stderr.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss"))
    }
    TestScript = { if (Test-Path -Path ('{0}\Microsoft DirectX SDK (June 2010)\system\uninstall\DXSDK_Jun10.exe' -f ${env:ProgramFiles(x86)}) -ErrorAction SilentlyContinue) { $true } else { $false } }
  }

  Chocolatey VCRedist2010Install {
    Ensure = 'Present'
    Package = 'vcredist2010'
    Version = '10.0.40219.1'
  }
  Chocolatey WindowsSdkInstall {
    Ensure = 'Present'
    Package = 'windows-sdk-8.1'
    Version = '8.100.26654.0'
  }

  Script RustDownload {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\Temp\rust-1.6.0-x86_64-pc-windows-msvc.msi' -f $env:SystemRoot) -ErrorAction SilentlyContinue) } }
    SetScript = {
      (New-Object Net.WebClient).DownloadFile('https://static.rust-lang.org/dist/rust-1.6.0-x86_64-pc-windows-msvc.msi', ('{0}\Temp\rust-1.6.0-x86_64-pc-windows-msvc.msi' -f $env:SystemRoot))
      Unblock-File -Path ('{0}\Temp\rust-1.6.0-x86_64-pc-windows-msvc.msi' -f $env:SystemRoot)
    }
    TestScript = { if (Test-Path -Path ('{0}\Temp\rust-1.6.0-x86_64-pc-windows-msvc.msi' -f $env:SystemRoot) -ErrorAction SilentlyContinue) { $true } else { $false } }
  }
  Package RustInstall {
    Name = 'Rust 1.6 (MSVC 64-bit)'
    Path = ('{0}\Temp\rust-1.6.0-x86_64-pc-windows-msvc.msi' -f $env:SystemRoot)
    ProductId = 'A21886AC-C591-4CC0-BA5B-C080B88F630B'
    Ensure = 'Present'
    LogPath = ('{0}\log\{1}.rust-1.6.0-x86_64-pc-windows-msvc.msi.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss"))
  }
  Script RustSymbolicLink {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\tools\rust' -f $env:SystemDrive) -ErrorAction SilentlyContinue) } }
    SetScript = {
      if ($PSVersionTable.PSVersion.Major -gt 4) {
        New-Item -ItemType SymbolicLink -Path ('{0}\tools' -f $env:SystemDrive) -Name 'rust' -Target ('{0}\Rust MSVC 1.6' -f $env:ProgramFiles)
      } else {
        & cmd @('/c', 'mklink', '/D', ('{0}\tools\rust' -f $env:SystemDrive), ('{0}\Rust MSVC 1.6' -f $env:ProgramFiles))
      }
    }
    TestScript = { (Test-Path -Path ('{0}\tools\rust' -f $env:SystemDrive) -ErrorAction SilentlyContinue) }
  }
  
  Script MozillaBuildDownload {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\Temp\MozillaBuildSetup-2.1.0.exe' -f $env:SystemRoot)) } }
    SetScript = {
      (New-Object Net.WebClient).DownloadFile('http://ftp.mozilla.org/pub/mozilla/libraries/win32/MozillaBuildSetup-2.1.0.exe', ('{0}\Temp\MozillaBuildSetup-2.1.0.exe' -f $env:SystemRoot))
      Unblock-File -Path ('{0}\Temp\MozillaBuildSetup-2.1.0.exe' -f $env:SystemRoot)
    }
    TestScript = { if (Test-Path -Path ('{0}\Temp\MozillaBuildSetup-2.1.0.exe' -f $env:SystemRoot) -ErrorAction SilentlyContinue) { $true } else { $false } }
  }
  Script MozillaBuildInstall {
    GetScript = { @{ Result = (Test-Path -Path ('{0}\mozilla-build\VERSION' -f $env:SystemDrive)) } }
    SetScript = {
      Start-Process ('{0}\Temp\MozillaBuildSetup-2.1.0.exe' -f $env:SystemRoot) -ArgumentList '/S' -Wait -NoNewWindow -PassThru -RedirectStandardOutput ('{0}\log\{1}.MozillaBuildSetup-2.1.0.exe.stdout.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss")) -RedirectStandardError ('{0}\log\{1}.MozillaBuildSetup-2.1.0.exe.stderr.log' -f $env:SystemDrive, [DateTime]::Now.ToString("yyyyMMddHHmmss"))
    }
    TestScript = { ((Test-Path -Path ('{0}\mozilla-build\VERSION' -f $env:SystemDrive)) -and ((Get-Content ('{0}\mozilla-build\VERSION' -f $env:SystemDrive)) -eq '2.1.0')) }
  }
}