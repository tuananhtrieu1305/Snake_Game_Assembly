.model small
.stack 100h
.data
    snake dw 10Dh, 10Ch, 10Bh, 10Ah, 150 dup(?)   
    ;khai bao con ran ban dau co 4 o tu (10,1) den (13,1), co 150 o trong de them khi ran an duoc moi
    ;toa do o 1: 10Dh = 00000001 00001101  => o 1 co toa do x = 1101 = 13, y = 0001 = 1
    ;                      y        x
    s_size db 4,0     ;luu do dai ran (ban dau la 4), byte thu 2 de tranh bi tran
    tail dw ?         ;vi tri duoi ran
    
    ;equ dung de dinh nghia hang so 
    left  equ 4Bh  ;const left = 4Bh(mui ten trai)
    right equ 4Dh  ;luu y: 4Bh, 4Dh, 48h, 50h là scan code, không phai ascii code
    up    equ 48h
    down  equ 50h

    cur_dir db right  ;mac dinh khi vao game ran se di sang phai  
    old_dir db right    
    
    mealX db ?
    mealY db ?

    score db '0','0','0','0','$' ;diem gom 4 so
    
    ; 0Ah : di chuyen con tro xuong dong duoi, giu nguyen vi tri theo hang ngang
    ; 0Dh: di chuyen con tro ve dau dong
    ; 20h : ki tu space
    msgstart db 5 dup(0Ah), 7 dup(20h)
         db             '   _____              _              _____                      ',0Dh,0Ah
         db 7 dup(20h), '  / ____|            | |            / ____|                     ',0Dh,0Ah
         db 7 dup(20h), ' | (___    _ __   __ | | _____     | |  __  __ _ _ __ ___   ___ ',0Dh,0Ah
         db 7 dup(20h), '  \___ \ | ''_ \/ _ `| |/ / _ \    | | |_ |/ _` | ''_ ` _ \/ _ \',0Dh,0Ah
         db 7 dup(20h), '  ____) || | | | (_| |   <  __/    | |__| | (_| | | | | | |  __/',0Dh,0Ah
         db 7 dup(20h), ' |_____/ |_| |_|\__,_|_|\_\___|     \_____|\__,_|_| |_| |_|\___|',0Dh,0Ah,0Ah, 0Ah, 0Ah, 0Ah 
         db 22 dup(20h), ' Using arrow keys to move the snake                            ',0Dh,0Ah
         db 27 dup(20h), ' Press Enter to start. $                                       '

    msgover db 5 dup(0Ah), 11 dup(20h)    
        db            ,'   _____                         ____                        ',0Dh,0Ah
        db 11 dup(20h),'  / ____|                       / __ \                        ',0Dh,0Ah
        db 11 dup(20h),' | |  __  __ _ _ __ ___   ___  | /  \ |__    _____  ______    ',0Dh,0Ah
        db 11 dup(20h),' | | |_ |/ _` | ''_ ` _ \/ _ \ | |  | |\ \  / / _ \| ___ /    ',0Dh,0Ah
        db 11 dup(20h),' | |__| | (_| | | | | | |  __/ | \__/ | \ \/ /  __/|     \    ',0Dh,0Ah
        db 11 dup(20h),'  \_____|\__,_|_| |_| |_|\___|  \____/   \__/ \___||__|\__\   ',0Dh,0Ah,0Ah,0Ah  
        db 28 dup(20h),'  Your score is: $                                           ',0Dh,0Ah
    
.code
main proc
    mov ax, @data
    mov ds, ax
    
    ;In ra msgstart                                       
    mov ah, 9   
    lea dx, msgstart                             
    int 21h  
                                    
    mov ax, 40h   ;Dung ax lam thanh ghi trung gian gan 40h cho es
    mov es, ax    ;es = 40h se luu cac thong tin lien quan den kich thuoc man hinh, vi tri con tro chuot (so cot, so dong)

    call wait_for_enter     

    mov al, 1      ;Chon trang man hinh moi (Trang 1)
    mov ah, 5      ;Chuyen sang trang da chon
    int 10h            
    
    call randomizeMeal

game_loop:
    call shownewhead

    ;Kiem tra ran co chet khong
    mov dx, snake[0]     ;luu vi tri doan dau tien cua ran
    mov si, w.s_size     ;luu do dai cua ran vao si
    add si, w.s_size     ;nhan doi do dai cua ran (vi moi doan cua ran co 2byte)
    sub si, 2            ;tru di 2 byte se ra vi tri doan cuoi cung cua ran
    mov cx, w.s_size     ;lay do dai cua ran - 4(do dai ban dau)
    sub cx, 4
    jz no_death          ;jump if zero, nhay neu do dai = 4 (ko the chet)
deathloop:               ;neu do dai > 4, vao deathloop
    cmp dx, snake[si]    ;Neu vi tri dau ran va than ran trung nhau => ran chet => nhay vao gameover 
    je game_over
    sub si, 2            ;Neu khong trung nhau, nhay den cac vi tri khac va tiep tuc kiem tra
    dec cx               ;den khi het phan tu cua ran
    jnz deathloop        
