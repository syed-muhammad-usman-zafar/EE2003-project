 org 100h
 jmp start
 start:
   mov cl,[perform_intro]
   or cl,cl
   jz game
   
      ; Set video mode to 80x25 text mode (AH = 00, AL = 03)
   mov ah, 00h
   mov al, 03h
   int 10h
      mov dx,my_message
      mov ah,9            ; DS:DX= pointer to '$' terminated string
      int 21h
    
      mov dx,separator
      mov ah,9            ; DS:DX=pointer to '$' terminated string
      int 21h
   
  game: ; A
			 main_loop: ;B
			  
			   mov cx,9
			   mov dl,'x'
			   for_loop:  ;C
						  push cx
						  push dx
						  mov dx,prompt
						  call print_string_0
						  call input_user_move
						  pop dx
						  call update_board
						  call print_board

						  cmp dl,'x'
						  je  mov_o
						  
						  mov dl,'x'
						  jmp end_mov
							 
						  mov_o: ;C1
							 mov dl,'o'
							 
						  end_mov: ;C2
							 push dx
						  
					   check_for_win: ;C3
								  mov si,row1
								  mov cx,3
								  
						  check_for_win_row_loop: ;C3-1
						  
									 push cx       ; save loop counter
									 xor cx,cx     ; clear cx
									 mov cl,[si]   ; move contents of addess pointer into cl
									 mov ax,cx     ; add new contents to accumlator ax
									 mov cl,[si+2] ; move contents of 2nd cell into cl
									 add ax,cx     ; add to accumulator
									 mov cl,[si+4] ; move contents of 3rd cell into cl
									 add ax,cx     ; add to accumulator
									 
									; mov cl,[si+6] ; move contents of 4th cell into cl
									 ;add ax,cx     ; add to accumulator
									
									 cmp ax,3*'o'  ; check if 3 'o' were in the three rows
									 jz win_found
									 cmp ax,3*'x'  ; check if 3 'x' were in the three rows
									 jz win_found
									 add si,8      ; move to next row (there 8bytes per row)
									 pop cx        ; get loop counter
									 dec cx        ; decrement loop counter. stay in loop if not zero
								  jnz check_for_win_row_loop ; stay in loop until cx is zero

						  mov si,row1
						  mov cx,3
						  
						  check_for_win_col_loop: ;C3-2
									 push cx       ; save loop counter
									 xor cx,cx     ; clear cx
									 mov cl,[si]   ; move contents of addess pointer into cl
									 mov ax,cx     ; add new contents to accumlator ax
									 mov cl,[si+8] ; move contents from 2nd row into cl
									 add ax,cx     ; add to accumulator
									 mov cl,[si+2*8] ; move contents from 3rd row into cl
									 add ax,cx     ; add to accumulator
									 
									  ;mov cl,[si+4*8] ; move contents from 4th row into cl
									 ;add ax,cx     ; add to accumulator
									 
									 cmp ax,3*'o'  ; check if 3 'o' were in the three rows
									 jz win_found
									 cmp ax,3*'x'  ; check if 3 'x' were in the three rows
									 jz win_found
									 add si,2      ; move to next column (skip the vertical bar)
									 pop cx        ; get loop counter
									 dec cx        ; decrement loop counter. stay in loop if not zero
								  jnz check_for_win_col_loop ; stay in loop until cx is zero

							 mov si,row1
							 xor cx,cx     ; clear cx
							 mov cl,[si]   ; move contents of addess pointer into cl
							 mov ax,cx     ; add new contents to accumlator ax
							 mov cl,[si+8+2] ; move contents from 2nd row into cl
							 add ax,cx     ; add to accumulator
							 mov cl,[si+2*8+4] ; move contents from 3rd row into cl
							 add ax,cx     ; add to accumulator
							 cmp ax,3*'o'  ; check if 3 'o' were in the three rows
							 jz win_found
							 cmp ax,3*'x'  ; check if 3 'x' were in the three rows
							 jz win_found

							 mov si,row1
							 xor cx,cx     ; clear cx
							 mov cl,[si+4]   ; move contents of addess pointer into cl
							 mov ax,cx     ; add new contents to accumlator ax
							 mov cl,[si+8+2] ; move contents from 2nd row into cl
							 add ax,cx     ; add to accumulator
							 mov cl,[si+2*8] ; move contents from 3rd row into cl
							 add ax,cx     ; add to accumulator
							 cmp ax,3*'o'  ; check if 3 'o' were in the three rows
							 jz win_found
							 cmp ax,3*'x'  ; check if 3 'x' were in the three rows
							 jz win_found
							 pop dx
						 
						  pop cx
						  dec cx
			   jnz for_loop  ;back to C
			   
			   win_found:  ;D
				   cmp ax,3*'o'
				   jz o_wins
					  mov dx,x_is_the_winner
					  call print_string_0
					  jmp end_print_winner
				   o_wins: ;D-1
					  mov dx,o_is_the_winner
					  call print_string_0
				 
				  
			   end_print_winner: ;E
			  ; mov al,0            ; return code 
			  ; mov ah,4Ch          ; "EXIT"  AL = return code
			   ;int 21h

			   ; ask the user if they want to play again
				mov ah, 09h ; DOS function to print a string
				mov dx, restart_prompt
				int 21h

				; Get user input (Y/N)
				mov ah, 01h ; DOS function to read a character
				int 21h
				cmp al, 'y'
				je main_loop ; Jump to the main loop if the user wants to play again

				; Exit the program if the user does not want to play again
				mov al, 0 ; return code (0 = no error)
				mov ah, 4Ch ; "EXIT" - TERMINATE WITH RETURN CODE, AL = return code
				int 21h

			   print_string: ;F
				  mov ah,40h
				  mov bx,01h           ; stdout
				  int 21h
			   ret

			   print_string_0: ;G
				  mov si,dx            ; load the start of string into si
				  print_string_0_loop:
					 mov cl,[si]       ; load the character byte into ch
					 inc si            ; advance dx pointer to the next character
					 and cl,cl         ; check to see if the char is zero
				  jnz print_string_0_loop
				  dec si               ; si is pointing to the byte after null. decrement it back to null char.
				  sub si,dx            ; subract first char address from last char address to get string length
				  mov cx,si            ; int 21h ah=40h expects CX to contain the string length

				  mov ah,40h
				  mov bx,01h           ; stdout
				  int 21h
			   ret ; print_string_0

			   input_user_move: ;H
				  ; read first char (row) from stdin without echo. The result is stored in AL
				  mov ah,07h
				  int 21h
				  sub al,30h ; convert ASCII to integer by subtracting '0'
				  mov [user_move],al

				  ; read another char (column) from stdin without echo. The result is stored in AL
				  mov ah,07h
				  int 21h
				  sub al,30h ; convert ASCII to integer by subtracting '0'
				  mov [user_move+1],al
			   ret ;input_user_move


			   ; 'x' or 'o' passed in with DL register
			   ; ax, cx and si are corrupted
			   update_board:;I
						  xor  ax,ax
						  mov  al,[user_move+1]
						  shl  ax,1 ;multiple by 2 to handle the vertical bar separators
						  xor  cx,cx
						  mov  cl,[user_move]
						  shl  cx,3  ; multiply by 8 to get the row(each row is conviently 8 bytes)
						  add  ax,cx
						  add  ax,row1
						  mov  si,ax
						  mov  [si],dl
					 
						  ret ;update_board


			   print_board: ;J
						  push dx
						  
						  mov ah,09h
						  mov al,0x01 ;fg text (white)
						  mov bh, 0x00 ;  bg (black)
						  int 10h
						 
						 mov dx,row1
						 call print_string_0
						
						  mov ah, 09h
						  mov al, 0x01
						  mov bh, 0x00 ;  bg (black)
						  int 10h
						  mov dx,sep
						  call print_string_0
                          
						  mov ah,09h
						  mov al,0x01
						  mov bh, 0x00 ;  bg (black)
						  int 10h
						  mov dx,row2
						  call print_string_0
						  
						  mov ah, 09h
						  mov al, 0x01
						  mov bh, 0x00 ;  bg (black)
						  int 10h
						  mov dx,sep
						  call print_string_0
                          
						  mov ah, 09h
						  mov al, 0x07
						  mov bh, 0x00 ;  bg (black)
						  int 10h
						  mov dx,row3
						  call print_string_0
						  
						  pop dx
						  ret; print_board



;int main()
   perform_intro dw 0
   my_message db 'He\$$lloh ',41h,7,'$',10,0
   my_message_len_equ equ $-my_message
   my_message_len_dw dw my_message_len_equ
 
   separator db 10,10,"------------------------",10,10,'$'

   o_is_the_winner db 'PLAYER 2 WINS_ NICE GAME_ ;)_USMANS TIC TAK TOE',10,0
   x_is_the_winner db 'PLAYER 1 IS VICTORIOUS_ GOOD GAME :)_USMANS TIC TAK TOE',10,0
                             
   prompt db ':PLAYER 1 IS X PLAYER 2 IS O FIRST ENTER ROW NO(0,1,2)THEN PRESS COL NO(0,1,2) ',10,0
   restart_prompt db  'Do you want to play again? (Y/N): $',10,0
   user_move db 0,0
   row1 db ' | |  ',10,0
   row2 db ' | |  ',10,0
   row3 db ' | |  ',10,0
   sep  db '----- ',10,0