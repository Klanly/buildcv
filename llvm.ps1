#!/usr/bin/env pwsh

#
# Config
#

$build_llvm = $true
$generate_msvc = $false

#
# Set root dir
#
Push-Location $PSScriptRoot
$root = (Get-Location).Path -replace "\\","/"


#
# Helpers
#

function Get-OS()
{
    if($PSVersionTable.PSEdition -ne "Core")
    {
        return "windows"
    }

    if($PSVersionTable.OS.StartsWith("Microsoft"))
    {
        return "windows"
    }

    if($PSVersionTable.OS.StartsWith("Linux"))
    {
        return "linux"
    }

    return "unknown"
}


function Get-Architecture()
{
    $os = Get-OS

    if($os -eq "windows")
    {
        switch(${env:PROCESSOR_ARCHITECTURE})
        {
            AMD64
            {
                return "amd64"
            }
            x86
            {
                return "i686"
            }
        }
    }
    elseif($os -eq "linux")
    {
        switch ($(uname -m))
        {
            x86_64
            {
                return "amd64"
            }
        }
    }

    return "Unknown"
}

function Set-BuildEnvironment(){
    if("windows" -eq $(Get-OS)){
        #https://stackoverflow.com/a/64744522
        Push-Location "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools"
        cmd /c "VsDevCmd.bat -arch=amd64 -host_arch=amd64&set " |
        ForEach-Object {
        if ($_ -match "=") {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
        }
        Pop-Location
    }
}


function Sign-IsAvailable(){
    if ("windows" -ne $(Get-OS)){
        return $false
    }

    return $null -ne $(Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert)
}

function Sign-File($FilePath, $TimestampServer = "http://time.certum.pl/")
{
    $cert=Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
    Set-AuthenticodeSignature -FilePath $FilePath -Certificate $cert -TimestampServer $TimestampServer
}

function Sign-Folder($Folder, $Filters = @("*.exe", "*.dll"), $TimestampServer = "http://time.certum.pl/")
{
    foreach($filter in $Filters){
        $files = Get-ChildItem -Path $Folder -Filter $filter -Recurse -ErrorAction SilentlyContinue -Force

        foreach ($file in $files) {
            Sign-File -FilePath $file.FullName -TimestampServer $TimestampServer
        }
    }
}


#
# Build functions
#

function Build-LLVM(){
    if (Test-Path -Path "./~build/llvm_git"){
        Push-Location "./~build/llvm_git"
        git reset --hard
        git pull
        Pop-Location
    }
    else{
        git clone --depth=1 https://github.com/llvm/llvm-project "./~build/llvm_git"
    }

    cmake "./~build/llvm_git/llvm" `
        -B"./~build/llvm_build" `
        -GNinja -DCLANG_CL=1 `
        -DMSVC_RUNTIME_LIBRARY=MultiThreadedDLL `
        -DCMAKE_POLICY_DEFAULT_CMP0091=NEW `
        -DCMAKE_BUILD_TYPE="Release" `
        -DCMAKE_INSTALL_PREFIX="./~build/llvm_install" `
        -DLLVM_BUILD_LLVM_C_DYLIB=OFF `
        -DLLVM_BUILD_RUNTIME=OFF `
        -DLLVM_BUILD_RUNTIMES=OFF `
        -DLLVM_BUILD_TOOLS=OFF `
        -DLLVM_BUILD_UTILS=OFF `
        -DLLVM_ENABLE_BACKTRACES=OFF `
        -DLLVM_ENABLE_BINDINGS=OFF `
        -DLLVM_ENABLE_CRASH_OVERRIDES=OFF `
        -DLLVM_ENABLE_OCAMLDOC=OFF `
        -DLLVM_ENABLE_PDB=ON `
        -DLLVM_INCLUDE_BENCHMARKS=OFF `
        -DLLVM_INCLUDE_DOCS=OFF `
        -DLLVM_INCLUDE_EXAMPLES=OFF `
        -DLLVM_INCLUDE_GO_TESTS=OFF `
        -DLLVM_INCLUDE_RUNTIMES=OFF `
        -DLLVM_INCLUDE_TESTS=OFF `
        -DLLVM_INCLUDE_TOOLS=OFF `
        -DLLVM_INCLUDE_UTILS=OFF `
        -DLLVM_TARGETS_TO_BUILD=""

    cmake --build "./~build/llvm_build"
    cmake --install "./~build/llvm_build"
    New-Item -Path 'c:\llvmlib' -ItemType Directory
    Copy-Item -Path "./~build/llvm_build/lib/*.lib" -Destination "c:\llvmlib" -Recurse
}

function Build-FakePDB(){
    if ($generate_msvc -eq $true) {
        cmake "./src_cpp/" `
            -B"./~build/fakepdb_build" `
            -DCMAKE_BUILD_TYPE="Release" `
            -DCMAKE_INSTALL_PREFIX="./~build/fakepdb_install" `
            -DCMAKE_PREFIX_PATH="$root/~build/llvm_install"
    }

    cmake "./src_cpp/" `
        -B"./~build/fakepdb_build_ninja" `
        -GNinja `
        -DCMAKE_BUILD_TYPE="Release" `
        -DCMAKE_INSTALL_PREFIX="./~build/fakepdb_install" `
        -DCMAKE_PREFIX_PATH="$root/~build/llvm_install"

    cmake --build "./~build/fakepdb_build_ninja"
    cmake --install "./~build/fakepdb_build_ninja"
}


#
# Build pipeline
#

function Build(){
    Set-BuildEnvironment

    if($true -eq $build_llvm){
        Build-LLVM
    }

      
}

Build

Pop-Location
