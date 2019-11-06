
--------------------------------------------------------------------

           PureBasic DocMaker Help - v3.93
        
           (c) 2005 - Fantaisie Software

--------------------------------------------------------------------

  Introduction
  ------------
  
  If you want to build help files following the PureBasic format (currently
  RTF (Word 97+ compatiable), CHM (Windows), Multiview (Amiga) and plain 
  HTML (Linux)), you should use this tool as it will do all the hard work 
  for you. You have to write a template file with some special tags, which 
  will be converted by the tool to the final format.
  
  
  I. Installing DocMaker
  ----------------------
  
  DocMaker is multi-langage, which means he has to be in a directory containing
  a directory per langage, correctly named:
  
    + DocMakerDirectory
      - DocMaker.exe
      + German
        - All german library files
      + English
        - All english library files
      + French
        - All french library files
    
    Then, it should work as expected, just press on start and it will process
    all the files found in the directory (depending of the selected langage).
    
    The 'User Library' mode allow to create an help file for an third part library, which will be
    at the same format than regular PureBasic help. It will be also recognized when pressing 'F1'
    over the user library command in the IDE, like any build-in command (the .chm has to be put in the
    Help\ directory of the PureBasic folder to have this feature enabled).
  
    - Command line parameters (to allow scripting using Docmaker):
    
      /DOCUMENTATIONPATH: Specify the path of the documentation (as explained above).
      
      /OUTPUTPATH: The output directory.

      /OS: The OS for which the documentation will be compiled. It can be "Windows", "Linux", "AmigaOS".

      /LANGUAGE: the language. The directory corresponding to this langage has to exist in the 'DocumentationPath'.
      
      /FORMAT: The output format in the which the documentation will be generated. It can be: "Html", "RTF", "Linux", "MultiView".

      /CHM: Will create a CHM (only supported on Windows). The /HTMLWORKSHOP parameter has to be specified.

      /HTMLWORKSHOP: The fullpath and filename of the hhc.exe file.
      
      /USERLIBRARY: Enable the User Library mode.
    
  
  II. Windows CHM
  ---------------
  
  CHM precompiled files are perfects as it's compact (compressed) and contains
  the needed tool to do indexing and searching in the help file. Nevertheless
  the creation of such files are long an a bit boring. Don't worry, DocMaker make
  all for you (almost :-). First, get HTML Help Workshop from the microsoft web site
  (free tool). Then launch DocMaker. A 'PureBasic Help.hhp' file will be created. 
  If you have installed HTML Help Workshop correctly, it will be launched when double 
  clicking on the 'PureBasic Help.hhp' file. Then look for the 'compile' button in the 
  toolbar and go, you have compiled you help file, with index and menu !
  
  
  III. PureBasic documentation
  ----------------------------
  
  The whole PureBasic documentation (in 3 langages) is available at http://cvs.purebasic.com
  and can be recompiled without any problem with DocMaker.
  
    
  If have any questions, remarks, suggestions, just write to:
        
            support@purebasic.com
   