no_death:
    mov si, w.s_size     ;Tinh toan lai vi tri doan cuoi cua ran (co the bi thay doi khi nhay vao deathloop)
    add si, w.s_size
    sub si, 2
    mov ax, snake[si]    ;luu vi tri cuoi cung cua ran vao tail qua bien trung gian ax
    mov tail, ax

    call move_snake             

    mov dx, snake[0]          ;luu vi tri dau ran vao dx
    mov al, mealX             ;luu vi tri moi vao al, ah -> luu vao ax
    mov ah, mealY
    cmp ax, dx                ;so sanh vi tri moi voi dau ran
    jne hide_old_tail         ;neu khac nhau, vao hide_old_tail
    mov al, s_size            ;neu bang nhau -> ran an moi -> tang do dai ran
    inc al
    mov s_size, al            ;cap nhat do dai vua tang
    mov ax, tail              ;luu vi tri duoi ran vao ax
    mov bh, 0
    mov bl, s_size            ;bl luu vi tri doan cuoi cung cua ran
    add bl, s_size            ;bh = 0, bl da tinh => phan tu cuoi cua ran duoc luu vao bx
    sub bl, 2
    mov snake[bx], ax           ;them duoi moi
    call scoreplus              ;them diem cho nguoi choi
    call randomizeMeal          ;tao moi moi
    jmp no_hide_old_tail       

hide_old_tail:
    mov dx, tail             ;luu vi tri duoi cu vao dx
    
    mov ah, 02h              ;dat con tro vao vi tri dx
    int 10h

    mov al, ' '              
    mov ah, 09h              ;ham ah,09h in ra ki tu al (ki tu space), co mau bl (mau trang),voi so lan cx (1 lan)
    mov bl, 0Fh
    mov cx, 1     
    int 10h  
    
no_hide_old_tail:
    mov ah, 01h             ;kiem tra phim nhan, ko an phim nao -> bo qua
    int 16h
    jz no_key

    mov ah, 00h           
    int 16h                 ;neu co an phim -> luu huong moi vua nhap vao cur_dir
    mov cur_dir, ah

no_key:
    jmp game_loop           ;quay lai gameloop

game_over:
    xor dx, dx                      ;dat dx = 0  
    
    mov ah, 02h                     ;dua con tro ve lai vi tri dx
    int 10h                  
    
    mov ah, 9                       ;in ra msgover
    lea dx, msgover  
    int 21h   
    
    mov ah, 9
    lea dx, score                   ;in ra score
    int 21h
    
    mov ah, 4ch
    int 21h
main endp    

wait_for_enter proc
    push ax 
    
    wait_loop:
        mov ah, 0      ;Dung ah,0 thay cho ah,1 (ca 2 deu dung de nhap ki tu)
        int 16h        ;Dung 16h thay vi 21h boi 16h ko hien ki tu da nhap len man hinh, 
                       ;dong thoi dung chuong trinh cho den khi nhap dung 
        cmp al, 13     ;Neu ki tu da nhap khong phai enter thi tiep tuc lap
        jne wait_loop  
        
    pop ax
    ret
wait_for_enter endp  

randomizeMeal proc
    mov ah, 00h  ;lay gia tri tu bo dem thoi gian cua he thong (luu trong dx)
    int 1ah      ;gia tri nay thay doi lien tuc, dung lam vi tri ngau nhien cho moi
    
    mov ax, dx      ;luu gia tri ngau nhien vao ax
    xor dx, dx      ;giong mov dx, 0 nhung hieu suat tot hon
    mov cx, 25      ;so dong tren man hinh (25 dong)
    div cx          ;ax / cx, phan nguyen luu vao ax, phan du luu vao dx
    mov mealY, dl   ;lay phan du lam vi tri dong cho moi (phan du tu 0-24)
    
    mov ah, 00h     ;Tiep tuc lay gia tri ngau nhien
    int 1ah 
    
    mov ax, dx       ;Tinh vi tri cot cua moi
    xor dx, dx
    mov cx, 80       ;so cot tren man hinh (80 cot)
    div cx
    mov mealX, dl    ;lay phan du lam vi tri cot cho moi (phan du tu 0-79)
    
    mov dh, mealY       ;gan mealY vao dh, mealX da gan vao dl => dx se luu vi tri moi
    mov cx, w.s_size    ;gan cx bang so phan tu trong mang s_size (ep kieu s_size tu db -> dw)  
    xor bx, bx          ;gan bx = 0, tuc la vi tri doan dau tien cua con ran

    check_snake:
        cmp dx, snake[bx]     ;so sanh vi tri moi voi tung doan cua con ran
        je randomizeMeal      ;neu trung nhau thi tao lai gia tri moi
        
        add bx, 2             ;neu khong trung thi tang tang bx de den doan tiep theo cua con ran (moi doan snake co 2 byte => +2 vao bx)
        loop check_snake      ;lap lai ham nay cho den khi xet het con ran
    
    mov ah, 02h         ;ham ah, 02h se di chuyen con tro chuot den vi tri dx(dh, dl) cua trang bh
    mov bh, 01h         
    int 10h
    
    mov al, 04h        ;luu ki tu thuc an vao al
    mov bl, 0eh        ;luu mau sac thuc an vao bl
    mov cx, 1          ;so lan in ki tu al (kich thuoc thuc an)
    mov ah, 09h        ;Thuc hien in ki tu tai vi tri con tro hien tai
    int 10h 
    
    ret
