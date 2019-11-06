
  ------------------------------------------------------------------
 
              PureUnit -- Automated testing in PureBasic
           
                     (c) 2008 - Fantaisie Software

  ------------------------------------------------------------------




  I. Introduction
  ---------------

  PureUnit allows automated unit testing for PureBasic code with similar
concepts to other xUnit frameworks like JUnit. The basic idea of unit
testing is the creation of a set of tests that can run without user 
interaction so they can be repeated many times during the development
process to ensure that the code still does what it is supposed to do.

  The main reason for the creation of PureUnit was the testing of 
(user-)libraries for PureBasic, but it can be used to test code written 
in PureBasic itself just as well. Caused by the fact that the goal is 
testing without user interaction, PureUnit is not intended for testing 
entire application or a finished program, but rater for testing the parts
of a program like individual functions which can be executed separately 
from the rest of the program to verify their correctness. (for example 
an includefile with commonly used functions etc). 

  PureUnit consists of a set of keywords (in the form of macros) to write
the actual test code and a tool which will analyze the code to extract 
information, compile and run the test code and report the status back to the
user. The tool comes with a commandline interface for use in makefiles or scrips
and a user interface for convenient testing directly from the PureBasic IDE
for example.


  NOTE: The Windows version comes as 2 separate executables for console/gui use.
The reason for this is that a console application on Windows will always open
a console window, even when started from the explorer which is annoying when using
it as a gui tool. Therefore these two files contain the exact same program, just
once compiled in console mode and once in gui mode. In a similar way, the  Mac OSX 
version comes as "PureUnit.app" (for gui use) and "pureunit" for console use.



  II. Installation
  ----------------


- The 'PureUnit.res' needs to be copied the 'Residents' Directory of your PureBasic 
  installation.

- Optionally, the 'PureUnitKeywords.txt' file can be selected in the preferences of the
  PureBasic IDE (Preferences->Colors->Custom Keywords) as a keyword file to color
  all PureUnit specific keywords in a separate color.

- The PureUnit executables can be executed from anywhere.

- Note: PureUnit requires a minimum compiler version of 4.10 due to the use of the
  compiler interface that was introduces with this version.





  III. Writing the testcode
  -------------------------


  All test code must be written inside procedures. Code outside of the test procedures
will not be executed. So just like in a dll there should only be stuff like constant
definitions, structures etc on the main level. (Note though that PureUnit does not
compile the code to a dll for the tests. The code is compiled to an executable with
extra embedded code to execute the tests.)
  
  Test procedures are created just like normal procedures but with one of the below
described keywords instead of 'Procedure'. Test procedures MUST have no arguments. 
They should have descriptive names (representing what they actually test for), as the
names are reported in case of a failure. 

  A test is considered to be passed if the procedure ends normally (or is left with
ProcedureReturn). A test is considered to be failed if the below described Assert() 
macro fails, the Fail() macro is called, or a runtime error (OnError library) happened.




  PureUnit adds the following new keywords (as macros without arguments):


ProcedureUnit

- A procedure created with this keyword is considered to be a test procedure. 

  The test procedures in a given code will be executed in RANDOM order. The reason for
  this is to find problems from possible sideeffects of the tests which would go unnoticed
  if the tests always get executed in the same order. (for example if some test always 
  succeeds just because the test before it sets certain conditions that were not
  realized when the test code got written)


ProcedureUnitStartup

- All procedures created with this keyword will be executed at the startup of the 
  compiled program. (there can be more than one startup procedure). Use this to
  set up global conditions (variables etc) for all tests.

ProcedureUnitShutdown

- All procedures with this keyword will be executed at the end of all tests.
  Note that they will also be executed when the program ends because of a failed test.
  Use this to do any cleanup after the tests.

ProcedureUnitBefore

- All procedures with this keyword will be executed before every single test.
  Use this to do preparations that should be done before every test separately.

ProcedureUnitAfter

- All procedures with this keyword will be executed after every single test.
  (also after a failed test.)

EndProcedureUnit

- This keyword has no special meaning to PureUnit. It is just defined as a macro
  for 'EndProcedure' to have a matching end keyword. (ProcedureUnit / EndProcedureUnit)
  Using this or 'EndProcedure' makes no difference at all. It is just there for
  esthetic reasons.




    PureUnit adds the following new macros with arguments:



Assert( <expression> [, Message$] )

