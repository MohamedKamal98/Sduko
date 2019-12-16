INCLUDE Irvine32.inc
INCLUDE macros.inc

BUFFER_SIZE = 98

.data
Row byte 0
Col byte 0
index BYTE 0
buffer BYTE BUFFER_SIZE DUP(?)
Initial_Matrix BYTE 81 DUP(?)
FinalMatrix BYTE 81 DUP(?)
EditMatrix byte 81 dup(?)
ColorMatrix byte 81 dup(30h)            ;Contains 1 ifthe current char is not 0

YeditOffset dword offset EditMatrix     ; used in filling the EditMatrix
YcolorOffset dword offset ColorMatrix   ; used in filling the ColorMatrix
Ytmp dword 0                            ; used in filling the ColorMatrix
YinitialIsFull byte 0


UnSolvedFiles BYTE "diff_1_1.txt",0,"diff_1_2.txt",0,"diff_1_3.txt",0,"diff_2_1.txt",0,"diff_2_2.txt",0,"diff_2_3.txt",0,"diff_3_1.txt",0,"diff_3_2.txt",0,"diff_3_3.txt"
SolvedFiles BYTE "diff_1_1_solved.txt",0,"diff_1_2_solved.txt",0,"diff_1_3_solved.txt",0,"diff_2_1_solved.txt",0,"diff_2_2_solved.txt",0,"diff_2_3_solved.txt",0,"diff_3_1_solved.txt",0,"diff_3_2_solved.txt",0,"diff_3_3_solved.txt"
str1Len byte 13
str2Len byte 20
check byte 0
fileHandle  HANDLE ?


Value byte 0
.code
main PROC

mWrite "Choose Level : ",0
	    call CRLF
	mWrite "[1] EASY",0
		call CRLF
	mWrite "[2] MEDIUM",0
		call CRLF
	mWrite "[3] HARD",0
		call CRLF
	mWrite "Enter your choice : ",0
	call readint

call ShowBoards 

call Kedit
	exit
main ENDP



ShowBoards PROC

YFinalLoop:

        cmp check,0 
        jne sol                        ;go to fill FinalMatrix
		mov	edx,OFFSET UnSolvedFiles   ;fill FinalMatrix the initial matrix 
		mov bl, byte ptr str1Len

      jmp mnext

       sol:
        mov	edx,OFFSET SolvedFiles
		mov bl, byte ptr str2Len

mnext:
	cmp eax,1
	je Easy   

	cmp eax,2
	je Medium

	cmp eax,3
	je Hard

	Easy:
		call writeString
		call crlf
		jmp Next

	Medium:
		mov al,3
		Mul bl
		add edx, eax
		call writeString
		call crlf
		jmp Next

	Hard:
		mov al,6
		Mul bl
		add edx, eax
		call writeString
		call crlf
		jmp Next
	

	Next:
	call OpenInputFile
	mov	fileHandle,eax


                                                    ; Check for errors.
	cmp	eax,INVALID_HANDLE_VALUE		            ; error opening file?
	jne	file_ok					                    ; no: skip
	mWrite <"Cannot open file",0dh,0ah>
	jmp	quit						                ; and quit

    file_ok:                                                   ; Read the file into a buffer.
	mov	edx,OFFSET buffer
	mov	ecx,BUFFER_SIZE
	call ReadFromFile
	jnc	check_buffer_size			                ; error reading?
	mWrite "Error reading file. "		            ; yes: show error message
	call	WriteWindowsMsg
	jmp	close_file
	
check_buffer_size:
	cmp	eax,BUFFER_SIZE			                   ; buffer large enough?
	jb	buf_size_ok				                   ; yes
	mWrite <"Error: Buffer too small for the file",0dh,0ah>
	jmp	quit						               ; and quit
	
buf_size_ok:	
	mov	buffer[eax],0		                       ; insert null terminator
	mWrite "File size: "
	call	WriteDec			                   ; display file size
	call	Crlf

                                                   ; Display the buffer.
	mWrite <"Buffer:",0dh,0ah,0dh,0ah>
	mov	edx,OFFSET buffer	                       ; display the buffer
	call	setCharColor
	call	Crlf

close_file:
	mov	eax,fileHandle
	call CloseFile

	quit:
call TransferData
cmp YinitialIsFull, 0
je Return		;if TransferData has been called before
jmp YFinalLoop	;the second itiration is to fill the final matrix from the solved matrix

