
--------------------------------------------------------------------

           PureBasic Library SDK - v5.10
        
           (c) 2013 - Fantaisie Software

--------------------------------------------------------------------

  I. Introduction
  ---------------
  
  PureBasic is a complete programming langage which use third parts 
libraries (called 'PureLibraries' to avoid conflit with systems 
libraries) to ease the programmer life. These libraries can be wrote
in ASM (with NAsm, FAsm etc.) or in C (with VisualC++, etc.).

  You must thought than a library could be used by every program,
so it has to be the most optimized as possible. If a library is
well wrote, every program wrote in PureBasic which use it will
benefit of its compactness and speed.

  Some examples are available in the 'VisualC' subfolder, so be sure to check
them, it's often easier to learn from working examples.

  
  II. ASM versus C
  ----------------
  
  If you don't know how to code in ASM or don't want code your library
in ASM, you can skip this part. A library wrote in full ASM has an advantage
over C one: the first parameter is passed trough a register (eax) instead of
the stack. This means it's a faster, especially in a small function case. Else,
all the rest is similar. Programming ASM allows to do some tricks/optimizations 
which aren't possible in C (ie: full access to FPU, MMX and SSE specific commands,
etc..).


  III. Using VisualC++ to develop PureLibraries
  ---------------------------------------------
  
  First, you have to get a recent version VisualC++ (we use 2010 edition). An Express
Edition is a available at no cost from Microsoft. For more information about using
VisualC for user libraries, check the 'VisualC' example folder.
  

  General notes:
        
  - A PureFunction name declaration begin always by 'PB_' (ex: PB_Right, PB_Left...)
   
   
  IV. Using FAsm
  --------------
   
  It's easier, as FAsm is used by PureBasic, so you could catch it in the \Compilers\ directory.
Try to compile the FAsm\MessageBox.asm file by typing:

   fasm MessageBox.asm MessageBox.obj
    
   General notes:
   
     - Only the registers 'eax', 'edx' and 'ecx' can be destroyed, all other must be preserved.
     - A PureFunction name declaration begin always by 'PB_' (ex: PB_Right, PB_Left...)
     - The first parameter is passed via the 'eax' register all other are on the stack.
     - If Float is used on the first paramater, it's not passed on 'eax' but on 'ST0'
       (first FPU register).
     - Float or Double result must be put on ST0.
     - Quad result has to be put in 'eax' (low word) and 'edx' (high word)
    
   A file called Win32N.inc is supplied with PureBasic (by Tamas Kaproncai [tomcat@szif.hu]) which