- This is the central macro of the testing concept. It is used to check all conditions
  that must be true for the test to succeed. If any of the conditions is found to 
  be false, the entire test is considered to be failed.

  <expression> can be any expression that evaluates to true (nonzero) or false (zero).
  Since the macro evaluates the expression with an 'If' statement, the logical operators
  And, Or, XOr and Not can be used.

  Message$ is an optional argument that can contain a message that is shown (in the
  test protocol or on the console) if the Assert failed.

  Example:
  Assert(MyVariable = 123 And aFunction() = 0)


AssertString( String1$, String2$ [, Message$] )

- This is a special macro that is intended to test results from string functions
  inside (user-)libraries. For any other purpose, "Assert(String1$ = String2$)" will
  work just fine.

  Detailed information:
  If a string function inside a library does not correctly allocate the internal string
  buffer (ie allocating more characters than are actually filled), the result will look
  just fine if seen as a single value. It will however become wrong if the string
  function result is added together with other strings. (because there will be a NULL
  character inside the string then.)

  To test for exactly this situation in a convenient way, this macro actually maps to this:

    Assert(Chr(1)+String1$+Chr(1) = Chr(1)+String2$+Chr(1))

  Since this situation cannot happen with PB code directly, there is no need to use this
  macro to test string equality in normal PB code.

  
Fail( [Message$] )

- If this macro is executed, the test will be seen as failed and the specified optional
  message is reported. It is used to indicate failure if the test code reaches
  a position that it is not supposed to reach.


UnitDebug( String$ )

- As the tests are executed without debugger (because the debugger is an interactive tool), there is
  no quick and dirty way like "Debug ..." to print information. This command will show the specified string
  in the gui in a different color and also list this output in the html report.

  This command should not be used to do extensive output like test results or similar (remember that the goal
  is unattended automatic testing). This is rather meant as a quick way to get some output when tracking
  a problem in the test code etc.


PureUnitOptions( Option1 [, Option2 [, ...]])

- This macro controls the compilation of the sourcecode for testing. It is the only one that should
  only appear once in every testcode. This macro is not present or specifies no flags, the code will
  be compiled/tested once normally and once in unicode mode. The following flags are possible:

  NoUnicode         - no unicode tests
  Thread            - test also in thread mode
  SubSystem[<name>] - test also with the given subsystem

  The code will be compiled in all possible combinations of the given flags (on/off), so when using
  "PureUnitOptions(Thread)", the code will be compiled once normally, once in unicode mode, once in thread
  mode, and once in thread+unicode mode. So every added option (except the NoUnicode one) actually doubles 
  the amount of times the given test source is compiled/executed. This can be a speed concern when
  doing many tests, so only the needed options should be enabled here.
  



  Handling of included files:


  PureUnit needs to parse the sourcecode in order to know about the used testprocedures etc. The parser
