; *************************************************************************
; 32-bit Windows Hello World Application - MASM32 Example
; EXE File size: 2,560 Bytes
; Created by Visual MASM (http://www.visualmasm.com)
; *************************************************************************
     
.386					; Enable 80386+ instruction set
.model flat, stdcall	; Flat, 32-bit memory model (not used in 64-bit)
option casemap: none	; Case sensitive syntax

; *************************************************************************
; MASM32 proto types for Win32 functions and structures
; *************************************************************************
Flag PROTO

  
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
         
; *************************************************************************
; MASM32 object libraries
; *************************************************************************  
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\kernel32.lib



; *************************************************************************
; Our data section. Here we declare our strings for our message box
; *************************************************************************
.data
      strTitle		db "Bare Bone",0
      strMessage	db "Hello World!",0

; *************************************************************************
; Our executable assembly code starts here in the .code section
; *************************************************************************
.code

start:
Main PROC

	; 2.1. PEB.BeingDebugged Flag: IsDebuggerPresent()
	assume fs:nothing
	mov eax,[fs:30h] ;EAX = TEB.ProcessEnvironmentBlock
	movzx eax,byte ptr [eax+02h] ;AL = PEB.BeingDebugged
	test eax,eax
	jnz debugger_found

	; 2.2. PEB.NtGlobalFlag, Heap Flags
    ;ebx = PEB
    assume fs:nothing
	mov ebx,[fs:30h]
	
	;Check if PEB.NtGlobalFlag != 0
	cmp dword ptr [ebx+68h],0
	jne debugger_found
	
	;Do not work on Windows 10 1909
	;eax = PEB.ProcessHeap
	;mov eax,dword ptr [ebx+18h]
	
	;Check PEB.ProcessHeap.Flags
	;cmp dword ptr [eax+0ch], 0
	;jne debugger_found
	
	;Check PEB.ProcessHeap.ForceFlags
	;cmp dword ptr [eax+10h], 0
	;jne debugger_found

	call Flag

	debugger_found:
 	invoke ExitProcess, 0
Main ENDP


; Flag 
Flag PROC
	; Use the MessageBox API function to display the message box.
	; To read more about MessageBox, move your mouse cursor over the
	; MessageBox text and press F1 to launch the Win32 help  
    invoke MessageBox, 0, ADDR strMessage, ADDR strTitle, MB_OK
    
	; When the message box has been closed, exit the app with exit code 0
    invoke ExitProcess, 0
	ret
Flag ENDP

end start





