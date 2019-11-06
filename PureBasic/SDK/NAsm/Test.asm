;
; MessageBox - Test Library File for PureBasic x86 SDK
;
; © 2001 Fantaisie Software
;
;
;
; 26/02/2001
;   First Version
;
;%INCLUDE "win32n.inc"
;
	GLOBAL	PB_MessageBox
		
	EXTERN 	PB_MemoryBase
	EXTERN 	PB_StringBase
	
	EXTERN _MessageBoxA@16

; Some macros to get the code much easier to read
  
%define MessageBox _MessageBoxA@16

; Now the Win32 constants to have a small .obj (very strange this bug)

MB_OK equ 0


 SEGMENT .text USE32 CLASS=CODE
 
;
; The only destroyable registers are 'eax' and 'edx'. All the other must be
; preserved...
;
 
PB_MessageBox:

  PUSH esi          ; save these registers
  PUSH edi          ;
  
  MOV esi, [esp+(4+8)]   ; Get the last args..
  MOV edi, [esp+(8+8)]   ; Get the 3rd arg..
  MOV edx, [esp+(12+8)]  ; Get the 2nd arg..
  
  PUSH  esi
  PUSH  edi
  PUSH  edx
  PUSH  eax
  CALL  MessageBox
  
  POP edi
  POP esi
  RET 12    ; Don't forget to free the stack
  

 SEGMENT .data CLASS=DATA
		
; Buffer:				  dd	0