;
;  ComboBox assembly example for gadget interface
;
;   (c) 2002 Fantaisie Software
;


%macro APIDeclareA 2
  EXTERN _%1A@%2
  %define %1 _%1A@%2
%endmacro

%macro APIDeclare 2
  EXTERN _%1@%2
  %define %1 _%1@%2
%endmacro

%macro PBFunction 1
  GLOBAL PB_%1
PB_%1:
%endmacro


  EXTERN  PB_MemoryBase
	EXTERN _PB_Instance
	EXTERN 	PB_StringBase
		
	EXTERN _PB_Gadget_ObjectsArea
	EXTERN _PB_Gadget_CreateGadget
	EXTERN _PB_Gadget_CurrentObject
	EXTERN _PB_Gadget_DefaultFont
	EXTERN  PB_Gadget_CheckReAllocate
	
  APIDeclareA SendMessage,16
  APIDeclareA CreateWindowEx,48

STRUC VT
  .FreeGadget RESD 1
  .GetGadgetState RESD 1
  .SetGadgetState RESD 1
  .GetGadgetText RESD 1
  .SetGadgetText RESD 1
  .AddGadgetItem RESD 1
  .AddGadgetItem2 RESD 1
  .RemoveGadgetItem RESD 1
  .ClearGadgetItemList RESD 1
  .ResizeGadget RESD 1
  .CountGadgetItems RESD 1
  .GetGadgetItemState RESD 1
  .SetGadgetItemState RESD 1
  .GetGadgetItemText RESD 1
  .SetGadgetItemText RESD 1
ENDSTRUC

CB_ADDSTRING equ 143h
CB_GETCURSEL equ 147h
CB_RESETCONTENT equ 14Bh
CB_INSERTSTRING equ 14Ah
CB_DELETESTRING equ 144h
CB_SETCURSEL equ 14Eh
CB_GETCOUNT equ 146h
CB_GETLBTEXT equ 148h
CB_SELECTSTRING equ 14Dh

CBS_SIMPLE equ 1h
CBS_DROPDOWN equ 2h
CBS_DROPDOWNLIST equ 3h
CBS_HASSTRINGS equ 200h

WS_CHILD equ 40000000h
WS_VISIBLE equ 10000000h
WS_TABSTOP equ 10000h
WS_BORDER equ 800000h
WS_VSCROLL equ 200000h
WS_HSCROLL equ 100000h
WS_CLIPSIBLINGS equ 4000000h
WS_GROUP equ 20000h

WS_EX_CLIENTEDGE equ 00000200h
WS_EX_WINDOWEDGE equ 00000100h
WS_EX_STATICEDGE equ 00020000h
WS_EX_TRANSPARENT equ 20h

WM_SETFONT equ 30h

SEGMENT .text USE32 CLASS=CODE


PBFunction ComboBoxGadgetTest
	POP	 	ecx
	POP		dword [arg1]
	POP		dword [arg2]
	POP		dword [arg3]
	POP		dword [arg4]
	MOV   dword [arg5],0 ; Name
	PUSH 	ecx
	MOV		ecx,WS_CHILD | WS_VISIBLE | WS_BORDER | CBS_HASSTRINGS | WS_GROUP | WS_VSCROLL | WS_TABSTOP | CBS_DROPDOWNLIST
	MOV		edx,WS_EX_CLIENTEDGE
PB_ComboBoxGadgetReal:
	MOV   dword [ComboBoxVT+VT.GetGadgetState], ComboBox_GetGadgetState
	MOV   dword [ComboBoxVT+VT.SetGadgetState], ComboBox_SetGadgetState
	MOV   dword [ComboBoxVT+VT.AddGadgetItem] , ComboBox_AddGadgetItem
  MOV   dword [ComboBoxVT+VT.GetGadgetText] , ComboBox_GetGadgetText
	MOV   dword [ComboBoxVT+VT.SetGadgetText] , ComboBox_SetGadgetText
	MOV   dword [ComboBoxVT+VT.ClearGadgetItemList], ComboBox_ClearGadgetItemList
	MOV   dword [ComboBoxVT+VT.CountGadgetItems], ComboBox_CountGadgetItems
	MOV   dword [ComboBoxVT+VT.RemoveGadgetItem], ComboBox_RemoveGadgetItem
	CALL  PB_Gadget_CheckReAllocate
	MOV	 	[ActualNumber],eax
	PUSH 	dword 0
	PUSH 	dword [_PB_Instance]
	PUSH 	eax  				        ; Our ID (was Menu...)
	PUSH 	dword [_PB_Gadget_CurrentObject]  ; ParentWindow
	PUSH 	dword [arg4]				; Height
	PUSH 	dword [arg3] 				; Width
	PUSH 	dword [arg2] 				; y
	PUSH 	dword [arg1] 				; x
	PUSH 	ecx
	PUSH 	dword [arg5]		    ; Name
	PUSH 	dword ComboBoxClass ; Template class..
	PUSH 	edx
	CALL 	CreateWindowEx
	MOV		ecx,eax
	PUSH  eax                 ; Save eax for future use
	MOV		eax,[ActualNumber]
	MOV 	edx,[_PB_Gadget_ObjectsArea]   ; Point on the right entry in the memory bank to store our new gadget infos
	SHL 	eax,4               ; eax*16
	ADD   edx,eax             ;
	MOV		[edx],ecx
	MOV		dword [edx+4], ComboBoxVT	; Store the gadget associated class for fast GetGadgetState()
	PUSH	dword 1					          ; Set the default Windows font for the gadgets...
	PUSH	dword [_PB_Gadget_DefaultFont]
	PUSH	dword WM_SETFONT			    ;
	PUSH	ecx					              ;
	CALL	SendMessage			          ;
	POP   eax                       ; Return the Gadget address in 'eax'
	RET
	

