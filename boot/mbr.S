;mbr
%include "boot.inc"
SECTION MBR vstart=0x7c00
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov fs,ax
	mov sp,0x7c00
	mov ax,0xb800
	mov gs,ax

; INT 0x10 Nunber: 0x06 Description:scroll window
; scroll all lines means clear window
; input: 
;	AH number=0x06
;	AL: num of scroll
; 	BH: property
;	(CL,CH): left top (X,Y)
;	(DL,DH): right down (X,Y)
; return: no
	mov ax, 0x600
	mov bx, 0x700
	mov cx, 0		;(0,0)
	mov dx, 0x184f  ;(80,25)
	int 0x10

	mov byte [gs:0x00], 'M'
	mov byte [gs:0x01], 0xA4
	mov byte [gs:0x02], 'B'
	mov byte [gs:0x03], 0xA4
	mov byte [gs:0x04], 'R'
	mov byte [gs:0x05], 0xA4	

	mov eax,LOADER_START_SECTOR ; lba address
	mov bx,LOADER_BASE_ADDR		; write address
	mov cx,3
	call rd_disk_m_16

	jmp LOADER_BASE_ADDR+0x300

;read hard disk sector
rd_disk_m_16:
	mov esi,eax
	mov di,cx ;backup

;step1: set sector number
	mov dx,0x1f2
	mov al,cl
	out dx,al		;sector number
	mov eax,esi		;restore ax

;setp2: put LBA address to 0x1f3~0x1f6
	;LBR 7-0 :0x1f3
	mov dx,0x1f3
	out dx,al

	;LBR 15-8: 0x1f4
	mov cl,8
	shr eax,cl
	mov dx,0x1f4
	out dx,al

	;LBR 23-16: 0x1f5
	shr eax,cl
	mov dx,0x1f5
	out dx,al

	shr eax,cl
	and al,0x0f		;LBR 24-27
	or al,0xe0		;set 7-4: 1110, lba mode
	mov dx, 0x1f6
	out dx,al

;step3: write read instruction(0x20) to port 0x1f7
	mov dx,0x1f7
	mov al,0x20
	out dx,al

;step4: check disk
.not_ready:
	nop;
	in al,dx
	and al,0x88 ;bit 4 is 1: disk is ready
				;bit 7 is 1: disk is busy
	cmp al,0x08
	jnz .not_ready ;not ready: wait

;step 5: read data from port 0x1f0
	mov ax,di
	mov dx,256
	mul dx
	mov cx,ax
;di : num of sector to be read, a sector is 512 byte, everytime a word is read, so total num of read is di*512/2=di*256

	mov dx, 0x1f0
.go_on_read:
	in ax,dx
	mov [bx], ax
	add bx,2
	loop .go_on_read
	ret

	times 510-($-$$) db 0
	db 0x55, 0xaa
