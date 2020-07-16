TITLE Program 06     (Program06.asm)

; Author: Christopher Eckerson
; Last Modified: 3/15/2020
; OSU email address: eckersoc@oregonstate.edu
; Course number/section: CS 271 W2020 / C400
; Project Number: Project #06                Due Date: 3/15/2020
; Description:

; gets 10 valid integers fromthe user and stores the numeric values in an array.
; then displays the integers, sum, and average
; testing with positive and negative
; conversion must use lodsb and/or stosb appropriately
; all parameters to stack

INCLUDE Irvine32.inc


; -------------------------------------------------------------------------------
getString MACRO memoryAddress:REQ, stringSize:REQ, promptAddress:=<OFFSET inputPrompt>
;
; Displays a prompt, then gets the user's keyboard input into a memory location.
; Receives: address of memory location to store input and a prompt string address.
; -------------------------------------------------------------------------------
	
	push	edx
	push	ecx
	push	eax
	call	Crlf
	mov		edx, promptAddress
	call	WriteString
	mov		edx, memoryAddress
	mov		ecx, stringSize - 1
	call	ReadString
	mov		stringSize, eax
	pop		eax
	pop		ecx
	pop		edx
ENDM

; -------------------------------------------------------------------------------
displayString MACRO memoryAddress:REQ
; print the string which is stored in a specific memory location
; Receives: address of memory location where string is location
; -------------------------------------------------------------------------------
	push	edx
	call	Crlf
	mov		edx, [memoryAddress]
	call	WriteString
	call	Crlf
	pop		edx
ENDM
TOTALINPUTS = 10
MAXLENGTH = 11			
.data

programTitle		BYTE	"Programming Assignment #6: Designing low-level I/O procedures", 0
programmerName		BYTE	"By Christopher Eckerson", 0
instructions		BYTE	"Please enter 10 signed integers. Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.", 0
inputPrompt			BYTE	"Please enter an signed integer: ", 0
errorMsg			BYTE	"Error: You did not enter a signed integer or your nuymber was too big.", 0
inputErrorPrompt	BYTE	"Please try again: ", 0
entryTitle			BYTE	"You entered the following signed integers: ", 0
sumTitle			BYTE	"The sum of these integers is: ", 0
averageTitle		BYTE	"The rounded average is: ", 0
farwellMsg			BYTE	"Thank you for using this program!", 0

validIntegerArray	SDWORD	TOTALINPUTS	DUP(0)
numericString		BYTE	MAXLENGTH	DUP(?)
			


.code
main PROC
	
	push	OFFSET instructions			; pass instructions by reference
	push	OFFSET programmerName		; pass programmerName by reference
	push	OFFSET programTitle			; pass programTitle by reference
	call	introduction				; introduces the program to user
	
	push	OFFSET validIntegerArray	; pass array by reference
	push	TOTALINPUTS					; pass lengthof array
	push	OFFSET numericString		; pass userInput by reference
	push	MAXLENGTH					; pass max lengthof userInput
	call	getData

	push	OFFSET validIntegerArray	; pass array by reference
	push	TOTALINPUTS					; pass lengthof array
	push	OFFSET numericString		; pass numericString by reference
	push	MAXLENGTH					; pass max lengthof userInput
	call	showData

	displayString	OFFSET farwellMsg

	exit	; exit to operating system
main ENDP

; ------------------------------------------------------------------------------------------
; introduction PROCEDURE
; Prints the program title, the programmer's name, and provides		introduction Stack:
; a description of the nature of the program.						[EBP]		old EBP
;																	[EBP+4]		@ret
; Recieves: OFFSETs of programTitle, programmerName, and			[EBP+8]		@programTitle
;  instructions onto the stack.										[EBP+12]	@programmerName
; Returns: nothing													[EBP+16]	@instructions
; Preconditions: Address of strings must be pushed onto the
;  stack as reference parameters.
; Postconditions: None
; Registers changed: None	
; ------------------------------------------------------------------------------------------
introduction PROC
	push	ebp
	mov		ebp, esp
	
	push	edx						; pushes register(s) onto stack to open them for use		
	
	mov		edx, [ebp+8]			; move address reference of programTitle into edx
	call	WriteString				; print programTitle string
	call	Crlf					; move to next line
	mov		edx, [ebp+12]			; move address reference of programmerName into edx
	call	WriteString				; print programmerName string
	call	Crlf					; move to next line
	call	Crlf					; move to next line
	mov		edx, [ebp+16]			; move address reference of instructions into edx
	call	WriteString				; print instructions string
	call	Crlf					; move to next line
	call	Crlf					; move to next line
	
	pop		edx						; restore register(s) to original value(s) 
	pop		ebp
	ret	12							; return, clear stack
introduction ENDP