contains almost all the needed constants and structures to develop in the Win32 environment.
    
   The full version of FAsm (with the help) can be found to: 
   
      http://fasm.sourceforge.net/
      
    
   V. Building the final PureLibrary
   ---------------------------------
   
   The commands available in a PureLibrary are described in a file, called
   'LibraryName.Desc'. Inside, you can put every commands, which langage you've
   used to code your library, and more. Every line beginning by a semi-column ';'
   is considered as a comment (like in PureBasic).
   
   1. Basic example
      - - - - - - -
   
  ;
  ; Langage used to code the library: ASM or C
  ASM
  ;
  ; Number of windows DLL than the library need
  2
  WINMM
  ODBC32
  ;
  ; Library type (Can be OBJ or LIB). Starting with 2.60, PureBasic can use both .obj (NAsm or LccWin32)
  ; and standard Windows .LIB file, useful to convert quickly a library. This should be mostly .obj
  ; here, instead you're really need to use a .lib.
  ;
  OBJ
  ;
  ; Number of PureBasic library needed by the library. Here we need the Gadget library
  ;
  1
  Gadget
  ; Help directory name. Useful when doing an extension of a library and want to put
  ; the help file in the same directory than the base library. This is not a facultative
  ; result.
  ;
  GadgetSlider
  ;
  ; Library functions:
  ;
  ; FunctionName, Arg1Type, Arg2Type, ... (DescriptionArg1, Arg2) - Description of the command show on the QuickHelp status bar
  ; Return type
  ;
   
   The final sample:
   -----------------
    
   ASM
   0
   OBJ
   0
   Misc
   ;
   ; Misc library descriptor
   ;
   ;
   InitMisc
   InitFunction
   ;
   FreeMiscs
   EndFunction
   ;
   PeekS, Long (Address) - Retrieve a string from the specified address
   String
   ;
   PeekL, Long (Address) - Retrieve a long from the specified address
   Long | DebuggerCheck
   
   
   Possible parameter type: Only one parameter type can be put at once.
   
   * Byte: The parameter will be a byte (1 byte)
   * Word: The parameter will be a word (2 bytes)
   * Long: The parameter will be a long (4 bytes)
   * String: The parameter will be a string (see below for an explaination of string handling)
   * Quad: The parameter will be a quad (8 bytes)
   * Float: The parameter will be a float (4 bytes)
   * Double: The parameter will be a double (8 bytes)
   * Any: The parameter can be anything (the compiler won't check the type)
   * Array: The parameter will be an array. It will have to be passed like: array()
   * LinkedList: The parameter will be an linkedlist. It will have to be passed like: list()
   
   
   Possible return flags: The flags can be combined with the '|' operand.
   
   * DebuggerCheck: The command need a PB_CommandName_DEBUG() routine, which will be called before the call
     of the real command (when the debugger is on), useful to check if the parameters are corrects. This function
     should be put in a different file, to not be linked with the final executable. You should put all the debug
     functions in the same file, to ease the management. This function has to be declared CDECL.
     
   * Byte: The return is a byte (1 byte) 
   * Long: The return is a long (4 bytes)
   * Float: The return is a long (4 bytes)
   * Double: The return is a double (8 bytes) 
   * Quad: The return is a quad (8 bytes)
   * String: The return is a string (see below for an explaination of string handling)
   * None: This function doesn't return anything

   * InitFunction: The function is an 'InitFunction' which will be called automatically when
     the program starts. This function won't appear in the available user command list. This function
     can not have any parameters. A debug function can be attached this function, if debugger specific
     code should be initialized once.
     
   * EndFunction: The function is an 'EndFunction' which will be called automatically when
     the program ends. It's very useful to clean up all the resource allocated by the library commands
     
   * StdCall: The function is truly stdcall. It's only useful for ASM library, to force the first parameter to
     pushed on the stack (instead of 'eax').
     
   * MMX: Informs the compiler than this function has an MMX specific version (see below)
   * SSE: Informs the compiler than this function has an SSE specific version (see below)
   * SSE2: Informs the compiler than this function has an SSE2 specific version (see below)
   * 3DNOW: Informs the compiler than this function has an 3DNOW specific version (see below)
   
   * CDecl: The function call will be CDecl, which means than it's the compiler which will readjust the
     stack.
     
   * Virtual: The function is not a real function, but a function pointer. The compiler will make an indirect call
     by using the PB_Command label as a function pointer. Can be useful to have a same function doing different
     operation depending of the context.
     
   * Thread: Informs the compiler than this function has a THREAD specific version. If the function needs to be
     tuned to be threadsafe, and the performance/size impact will be important, it's advised to use this flag
     and create a function which will be used only when the executable will be thread safe (ie: compiled with the
     /THREAD flag). The command should be named PB_CommandName_THREAD()
     
   * Unicode: Informs the compiler than this function has an UNICODE specific version. If the function returns
     a string or has some string parameter, it's strongly recommanded to use this flag and add the unicode version
     so the command can be used in unicode program as well (else it will work in ascii only).
     The command should be named PB_CommandName_UNICODE(). Note: if your command also has the 'Thread' flag, you
     need to do another command name PB_CommandName_THREAD_UNICODE() which will be used if the program is compiled
     with the /THREAD and /UNICODE flag.
     
   * Assembly: Tells than this function is written in assembly (so the first parameter is on eax, and the name 
     decoration doesn't have @NbParams*4). This allow to mix assembly and C command in the same library.
     
 
   
   
   2. Examples of variable parameters
      - - - - - - - - - - - - - - - -
   
   2.1 One, two or tree parameters
   
     CustomBox, String, [Long], [Long], (Title$ [, Flags [, Hidden]]) - My Custom box
     Long
     
     Now, you have to create 3 PB functions, named like this:
     PB_CustomBox (char *String)
     PB_CustomBox2(char *String, Long)
     PB_CustomBox3(char *String, Long, Long)
   
   2.2 One or tree parameters
   
     CustomBox, String, [Long, Long], (Title$ [, Flags , Hidden]) - My Custom box
     Long
     
     Now, you have to create 2 PB functions, named like this:
     PB_CustomBox (char *String)
     PB_CustomBox2(char *String, Long, Long)
     
   
   3. Advanced flags
      - - - - - - - 
      
      * Starting with PureBasic 3.50 it's possible to force an asm procedure to be stdcall
        (ie: last argument pushed on the stack, instead in 'eax'), by using the 'StdCall'
        keyword in the return field. This is very handy, especially for DLL wrapper.
        
        Example:
      
          MyDLLWrapper, Long, Long, () - My DLL wrapper
          Long | StdCall
          
      * It's possible to put an 'ANY' flags, instead of Long, Float, etc.. arguments type. This
        mean that's the last type which is used, without convertion. For example, you can do
        a function which sometimes need float, sometimes long, depending of the flags. It is
        especially used with the CallFunction() and CallFunctionFast() command.
        
        Example:
        
          MySpecialFunction, Long, Any, (Flags, Float or Long or String)
          Long
      
   
   Once this file is finished, you have to mix the .obj with the .desc to produce a
 real PureLibrary. To do this, copy the .Desc and the .obj in the same directory and
 run the LibraryMaker tool. Select this path as 'Source Object Path' and a destination
 path. If errors are found, they will be signaled. 
 
   4. Conditional directives
      - - - - - - - - - - - -
      
      As PureBasic is a crossplatform programming langage it sometimes useful to uses the same
      .desc file for several OS. In this case, it could have some minor changes to do to the .desc
      to fit the system rules. To do it, it's possible to use CompilerIf/CompilerElse/CompilerEndIf
      directory, like in PureBasic. The /CONSTANT command line flag will be used to declare the constants.
      It's possible to use several constants and to nest the statements.
      
      Example:
      
      ; Custom library
      ;
      CompilerIf WINDOWS
        ; Do all the Windows related stuff here
      CompilerElse
        CompilerIf LINUX
          ; Do the stuff for linux
        CompilerElse
          ; Default case
        CompilerEndIf
      CompilerEndIf

 
 
   V. MMX, 3DNow, SSE and SSE2 
   ---------------------------
   
   Since PureBasic 3.60, it's possible to creates specialized executables (or dynamic executables)
 which can use optimized commands for MMX, 3DNOW, SSE and SSE2 processor. It's done at compile time
 or at runtime, depending of the executable type (Normal or Dynamic CPU). Implements an optimized
 function is very easy, just put _EXTENSION below the name.
 
   Example (in C) to support MMX and 3DNOW format:
   
    PB_CrossFading       (int Rate)  // Base function, working on all processors
    PB_CrossFading_MMX   (int Rate)  // MMX optimized
    PB_CrossFading_3DNOW (int Rate)  // 3DNOW optimized
   
   Now, you have to add in the .desc which optimized functions are available. The following
   flags are available: MMX, 3DNOW, SSE and SSE2
   
   Example for a MMX and 3DNOW optimized function:
   
    CrossFading, Long, (Rate)  
    Long | MMX | 3DNOW
   
   The PureBasic compiler is smart enough to use the base function if no optimized functions are
 availables for the specified CPU. In dynamic mode, all the functions are included in the final
 executable and choose the right one when the program start depending of the
 CPU on which the executable is run. It makes of course the executable bigger but in cases where
 speed is critical, size doesn't matter.
 
   VI. Managing strings
   --------------------
   
   Note: Some examples are available in the 'VisualC' subfolder, so be sure to check them, it's often easier 
   to learn from working examples.
   
   Managing strings in PureBasic 4.0 and above isn't obvious anymore. If a function use strings but doesn't
   returns string, there is not problem at all. Now when it returns string, there is different case:
   
   1) The function doesn't has string parameter
   
   It's the easiest one, and you can use the SYS_GetOutputBuffer() funtion:.
   
   char *Output = SYS_GetOutputBuffer(int Length, int PreviousPosition)
   
   With this command you ask PureBasic to returns a string buffer of 'Length' (in characters, which means
   than it's the same value in unicode or not) and store the pointer value in 'Output'. 'PreviousPosition' is a 
   value passed in the string function.
   
   ex: Output = SYS_GetOutputBuffer(100, PreviousPosition);
   
   Once you get this buffer, just write the string result in it and you're done.
   
   Note: 'Length' should be the exact returned string length. It doesn't count the null terminating character
   

   2) If the function has some string parameters
   
   You still have to use the above functions, but before you may need to to call SYS_GetParameterIndex() and SYS_ResolveParameter()
   if you need to use the string parameters after having called SYS_GetOutputBuffer(). Why that ? Because if one of your
   parameter is a composed string (like a$+b$), it will reside on the internal buffer. When you request some length (let's say
   a big length), it can be reallocated, which means than your string pointers won't be correct anymore. SYS_GetParameterIndex() will
   get the index in the buffer, if the string is in the buffer (or return 0 else). SYS_ResolveParameter() will rebuild the
   string pointer once SYS_GetOutputBuffer() will be called.
   
   A typical C code will look like that:
      
      M_PBFUNCTION void PB_LSet(const TCHAR *String, int Length, int PreviousPosition)
      {
        [...]
        
        ParameterIndex  = SYS_GetParameterIndex(String);
      
        Cursor = SYS_GetOutputBuffer(StringLength, PreviousPosition);
      
        if (ParameterIndex)
      	  String = SYS_ResolveParameter(ParameterIndex);
        
        [...]
      }

   Now, sometimes you can't know the size of the result string (or it will be too long to compute it. In this can, you
   can request a fixed size and adjust it at the end with the SYS_ReduceStringSize(Length) function. 'Length' is the
   number of byte to reduce the buffer. If you have requested a buffer of 4096 with SYS_GetOutputBuffer() and your
   string do only 4000 bytes, you will have to reduce it from 96 bytes ie: SYS_ReduceStringSize(96). 
     
   
   VII. Splitted library format 
   ---------------------------
   
   Since v3.00, PureBasic uses a new type of library: the splitted library. Each commands should be
 done in its own file, using the C or ASM 'extern' keyword to access shared variables. The good
 point is than only the needed functions are linked to the final executable, which produces much
 smaller code, in case of only a few commands are used. Once you have all your .obj in the same
 directory, you have to change the .DESC 'type' header from OBJ to LIB. That's the only change
 needed for this file. Then, you have to create the .lib, based on the .obj files. To do that,
 a little tool is provided. Usage:
 
     polib.exe /OUT:MyKillerLib.lib killer.obj reboot.obj
     
   A library file will be created, containing all your obj files. Just lauch the LibraryMaker
 tool, as usual...
 
 
    VIII. Command line option
    -------------------------
    
  LibraryMaker can take several arguments in parameter to allow easy scripting:
    
    /ALL                : Process all the .desc files found in the source directory
    /COMPRESSED         : Compress the library (much smaller and faster to load, but slower to build)
    /TO <Directory>     : Destination directory
    /CONSTANT MyConstant: Defines a constant for the preprocessor
  
  The source directory must be the first arument.
  
  Example:
  
    C:\LibraryMaker.exe c:\PureBasicDesc\ /TO C:\PureBasic\PureLibraries\ /ALL /COMPRESSED
    
    It will convert all the .desc found in the 'c:\PureBasicDesc\' directory and with compression
    
      
        If you have any questions, remarks, suggestions, just write to:
        
            support@purebasic.com
   