PBFunction ComboBoxGadgetTest2
	POP	 	ecx
	POP		dword [arg1]
	POP		dword [arg2]
	POP		dword [arg3]
	POP		dword [arg4]
	MOV   dword [arg5],0 ; Name
	POP   dword [Flags]
	PUSH 	ecx
	MOV   ecx, [Flags]
	AND   ecx, CBS_DROPDOWN
	JZ    CBG_NotEditable
	MOV   ecx, [Flags]
  JMP   CBG_Next
CBG_NotEditable:
  MOV   ecx, [Flags]
  OR    ecx, CBS_DROPDOWNLIST
CBG_Next:  
	OR 		ecx, WS_CHILD | WS_VISIBLE | WS_BORDER| CBS_HASSTRINGS | WS_GROUP | WS_VSCROLL | WS_TABSTOP
	MOV		edx, WS_EX_CLIENTEDGE
  JMP   PB_ComboBoxGadgetReal
	

; (#Gadget, Position, String$)
;
ComboBox_AddGadgetItem:
  PUSH	dword [esp+12]		; String to add (Position on the stack)
	PUSH	dword [esp+12]		; Position
	PUSH	dword CB_INSERTSTRING		
	PUSH	dword [esp+16]    ; Gadget
	CALL	SendMessage
  RET   12


; (#Gadget)
;
ComboBox_ClearGadgetItemList:
  PUSH	dword 0			
	PUSH	dword 0
	PUSH	dword CB_RESETCONTENT
	PUSH	dword [esp+16]
	CALL	SendMessage
  RET   4


; (#Gadget)
;
ComboBox_CountGadgetItems:
  PUSH	dword 0
	PUSH	dword 0		
	PUSH	dword CB_GETCOUNT
	PUSH	dword [esp+16]    ; Gadget
	CALL	SendMessage
	RET   4
 

; (#Gadget)
;
ComboBox_GetGadgetState:
	PUSH	dword 0			 							; 
	PUSH	dword 0			 							;
	PUSH	dword CB_GETCURSEL				; 
	PUSH	dword [esp+16] 						; The gadget address...
	CALL	SendMessage								; Result in eax is the gadget result state
	RET   4
	

; (#Gadget)
;
ComboBox_GetGadgetText:
	PUSH	dword 0
	PUSH	dword 0
	PUSH	dword CB_GETCURSEL
	PUSH	dword [esp+16]
	CALL	SendMessage				; Get the current select indes in 'eax'
	CMP		eax,-1
	JE		ComboBox_GGT_End
	PUSH	dword [PB_StringBase]
	PUSH	eax
	PUSH	dword CB_GETLBTEXT	; CB_GETTEXT or LB_GETTEXT, depending of the gadget type
	PUSH	dword [esp+16]
	CALL	SendMessage
	CMP		eax,-1
	JE		ComboBox_GGT_End
	ADD		dword [PB_StringBase], eax
ComboBox_GGT_End:
  MOV   eax, [PB_StringBase]
  MOV   byte [eax], 0
	RET   4
	

; (#Gadget, Position)
;
ComboBox_RemoveGadgetItem:
  PUSH	dword 0
	PUSH	dword [esp+12]	  				;
	PUSH	dword CB_DELETESTRING     ;
	PUSH	dword [esp+16]						; The gadget address...
	CALL	SendMessage								; 
	RET   8


; (#Gadget, State)
;
ComboBox_SetGadgetState:
  PUSH	dword 0
	PUSH	dword [esp+12]	  				;
	PUSH	dword CB_SETCURSEL        ;
	PUSH	dword [esp+16]						; The gadget address...
	CALL	SendMessage								; Result in eax is 1 if the checkbox is pressed !
	RET   8


; (#Gadget, String$)
;  
ComboBox_SetGadgetText:
  PUSH	dword [esp+8]	    				;
  PUSH	dword 0
	PUSH	dword CB_SELECTSTRING     ;
	PUSH	dword [esp+16]						; The gadget address...
	CALL	SendMessage								; 
	RET   8
	
	
SEGMENT .data CLASS=DATA

ComboBoxClass: db "COMBOBOX",0

SEGMENT .bss CLASS=DATA

Flags:            RESD 1
arg1:				      RESD 1
arg2:				      RESD 1
arg3:				      RESD 1
arg4:				      RESD 1
arg5:				      RESD 1
arg6:				      RESD 1
ActualNumber      RESD 1

; VirtualTable for Combobox
;
ComboBoxVT:     RESD 15