Return:
	ret
ShowBoards ENDP

;colors the chars before printing them
setCharColor PROC
mov ecx,sizeof buffer
DisplayLoop:
mov bl, [edx]
cmp bl, 30h
jne Ywhite
call ColorItRed
jmp Yred
Ywhite:
call DefaultColor
Yred:
mov al,bl
call writeChar
inc edx
Loop DisplayLoop

ret
setCharColor ENDP


DefaultColor PROC
	mov eax,white+(black*16)
	call SetTextColor
	ret
DefaultColor ENDP

ColorItRed PROC
	mov eax,red+(black*16)
	call SetTextColor

	ret
ColorItRed ENDP

ColorItGreen PROC
	mov eax,green+(black*16)
	call SetTextColor

	ret
ColorItGreen ENDP

ColorItBlue PROC
	mov eax,blue+(black*16)
	call SetTextColor

	ret
ColorItBlue ENDP



Kedit PROC
	KL1:
	mwrite "Enter Row number: "
	call readint
	call crlf
	mov Row ,al
	mwrite "Enter Column number: "
	call readint
	call crlf
	mov Col ,al
	mwrite "Enter Value: "
	call readint
	call crlf
	mov Value ,al
	call GetIndex
	movzx eax,ColorMatrix[ebp]
	cmp eax,30h
	je KE
	mwrite "Invalid row or column u cannot edit this cell"
	call crlf
	Loop KL1
	KE:
	mov al,Value

	mov EditMatrix[ebp],al
	ret
Kedit ENDP


;Transfares numbers from Buffer to Initioal_Matrix without endlines
;and filling the 'ColorMatrix'

TransferData PROC
mov ecx, sizeOf buffer
cmp check,0
jne finall                       ;if check != 0 go to fill the final matrix
mov ebx, offset Initial_Matrix   ;if check == 0 fill the initial matrix 
jmp Yskip
finall:
mov ebx, offset FinalMatrix 

Yskip:

mov esi, offset buffer
TransLoop:
mov edx, esi
lodsb
cmp al, 0dh		
jne Store		 ;if al != '\r' go to stor it into initial matrix
add esi, 1       ;if al = '\r' skip it and skip the next element
dec ecx

jmp Skip

Store:
mov edi,ebx

cmp check,0
jne StoreFinal

cmp al,30h
je DontSetColor				;if al == 0 dont store '1' into the color matrix
mov Ytmp,ebx
mov ebx, YcolorOffset       ;if al != 0 store '1' into the color matrix
mov byte ptr [ebx], 31h
inc ebx
mov YcolorOffset, ebx 
mov ebx,Ytmp
jmp Continue

DontSetColor:

inc YcolorOffset

Continue:
stosb						;store into InitialMatrix
mov edi, edx
mov Ytmp, edi
mov edi, YeditOffset
stosb						;store into EditMatrix

mov YeditOffset, edi
mov edi, Ytmp

StoreFinal:
stosb						;store into the finall matrix

inc ebx						;go to the next element
Skip:
loop TransLoop

;====================================TEST DISPLAY INITIAL, EDIT, COLOR, FINAL======================
mov ecx, 81
mov edx,offset Initial_Matrix

LL:
mov eax,[edx]
call writeChar
inc edx
loop LL

call crlf

mov ecx, 81
mov edx,offset EditMatrix

LLLL:
mov eax,[edx]
call writeChar
inc edx
loop LLLL

call crlf
mov ecx, 81
mov edx,offset ColorMatrix
LLL:
mov eax,[edx]
call writeChar
inc edx
loop LLL

call crlf
mov ecx, 81
mov edx,offset FinalMatrix
LLLLL:
mov eax,[edx]
call writeChar
inc edx
loop LLLLL

call crlf
;====================================END TEST DISPLAY INITIAL, EDIT, COLOR, FINAL======================

not check
not YinitialIsFull
ret
TransferData ENDP


;PROC to get the index of selected index in 1D array
GetIndex PROC   
	mov Ytmp, eax     
	mov index, 0
	mov al, 9
	mul Row
	add index,al
	mov eax,Ytmp
	mov Ytmp,ebx
	mov bl, Col
	add index,bl
movzx ebp,index
	mov ebx, Ytmp

	ret 
GetIndex ENDP



END main