does not do a full analysis of the code, so there are some limits to what it can handle, especially when
it comes to includefiles. The parser does handle correctly IncludePath and (X)IncludeFile statements, but
only as long as the paths are given as literal strings. The parser does NOT resolve constants or macros and
also it does not take care of compiler directives like CompilerIf. So IncludePath and (X)IncludeFile can be
used in test code (to include common startup code for example), even in nested files, but they may only
contain literal strings.


  Example code:


  Note that everything in the example is optional, except that one 'ProcedureUnit' must be present as else
  the file is skipped (which makes sense as there are no tests then).


  ; Set the options. This Code will be compiled/tested once normally and once with the OpenGl subsystem:
  ; 
  PureUnitOptions(NoUnicode, SubSystem[OpenGl])

  ; called once on program start
  ;
  ProcedureUnitStartup startup()
    UnitDebug("Startup...")
  EndProcedureUnit

  ; called once on program end
  ;
  ProcedureUnitShutdown shutdown()
    UnitDebug("Shutdown...")
  EndProcedureUnit

  ; Same goes for ProcedureUnitBefore / ProcedureUnitAfter

  ; Here comes our test procedure
  ;
  ProcedureUnit mytest()

    Assert(#True <> #False, "If this fails, the world has gone crazy :)")

    For i = 1 To 10
      Continue
      Fail("This point should never be reaced")
    Next i

    ; here our test will fail.
    Assert(#True = #False, "This is bound to fail!") 

  EndProcedureUnit



  Note that all PureUnit macros have a fallback to Messagerequester/Debugger display if the code is
not executed from within PureUnit. This allows any PureUnit testcode to be executed from the Editor
or compiler without PureUnit for quick syntax checks or debugging while creating the testcode.





  IV. Commandline arguments
  -------------------------



  PureUnit supports the POSIX style short and long versions of the below commandline arguments 
on all OS (though not the combining of short versions, eg "-x -y -z" does not equal "-xyz"). The
Windows style commandline parameters (ie "/HELP") are only supported in the windows version though.
For portable testing, the POSIX style arguments should be prefered.

  On exit, PureUnit returns a standard exitcode to indicate success (0) or failure (1) of the tests 
to allow running test from scripts or makefiles. When executed without any commandline options, 
PureUnit will enter GUI mode and display a window which allows the selections of files/folders 
for testing. 


Usage:
  pureunit [Options] TestFiles

  Wildcards are allowed to specify multiple TestFiles for testing easily.


Options:


-c         <compiler>
--compiler <compiler>
/COMPILER  <compiler>

  This Option allows to specify the PureBasic compiler to use for compilation.
  If this option is not specified, PureUnit will try to locate a compiler to use
  in the following places in the given order:

  - the PUREBASIC_HOME environment variable
  - the PATH environment variable
  - the Registry                          (Windows only)
  - the fixed path "/usr/share/purebasic" (Linux and OSX only)

  NOTE: The compiler must have a version of 4.10 or higher to work with PureUnit.


-f      <listfile>
--files <listfile>
/FILES  <listfile>

  Specify a file that contains a list of sourcfiles for testing. The file should contain
  one entry per line. Wildcards are allowed.


-g
--gui
/GUI
  
  With this switch present, PureUnit will not output anything on the console, but rather
  display a window to show the progress and information messages. without this switch,
  messages are printed on the console only.
  This switch is useful to configure PureUnit as a tool for the PureBasic IDE for example.


-v
--verbose
/VERBOSE

  Increases the verbosity of the output. 
  (for example prints the currently running test and similar information instead of just 
  error messages as it is in normal mode.)

  This affects the console mode only.


-q
--quiet
/QUIET

  Hides all warning messages. 
  (Warning messages appear when the parser skips a file and similar minor issues)

  This affects both console and gui mode.


-i
--ignore
/IGNORE

  With this switch set, the testing does not stop with a failed test but continues
  until all tests have been executed.

  The normal behavior is to quit testing at the first failed test, as a failed
  test is considered a fatal thing. This switch allows to change this however and
  get an overview of how many test actually do fail in a test code.

  Note: 
    If a test fails, PureUnit will call the '...After' and '...Shutdown' procedures
    and then terminate the testing executable no matter if this switch is set or not.

    If this switch is set, PureUnit will restart the executable. Call the '...Startup'
    Procedures again and then keep executing the remaining tests in the executable.
    The reason for this is to provide a clean state of the program for the remaining
    tests, as the failed test could have messed up the state of the program.
    (for example if the failure was a stack problem/memory error reported by the 
    OnError library, the remaining tests could fail as well, just because of this stack 
    problem)
    

-r       <html file>
--report <html file>
/REPORT  <html file>

  This switch creates a test report in html format in the given file.

  Note that in gui mode, there is also an option to view/save this report
  after the tests have been done.


-v
--version
/VERSION

  Displays version information and quits.


-h
--help
/HELP
/?

  Displays commandline arguments and quits.






  V. Using the graphic user interface
  -----------------------------------




  Starting PureUnit without any commandline options will launch it in gui mode.
The settings entered there will be saved in 'PureUnit.prefs' in the standard location
for PureBasic preference files.


  The gui provides the following options:


Compiler Executable

  Select the compiler to use. Must be of version 4.10 or above.

Source Directory

  Select the base directory in which to look for files to test.

Source Pattern

  Select the pattern to search for when processing a whole directory.

Process the whole directory

  With this switch set, all files in 'Source Directory' matching 'Source Pattern' will be tested.
  Without this switch, you will be promted to select a file for testing when 'Start' is pressed.

Include subdirectories

  Recursively scans subdirectories for files to be tested.

Do not abort on errors

  Same as the "--ignore" commandline switch. See there for more information

Hide warnings

  Hides warning messages. Same as the "--quiet" commandline switch.


  After pressing 'Start' (and selecting a test file if needed), a progress window will be
displayed showing log and debug messages while the tests are executed. After finishing
or aborting the tests, a report in html format can be viewed or saved.


  Starting PureUnit with options on the commandline including the "--gui" switch will cause PureUnit
to directly show the progress window and start the testing with the provided commandline options.