; ------------------------------------------------------------------------------------------
; getData PROCEDURE
; Prompts user to enter a number of signed integer values.  		getData Stack:
; Each request for input uses ReadVal PROC, which converts into 	[EBP]		old EBP
; numeric value.  The converted value is then stored in 			[EBP+4]		@ret
; validInputArray.  This PROC will loop until each element of		[EBP+8]		MAXLENGTH
; the validInputArray is filled with a valid signed 32-bit integer.	[EBP+12]	@numericString
;																	[EBP+16]	TOTALINPUTS	
; Recieves: OFFSETs userInput and validInputArray. Values	 		[EBP+20]	@validInputArray		
;  MAXLENGTH (of string input) and TOTALINPUTS (from user). 		
; Returns: Fills validInputArrayValid with valid signed integers from user.
; Preconditions: None			
; Postconditions: None
; Registers changed: None	
; ------------------------------------------------------------------------------------------
getData PROC
	push	ebp
	mov		ebp, esp
	push	ecx
	push	esi
	mov		ecx, [ebp+16]		; move TOTALINPUTS into counter register
	mov		edi, [ebp+20]		; point to valid input array
getInput:
	mov		esi, [ebp+12]		; point to string array
	
	push	esi					; pass by reference the numericstring
	push	[ebp+8]				; pass by value the length of the numericstring
	push	edi					; pass by reference the validInputArray
	call	ReadVal				; call ReadVal PROC for each element, prompts user for input
	add		edi, 4				; increment to next element in validInputArray
	loop	getInput
	
	pop		esi
	pop		ecx
	pop		ebp
	ret 16
getData	ENDP


; ------------------------------------------------------------------------------------------
; readVal PROCEDURE
; Prompts user to enter a number of signed integer values.  		readVal Stack:
; Checks sign with checkSign PROC and sets up numericString for		[EBP]		old EBP
; digitConversion PROC to convert each digit of the string and 		[EBP+4]		@ret
; add it to the current element of the valid input array.			[EBP+8]		@validInputArray element
; Data validates that input only includes digits, or "+/"-" signs.	[EBP+12]	MAXLENGTH
; Error message for non-numeric values or if too large for 32bt,	[EBP+16]	@numericString	
; discards the current numericString to get a new numericString input.
;
; Recieves: OFFSETs userInput and validInputArray. Values	 			
;  MAXLENGTH (of string input)  		
; Returns: The numeric value of string in provided memory location (element of validInputArray)
; Preconditions: The a location to store the numericString must be defined and its maxlength provided. 			
; Postconditions: None
; Registers changed: None	
; ------------------------------------------------------------------------------------------
ReadVal PROC
	push	ebp
	mov		ebp, esp
	push	esi
	push	edi
	push	ecx
	push	eax

	getString	[ebp+16], [ebp+12]	; userInput string address location and size of allocated memory
setup: 
	mov			esi, [ebp+16]		; point to end of userInput string
	add			esi, [ebp+12]
	dec			esi
	mov			eax, 0				; zero eax			
	and			eax, 7fffffffh		; clear Sign flag

	push		[ebp+12]			; pass value of the MAXLENGTH
	push		[ebp+16]			; pass reference of userInput
	push		[ebp+8]				; pass reference of validInputArray
	call		checkSign			; adjust ecx, adjust esi, set valid input element as positive/negative
	clc								; clear the carry flag
	cld								; set forward direction flag
	
convert:	
	lodsb							; load string byte by byte
	cmp			al, 30h				; between 0 <= stringVal <= 9 
	jl			InputError
	cmp			al, 39h
	jg			InputError
	
	push		[ebp+8]				;pass by reference the validInputArray element
	push		esi					;pass by reference the string element
	call		DigitConversion
	
	jc			InputError			;if the carry flag is set, input was too large.
	loop		convert				;get next string value

	jmp			conversionDone

InputError:

	displayString	OFFSET errorMsg
	getString		[ebp+16], [ebp+12], OFFSET inputErrorPrompt		; get new numericString
	jmp				setup


conversionDone:
	pop		eax
	pop		ecx
	pop		edi
	pop		esi
	pop	ebp
	ret 12

ReadVal ENDP

