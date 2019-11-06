@echo off

:: The destination purebasic path (don't use a path with space, don't put double quotes around it)
set PUREBASIC_HOME=C:/PureBasic

:: All the PureBasic tools needed by the makefile, relative to the PureBasic home directory
set PB_LIBRARIES=%PUREBASIC_HOME%/SDK/VisualC/PureLibraries
set PB_LIBRARIAN=%PUREBASIC_HOME%/Compilers/polib.exe
set PB_LIBRARYMAKER=%PUREBASIC_HOME%/SDK/LibraryMaker.exe

:: The dependancies useful to develop on Windows
set PB_VS8=C:/Program Files/Microsoft Visual Studio 10.0
set PB_PLATEFORM_SDK=C:/Program Files/Microsoft SDKs
set PB_DIRECTX9_SDK=C:/Program Files/Microsoft DirectX SDK (August 2009)


set PB_VC8=cl.exe -I"%PB_VS8%/VC/include" -I"%PB_LIBRARIES%" -DWINDOWS -DVISUALC -DX86 -I"%PB_PLATEFORM_SDK%/Windows/v7.0A/Include"  /nologo /GS- /D_CRT_NOFORCE_MANIFEST /D_USE_32BIT_TIME_T

:: Add VisualC++ to the path, so we have access to cl.exe
set PATH=%PB_VS8%/VC/bin;%PB_VS8%/Common7/IDE;%PATH%

cmd