; *************************************************************************
; 32-bit Windows Hello World Application - MASM32 Example
; EXE File size: 2,560 Bytes
; Created by Visual MASM (http://www.visualmasm.com)
; *************************************************************************
     
;.386					; Enable 80386+ instruction set
.586                    ; For rdtsc instruction
.mmx
.model flat, stdcall	; Flat, 32-bit memory model (not used in 64-bit)
option casemap: none	; Case sensitive syntax

; *************************************************************************
; MASM32 proto types for Win32 functions and structures
; *************************************************************************
Flag PROTO
CheckDebugPort PROTO
DebuggerInterrupts PROTO
TimingChecks PROTO

  
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

      szNtQueryInformationProcess db "NtQueryInformationProcess",0
      szNtDll db "ntdll.dll",0
      szCsrGetProcessId db "CsrGetProcessId"
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
	jnz lb_debugger_found

	; 2.2. PEB.NtGlobalFlag, Heap Flags
    ;ebx = PEB
    assume fs:nothing
	mov ebx,[fs:30h]
	
	;Check if PEB.NtGlobalFlag != 0
	cmp dword ptr [ebx+68h],0
	jne lb_debugger_found
	
	;eax = PEB.ProcessHeap
	mov eax,[ebx+18h]
	
	;Check PEB.ProcessHeap.Flags
	cmp dword ptr [eax+0ch],2
	jne lb_debugger_found
	
	;Check PEB.ProcessHeap.ForceFlags
	;do not work on windows 10 1909
	;cmp dword ptr [eax+010h],0
	;jne lb_debugger_found

    ;2.3. DebugPort: CheckRemoteDebuggerPresent() / 
	;NtQueryInformationProcess()
	call CheckDebugPort
	test eax,eax
	jnz lb_debugger_found

	;2.4. Debugger Interrupts
	;Do not work with x64dbg, it only works with ollydbg
	call DebuggerInterrupts
	test eax,eax
	jnz lb_debugger_found

    ;2.5. Timing Checks
	call TimingChecks
	test eax,eax
	jnz lb_debugger_found

	;2.6. SeDebugPrivilege
	;Do not work with x63dbg set privilege as administrator
	call SeDebugPrivilege
	test eax,eax
	jnz lb_debugger_found



	call Flag

	lb_debugger_found:
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

CheckDebugPort PROC
    LOCAL bDebuggerPresent:BOOL
    LOCAL dwReturnLen:DWORD,dwDebugPort:DWORD,fnNtQueryInformationProcess:DWORD
    LOCAL hCurrentProcess:HANDLE, hNtDll:HANDLE
    
	; CheckRemoteDebuggerPresent()
	call GetCurrentProcess
    mov  hCurrentProcess,eax
	lea eax,bDebuggerPresent
    push eax
	push hCurrentProcess    
    call CheckRemoteDebuggerPresent
    test eax,eax
    je fn_fails
    cmp bDebuggerPresent,TRUE
    je lb_debugger_found
    
    ; NtQueryInformationProcess()
    
    invoke GetModuleHandle, ADDR szNtDll
    mov  hNtDll,eax
    invoke GetProcAddress, hNtDll, ADDR szNtQueryInformationProcess
    mov fnNtQueryInformationProcess,eax
    lea eax,dwReturnLen
    push eax
    push 4
    lea eax,dwDebugPort
    push eax
    push 7h ;ProcessDebugPort
    push 0ffffffffh
    call fnNtQueryInformationProcess
    cmp dwDebugPort,0
    jne lb_debugger_found
    
    mov eax,FALSE
    ret
    
    lb_debugger_found:
	mov eax,TRUE
	ret
	
	fn_fails:
    invoke ExitProcess, 0
CheckDebugPort ENDP

DebuggerInterrupts PROC
	;set exception handler
	push lb_exception_handler
	assume fs:nothing
	push [fs:0h]
	mov [fs:0],esp
	
	;reset flag eax invoke int3
	xor eax,eax
	int 3h
	
	;restore exception handler
	pop [fs:0]
	add esp,4h
	
	;check if the flag had been set
	test eax,eax
	je lb_debugger_found
	
	mov eax,FALSE
	ret
	
	lb_debugger_found:
	mov eax,TRUE
	ret
	
	lb_exception_handler:
	;eax = ContextRecord
	mov eax,[esp+0ch]
	;set flag ContextRecord.eax
	mov dword ptr [eax+0b0h],0ffffffffh
	;set ContextRecord.EIP
	inc dword ptr [eax+0b8h]
	xor eax,eax
	retn 	
DebuggerInterrupts ENDP

TimingChecks PROC
	rdtsc
	mov ecx,eax
	mov ebx,edx
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	pushad
	popad
	rdtsc
	cmp edx,ebx
	ja lb_debugger_found
	sub eax,ecx
	;test on my computer it takes 0x130 clock when run in a debugger
	;by set breakpoint at the start rdtsc and the end rdtsc
	;intel i5-8300H 
	cmp eax, 0ffh
	ja lb_debugger_found
	mov eax,FALSE
	ret
	lb_debugger_found:
	mov eax,TRUE
	ret
TimingChecks ENDP

SeDebugPrivilege PROC
	LOCAL bDebuggerPresent:BOOL
    LOCAL dwCsrId:DWORD,fnCsrGetProcessId:DWORD
    LOCAL hNtDll:HANDLE
    
    ; NtQueryInformationProcess()
    
    invoke GetModuleHandle, ADDR szNtDll
    mov  hNtDll,eax
    invoke GetProcAddress, hNtDll, ADDR szCsrGetProcessId
    mov fnCsrGetProcessId,eax
    call fnCsrGetProcessId
    mov dwCsrId,eax
    
    invoke OpenProcess, PROCESS_QUERY_INFORMATION, FALSE, dwCsrId
	test eax,eax
	jnz debugger_found
	mov eax,FALSE
	ret
	debugger_found:
	mov eax,TRUE
	ret
SeDebugPrivilege ENDP

end start





