
To compile these examples, you will need:

1) VisualC++ Express edition, if possible the 2010 edition as it's the current one used by PureBasic libraries (fully free, also for commercial application)
2) Unix tools for Windows (UnxUtils) in the PATH, to have the 'make' program. They can be found here: http://unxutils.sourceforge.net/
2.1) Install the update from UnxUtils : http://unxutils.sourceforge.net/UnxUpdates.zip
3) Modify the 'PureLibraries.cmd' file to set the correct environment variables (use a PureBasic path without spaces, or it won't work. Don't put double quotes around paths).
4) Launch 'PureLibraries.cmd' and type 'make' in the directories with a makefile and all should be compiled correctly.
   The resulting purelibrary is automatically copied in your PureBasic\PureLibraries\UserLibraries\ drawer.
5) Open the .c/.h files to see how it works, as they are fully commented
