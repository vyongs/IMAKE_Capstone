
--------------------------------------------------------------------

              PureBasic DLL Importer - v3.60
        
              (c) 2003 - Fantaisie Software

--------------------------------------------------------------------

  Introduction
  ------------
  
  PureBasic allows to uses external DLL as it was standard commands, with an
  trailing underscore (ie: SendMessage_(), CreateWindowEx_()...). Almost
  all the Win32 API is natively supported by PureBasic, and with this 
  tool, it's now possible to add your own dll or update the actual one.

  I. Building a DLL Definition file
  ---------------------------------
  
    The DLL Definition file is a list of all the DLL functions you want to support
    in PureBasic. It's plain ASCII and use a very easy format:
    
    DLLNAME.DLL
    Function1 NbParameters
    Function2 NbParameters
    Function3 NbParameters
    ...
    
    Comments are accepted, using the ';' character.
    
    Example (which works with the DLLSample.pb example):
    
    ; PureBasic DLL import file
    ;
    PUREBASIC.DLL
    EasyRequester 1
  
    Once the file is finished, just save it with the .pbl (PureBasic Library) extension.
    
  
  II. Using DLL Importer with the GUI
  -----------------------------------
  
    1) Selects the 'PureLibraries' directory. It's located in the PureBasic
       drawer and should contains a 'Windows' directory, inside
       which it should have a Bin\BuildLib.exe tool. This tool is needed
       to make the DLL, and it's used internally by the DLL Importer. You don't
       need to use it.
       
    2) Select the 'PureDLL' drawer. Just create a new drawer and choose it. A drawer
       called 'Exports' will be created automatically if none are found.
       
    Note: When the program quits, these settings are automatically saved.
       
    3) Now, you can select the .pbl file by clicking on 'Start'. If you have lots
       of files to import, you can check the 'Process whole directory' checkbox and the
       all the .pbl files found in the 'PureDLL' drawer will be imported.
    
  
 
  
  If have any questions, remarks, suggestions, just write to:
        
            support@purebasic.com
   