randomizeMeal endp    

shownewhead proc
    mov dx, snake[0]   ;luu vi tri doan dau tien cua ran   
    
    mov ah, 02h        ;di chuyen con tro chuot den vi tri dx
    int 10h            
    
    mov al, 002        ;luu ki tu dau ran vao al
    mov ah, 09h        ;ham ah, 09h de hien thi ki tu al voi mau bl tai trang bh voi so lan hien thi cx
    mov bl, 0Ah
    mov bh, 01h
    mov cx, 1
    int 10h 
    
    ret
shownewhead endp 

move_snake proc
    mov di, w.s_size         ;Tinh toan vi tri cuoi cung cua ran 
    add di, w.s_size
    sub di, 2

    mov cx, w.s_size         ;luu do dai ran vao cx
    dec cx                   ;giam do dai di 1 (len vi tri phia tren)

    move_array:
        mov ax, snake[di-2]   ;luu vi tri cuoi cua ran vao vi tri truoc no (di chuyen ran di 1 don vi)
        mov snake[di], ax     
        sub di, 2             ;chuyen sang vi tri tiep theo va lap lai thao tac
        loop move_array       ;cho den khi ca con ran den vi tri moi 
    
    getdir:                      ;kiem tra huong di hien tai
        cmp cur_dir, left
        je move_left
        cmp cur_dir, right
        je move_right
        cmp cur_dir, up
        je move_up
        cmp cur_dir, down
        je move_down
    
    get_old_dir:               ;luu huong di cu vao huong di hien tai
        mov al, old_dir
        mov cur_dir, al
        jmp getdir 
        
    move_left:                   
        cmp old_dir, right       ;neu huong cu nguoc chieu voi huong hien tai -> lay huong cu
        je get_old_dir
        mov al, b.snake[0]       ;lay gia tri byte thap cua snake[0] (toa do cua x)
        dec al                   ;x = x - 1 -> di sang trai
        mov b.snake[0], al       ;cap nhat toa do x moi
        cmp al, -1               ;neu khong ra khoi bien ben trai thi vao stop_move
        jne stop_move            ;neu ra khoi bien thi
        mov al, es:[4ah]         ;lay so cot cua man hinh luu vao al
        dec al                   ;tru so cot di 1
        mov b.snake[0], al       ;dua dau con ran ve cot cuoi (lam hieu ung di xuyen qua tuong)
        jmp stop_move            ;ket thuc di chuyen
    
    move_right:                  ;tuong tu ham tren
        cmp old_dir, left
        je get_old_dir
        mov al, b.snake[0]
        inc al
        mov b.snake[0], al
        cmp al, es:[4ah]
        jb stop_move
        mov b.snake[0], 0
        jmp stop_move
     
    move_up:                     ;tuong tu ham tren
        cmp old_dir, down
        je get_old_dir
        mov al, b.snake[1]
        dec al
        mov b.snake[1], al
        cmp al, -1
        jne stop_move
        mov al, es:[84h]
        mov b.snake[1], al
        jmp stop_move 
        
    move_down:                   ;tuong tu ham tren
        cmp old_dir, up
        je get_old_dir
        mov al, b.snake[1]
        inc al
        mov b.snake[1], al
        cmp al, es:[84h]
        jbe stop_move
        mov b.snake[1], 0
        jmp stop_move
    
    stop_move:                       ;luu huong di hien tai vao huong di cu cho lan di chuyen tiep theo
        mov al, cur_dir
        mov old_dir, al
    ret
move_snake endp

scoreplus proc
    mov al, score[3]             ;luu so cuoi cua mang score vao al (chu so hang don vi)
    inc al                       ;tang len 1
    cmp al, '9'                  ;vuot qua 9 -> tang len chu so hang tiep theo
    jg inc_second
    mov score[3], al             ;neu nho hon 9 -> cap nhat ket qua
    ret

inc_second:
    mov score[3], '0'            ;tuong tu phia tren
    mov al, score[2]
    inc al
    cmp al, '9'
    jg inc_third
    mov score[2], al
    ret

inc_third:                      ;tuong tu phia tren
    mov score[2], '0'
    mov al, score[1]
    inc al
    cmp al, '9'
    jg inc_fourth
    mov score[1], al
    ret

inc_fourth:                      ;tuong tu phia tren
    mov score[1], '0'
    mov al, score[0]
    inc al
    mov score[0], al
    ret  
scoreplus endp    

end main  