; ------------------------------------------------------------------------------------------
; checkSign PROCEDURE
; Looks at first value located at the numericString address and  	checkSign Stack:
; Checks if the it contains a "+"/"-" sign.  For these special 		[EBP]		old EBP
; cases, the valid input array is updated to contain the value		[EBP+4]		@ret
; FFFFFFFFh to represent negative numericString. 					[EBP+8]		@validInputArray element
;																	[EBP+12]	@numericString
; Error message for non-numeric values or if too large for 32bt,	[EBP+16]	MAXLENGTH	
; discards the current numericString to get a new numericString input.
;
; Recieves: OFFSETs userInput and validInputArray. Values MAXLENGTH (of string input)  		
; Returns: The numeric value of string in provided memory location (element of validInputArray)
; Preconditions: The a location to store the numericString must be defined and its maxlength provided. 			
; Postconditions: None
; Registers changed: None	
; ------------------------------------------------------------------------------------------
checkSign PROC
	push	ebp
	mov		ebp, esp
	push	edi
	push	eax

	mov		esi, [ebp+12]				;get @numericString
	mov		edi, [ebp+8]				;get @validInputArray element
	mov		al, [esi]					;get first value of numericString
	cmp		al, 2dh						;compare to "-" symbol
	je		negative		
	cmp		al, 2bh						;compare to "+" symbol
	je		positive
	jmp		notSigned					;first value contains neither, update counter with length of numericString
negative:								;set validInputArray element to FFFFFFFFh, point esi to next value, and update counter
	mov		eax, 0FFFFFFFFh	
	mov		[edi], eax
	inc		esi
	mov		ecx, [ebp+16]
	dec		ecx
	jmp		donecheck
positive:
	mov		ecx, [ebp+16]				;point esi to next value, and update counter 
	dec		ecx
	inc		esi
	jmp		donecheck
notSigned:	
	mov		ecx, [ebp+16]
donecheck:
	pop		eax
	pop		edi
	pop		ebp
	ret 12
checkSign ENDP

; ------------------------------------------------------------------------------------------
; DigitConversion PROCEDURE
; Converts numericString element to its numeric value and add  		DigitConversion Stack:
; it to the validInputArray element. As a signed numeric value, 	[EBP]		old EBP
; the procedure checks if above or below 7FFFFFFFh.					[EBP+4]		@ret
; Set carry flag if negative or positive values go out of boundary. [EBP+8]		@numericString
;																	[EBP+12]	@validInputArray element
; Recieves: OFFSETs userInput and validInputArray.  		
; Returns: updates validInputArray element by adding the digit value
; Preconditions: numericString pointer must be incremented outside of PROC, from highest digit
;  to lowest digit. The validInputArray element must be initialized as zero or FFFFFFFFh.
; Postconditions: None
; Registers changed: None	
; ------------------------------------------------------------------------------------------
DigitConversion PROC
	push	ebp
	mov		ebp, esp

	mov		edx, 0				
	mov		edi, [ebp+12]			; @validInput element
	mov		eax, [edi]
	cmp		eax, 7FFFFFFFh
	jbe		positive				; the integer has been signed positive
	jmp		negative				; the integer has been signed negative
negative:
	mov		eax, 0FFFFFFFFh
	sub		eax, [edi]
	mov		ebx, 10
	mul		ebx
	cmp		eax, 7FFFFFFFh
	ja		overflow
	mov		esi, [ebp+8]
	dec		esi		
	mov		bl, [esi]
	inc		esi
	add		eax, ebx
	cmp		eax, 7FFFFFFFh
	sub		eax, 30h
	not		eax
	inc		eax
	mov		[edi], eax
	jmp		notOverflow
positive:
	mov		ebx, 10
	mul		ebx
	cmp		eax, 7FFFFFFFh
	ja		overflow
	mov		esi, [ebp+8]
	dec		esi		
	mov		bl, [esi]
	inc		esi
	add		eax, ebx
	cmp		eax, 7FFFFFFFh
	sub		eax, 30h
	mov		[edi], eax
	jmp		notOverflow
overflow:
	stc
notOverflow:
	clc
	
	pop		ebp
	ret	8
DigitConversion	ENDP

showData PROC
	push	ebp
	mov		ebp, esp
	push	ecx
	push	esi

	mov		ecx, [ebp+16]		; move TOTALINPUTS into counter register
	mov		edi, [ebp+20]		; point to valid input array
	displayString	OFFSET entryTitle
getOutput:
	mov		esi, [ebp+12]		; point to string array
	
	push	esi					; pass by reference the numericstring
	push	[ebp+8]				; pass by value the length of the userInput string
	push	edi					; pass by reference the validInputArray
	call	WriteVal			; call ReadVal PROC for each element, prompts user for input
	
	add		edi, 4				; increment to next element in validInputArray
	loop	getOutput
	
	
	; calculate average
	

	pop		esi
	pop		ecx
	pop		ebp
	ret 16
showData ENDP

WriteVal PROC
; for signed integers, convert a numeric value to string of digits,
; invoke 'displayString' macro to produce the output 
	push	ebp
	mov		ebp, esp
	mov		esi, [ebp+8]
	mov		eax, [esi]
	call	WriteInt
	pop		ebp
	ret	12
WriteVal ENDP

calcAverage PROC
	push	ebp
	mov		ebp, esp
	pop		ebp
	ret
calcAverage ENDP

END main
