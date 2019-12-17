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
Ytmp dword 0                            
Ytmp2 dword 0
YinitialIsFull byte 0
checkRight byte 0					; = '1' if the number entered is correct & '0' if it is wrong 
Ycounter byte 0						; if > 9 endline (used in YDisplay)
YRowIndexCounter byte 1					
YColCounter	byte 1				
YRowCounter byte 1



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
MAINLOOP:
call Kedit
jmp MAINLOOP
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
		jmp Next

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
	cmp check,0 
	jne close_file

	mov	buffer[eax],0		                       ; insert null terminator
	mWrite "File size: "
	call	WriteDec			                   ; display file size
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

ColorItYellow PROC
	mov eax,yellow+(black*16)
	call SetTextColor

	ret
ColorItYellow ENDP

;Displayes the board with each new value
YDisplay PROC
mov YRowIndexCounter, 2				
mov YColCounter, 1				
mov YRowCounter, 1
mov Ycounter, 0	
call clrscr
call ColorItYellow
mWrite "   1 2 3  |  4 5 6  |  7 8 9 "
call crlf
mwrite "   ---------------------------"
call crlf
mwrite "1 |"
call DefaultColor

mov ecx,sizeof EditMatrix
mov ebp, 0
DisplayEditLoop:
mov al, EditMatrix[ebp]
call Kcompare
cmp ColorMatrix[ebp],31h
jne NOTWHITE					
call DefaultColor			;if WHITE
jmp SKIP

NOTWHITE:					;else if NOT WHITE
cmp checkRight,0
jne CORRECT
call ColorItRed				;if the current value is WRONG
jmp SKIP

CORRECT:
call ColorItGreen			;if the current value is RIGHT

SKIP:
mov al, EditMatrix[ebp]
cmp YColCounter, 3
jbe PRINTSPACECOLUMN
mov Ytmp, eax
call DefaultColor
mov eax, Ytmp
mWrite " |  "
mov YColCounter, 1

PRINTSPACECOLUMN:
inc YColCounter
call writeChar				;print the current element in EditMatrix
mWrite " "
inc ebp
inc Ycounter				
cmp Ycounter, 9
jb CONT	
mov Ytmp, eax
call ColorItYellow
mwrite "|"	
mov eax, Ytmp
cmp YRowCounter, 3
jb PRINTSPACEROW		
call crlf
mov Ytmp,eax
call DefaultColor
mov eax,Ytmp
mov Ytmp,ecx
 mWrite "  |------"
mov ecx, 2
PRINTDASHESLOOP:
 mWrite "   -------"
loop PRINTDASHESLOOP
mov ecx, Ytmp
mwrite "|"	
mov YRowCounter, 0
PRINTSPACEROW:
call crlf				;if Ycounter > 9 endLine

cmp YRowIndexCounter, 9
ja CONT
mov Ytmp, eax
call ColorItYellow
mov al, YRowIndexCounter
call writeDec
mwrite " |"
inc YRowIndexCounter
mov eax,Ytmp
call DefaultColor

mov YColCounter, 1
mov Ycounter, 0
inc YRowCounter
CONT:
DEC ecx
jnz DisplayEditLoop

ret
YDisplay ENDP

Kedit PROC
	KL1:
	call YDisplay
	mwrite "Enter Row number: "
	call readint
	call crlf
	mov Row ,al
	mwrite "Enter Column number: "
	call readint
	call crlf
	mov Col ,al
	mwrite "Enter Value: "
	call readchar
	call crlf
	mov Value ,al
	call GetIndex
	movzx eax,ColorMatrix[ebp]
	cmp eax,30h
	je KE
	mwrite "Invalid row or column u cannot edit this cell"
	call waitmsg
	Loop KL1
	KE:
	mov al,Value
	mov EditMatrix[ebp],al
	;call YDisplay
	ret
Kedit ENDP
; Function that compares the edited value 
Kcompare PROC
	cmp al,FinalMatrix[ebp]
	je  right
	mov al,0
	mov checkRight,al
ret
	right:
	mov al,1
	mov checkRight,al
ret
Kcompare ENDP

;Transfares numbers from Buffer to Initioal_Matrix without endlines
;and filling the 'ColorMatrix'

TransferData PROC
mov ecx, sizeOf buffer
dec ecx
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
mov al,' '
Continue:
stosb						;store into InitialMatrix
mov edi, edx
mov Ytmp, edi
mov edi, YeditOffset
stosb						;store into EditMatrix

mov YeditOffset, edi
mov edi, Ytmp
inc ebx
jmp Skip

StoreFinal:
stosb						;store into the finall matrix

inc ebx						;go to the next element
Skip:
loop TransLoop

;====================================TEST DISPLAY INITIAL, EDIT, COLOR, FINAL======================
;====================================END TEST DISPLAY INITIAL, EDIT, COLOR, FINAL======================

not check
not YinitialIsFull
ret
TransferData ENDP


;PROC to get the index of selected index in 1D array
GetIndex PROC   
	dec Row
	dec Col
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