;======================================================
; Title: Slide
;
; Description: A sliding puzzle game
;
; Developer: Jan Tatham
;
; Start Date: 30/08/2009
;
; Required Compiler Options
;
; Compile Instructions:
; ml /c /coff /Cp Slide.asm
; rc Slide.rc
; link /SUBSYSTEM:WINDOWS /LIBPATH:c:\masm32\lib Slide.obj Slide.res
;======================================================
.486
.model flat,stdcall
option casemap:none

;======================================================
; Desc: These are the include files for Windows and Window calls
;======================================================
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc
include \masm32\include\comdlg32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc
include \masm32\include\windows.inc
include \masm32\include\shell32.inc

;======================================================
; Desc: The custom include file
;======================================================
include Slide.inc

;======================================================
; Desc: The Lib's for the included files
;======================================================
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\comctl32.lib
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\shell32.lib

;======================================================
; Desc: This section contains the prototypes for your program
;======================================================

WinMain             PROTO STDCALL   :DWORD, :DWORD, :DWORD, :DWORD
WinProc             PROTO STDCALL   :DWORD, :DWORD, :DWORD, :DWORD
InitControls        PROTO STDCALL   :DWORD
InitBitmaps         PROTO STDCALL   :DWORD
DeleteBitmaps       PROTO STDCALL
SetBitmap           PROTO STDCALL   :DWORD, :DWORD
GetCoordinates      PROTO STDCALL   :DWORD
DrawNumbers         PROTO STDCALL
CreateTiles         PROTO STDCALL
DrawProc            PROTO STDCALL   :DWORD, :DWORD
InitGame            PROTO STDCALL   :DWORD
NewGame             PROTO STDCALL   :DWORD
GetPosOf            PROTO STDCALL   :DWORD, :DWORD, :DWORD
GetTile             PROTO STDCALL   :DWORD
ProcessClick        PROTO STDCALL   :DWORD, :DWORD
ProcessMenuItems    PROTO STDCALL   :DWORD, :DWORD
SetColors           PROTO STDCALL   :DWORD
CheckIfValidBitmap  PROTO STDCALL   :DWORD, :DWORD, :DWORD
OpenBitmap          PROTO STDCALL   :DWORD
GetRandomNumber     PROTO STDCALL
ShuffleTiles        PROTO STDCALL
CheckIfSolved       PROTO STDCALL   :DWORD
UpdateInfo          PROTO STDCALL
DlgProc             PROTO STDCALL   :DWORD, :DWORD, :DWORD, :DWORD
PreviewDlgProc      PROTO STDCALL   :DWORD, :DWORD, :DWORD, :DWORD
CheckMoveLimit      PROTO STDCALL   :DWORD
CheckTimeLimit      PROTO STDCALL   :DWORD

;======================================================
; Name: data
; Desc: This section contains initialized data of your program
;======================================================

.data
    AppName             db      "JE Slide",0
    ClassName           db      "Slide32",0
    ClassStatic         db      "STATIC",0          ; window class, this creates a static control
    StatusParts			dd		65,155,210,230,250
    DefaultStatusText   db      09h,"JE Slide 1.0",0
    MoveStatusText      db      09h,"M",0
    TimeStatusText      db      09h,"T",0
    FontFace            db      "Arial",0
    NumberFormat        db      "%lu", 0
    TextFormat          db      "%s",0
    MovesFormat         db      09h,"%lu move(s)", 0
    MovesLimitFormat    db      09h,"%lu move(s) left", 0
    TimeFormat          db      09h,"%02lu:%02lu:%02lu", 0
    SolvedFormat        db      "Congratulations!", 0Ah, \
                                "You solved the puzzle in %02lu:%02lu:%02lu with %lu moves.",0
    MoveLimitReached    db      "GAME OVER!!!",13,10,"You have reached the Move Limit!!!",0
    TimeLimitReached    db      "GAME OVER!!!",13,10,"You have exceeded the Time Limit!!!",0
    NullString          db      0
    HintDlgBox          db      "HINTDLGBOX",0
    
    ToolTip1            db      "Tip 1",0
    
    Rect200             RECT    <0,0,200,200>
    Rect220             RECT    <0,0,220,220>
    RectUpdate          RECT    <15,55,15+220,55+220>
    Seed                dd      89456278h
    
    ErrorOpenBitmap     db      "Error: Could not open bitmap file.",0
    ErrorReadBitmap     db      "Error: Failed reading from bitmap file.",0
    ErrorBitmapSize     db      "Error: The bitmap is not 200x200 pixels",0
    ErrorBitmapInvalid  db      "Error: Bitmap is invalid",0
    
    OFN_Filter          db      "Bitmaps (*.bmp)",0,"*.bmp",0,"All Files (*.*)",0,"*.*",0,0
    HelpName            db      "Slide.chm", 0
    Open                db      "open",0
    

    BitmapOFN           OPENFILENAME    <sizeof OPENFILENAME, NULL, NULL, offset OFN_Filter, \
                                        NULL, NULL, NULL, offset OFN_file, 270, \
                                        NULL, NULL, offset CurrentDir, NULL, OFN_PATHMUSTEXIST + OFN_FILEMUSTEXIST, \
                                        NULL, NULL, NULL, NULL, NULL, NULL>
    
    ToolbarButtons  TBBUTTON <0, MI_OPENBITMAP, TBSTATE_ENABLED, \
                              TBSTYLE_BUTTON, 0, NULL, NULL>
                    TBBUTTON <1, MI_NEWGAME, TBSTATE_ENABLED, \
                              TBSTYLE_BUTTON, 0, NULL, NULL>
                    TBBUTTON <NULL, NULL, NULL, TBSTYLE_SEP, NULL, NULL>
                    TBBUTTON <2, MI_USESTANDARD, TBSTATE_ENABLED or TBSTATE_CHECKED, \
                              TBSTYLE_CHECKGROUP, 0, NULL, NULL>
                    TBBUTTON <3, MI_USENUMBERS, TBSTATE_ENABLED, \
                              TBSTYLE_CHECKGROUP, 0, NULL, NULL>
                    TBBUTTON <4, MI_USEFILE, TBSTATE_ENABLED, \
                              TBSTYLE_CHECKGROUP, 0, NULL, NULL>
                    TBBUTTON <NULL, NULL, NULL, TBSTYLE_SEP, NULL, NULL>
                    TBBUTTON <5, MI_HINT, TBSTATE_ENABLED, \
                              TBSTYLE_BUTTON, 0, NULL, NULL>
                              
    TilePositions   dw  0,0         ; tile 1 , index 0
                    dw  50,0        ; tile 2 , index 1
                    dw  100,0       ; tile 3 , index 2
                    dw  150,0       ; tile 4 , index 3
                    dw  0,50        ; tile 5 , index 4
                    dw  50,50       ; tile 6 , index 5
                    dw  100,50      ; tile 7 , index 6
                    dw  150,50      ; tile 8 , index 7
                    dw  0,100       ; tile 9 , index 8
                    dw  50,100      ; tile 10 , index 9
                    dw  100,100     ; tile 11 , index 10
                    dw  150,100     ; tile 12 , index 11
                    dw  0,150       ; tile 13 , index 12
                    dw  50,150      ; tile 14 , index 13
                    dw  100,150     ; tile 15 , index 14
                    dw  150,150     ; tile 16 , index 15
                    
    

;======================================================
; Name: .data
; Desc: This section contains uninitialized data of your program.
;======================================================

.data?
    hInstance           dd  ?   ; Application instance handle
    hMenu               dd  ?
    hStatic             dd  ?   
    hStatus             dd  ?
    hToolbar            dd  ?
    BackBufferDC        dd  ?
    hBackBuffer         dd  ?
    ImageDC             dd  ?
    hImage              dd  ?
    hBackgroundColor    dd  ?
    hTileColor          dd  ?
    hFont               dd  ?
    TextColor           dd  ?
    CurImageType        dd  ?
    Buffer              db  200 dup (?)
    TileTable           db  16 dup (?)
    CurrentBlankPos     dd  ?
    Difficulty          dd  ?
    MoveLimitEnabled    dd  ?
    TimeLimitEnabled    dd  ?
    DefaultImage        dd  ?
    OFN_file            db  270 dup (?)
    hCombo              dd  ?
    CurrentDir          db  256 dup (?)
    
    LastUM              dd  ?
    LastH               dd  ?
    LastM               dd  ?
    LastS               dd  ?
    
    UserMoves           dd  ?
    StartTime           dd  ?
    MoveLimit           dd  ?
    TimeLimit           dd  ?
    
    hBitmap             dd  ?
    debug               dd  ? 
    
;======================================================
; Desc: Declare constants used by your program
;======================================================

;======================================================
; Name .code
; Desc: Begin the code section
;======================================================
.code
start:
    ; Get module handle and save it
    invoke  GetModuleHandle, NULL
    mov     hInstance, eax
    
    ; Init Common Controls library
    invoke  InitCommonControls
    
    ; Run winmain procedure and exit program
    invoke  WinMain, hInstance, NULL, NULL, SW_SHOWNORMAL
    invoke  ExitProcess, eax

;======================================================
; Name: WinMain
; Desc: Program execution starts here
;======================================================

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hWnd:HWND
    
    mov     wc.cbSize, sizeof WNDCLASSEX
    mov     wc.style, CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, offset WndProc
    mov     wc.cbClsExtra, NULL
    mov     wc.cbWndExtra, NULL
    push    hInstance
    pop     wc.hInstance
    mov     wc.hbrBackground, COLOR_WINDOW
    mov     wc.lpszMenuName, NULL
    mov     wc.lpszClassName, offset ClassName
    invoke  LoadIcon, hInstance, ICON1_BIG
    mov     wc.hIcon, eax
    invoke  LoadIcon, hInstance, ICON2_SMALL
    mov     wc.hIconSm, eax
    invoke  LoadCursor, NULL, IDC_ARROW
    mov     wc.hCursor, eax
    invoke  RegisterClassEx, addr wc
    invoke  LoadMenu, hInstance, MAINMENU
    mov     hMenu, eax
    invoke  CreateWindowEx, NULL, addr ClassName, addr AppName, \
            WS_OVERLAPPEDWINDOW-WS_MAXIMIZEBOX-WS_SIZEBOX, \
            CW_USEDEFAULT, CW_USEDEFAULT, 258, 350, NULL, hMenu, \
            hInst, NULL
    mov     hWnd, eax
    invoke  ShowWindow, hWnd, CmdShow
    invoke  UpdateWindow, hWnd
    .while TRUE
        invoke  GetMessage, addr msg, NULL, 0, 0
        .break  .if (!eax)
            invoke TranslateMessage, addr msg
            invoke DispatchMessage, addr msg
    .endw
    mov     eax, msg.wParam
    
    ret

WinMain endp

;======================================================
; Name: WinProc
; Desc: The main window procedure
;======================================================

WndProc proc    hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    
    mov     eax, uMsg
    .if eax == WM_CREATE
        invoke  GetCurrentDirectory,255,addr CurrentDir
        mov     MoveLimitEnabled, FALSE
        mov     MoveLimit, 0
        mov     TimeLimitEnabled, FALSE
        mov     TimeLimit, 0
        invoke  InitControls, hWnd
        invoke  InitBitmaps, hWnd
        invoke  InitGame, hWnd
        invoke  ProcessMenuItems, hWnd, MI_DIFFICULTYEASY
        invoke  ProcessMenuItems, hWnd, MI_MOVELIMITOFF
        invoke  ProcessMenuItems, hWnd, MI_TIMELIMITOFF
        invoke  ProcessMenuItems, hWnd, MI_USESTANDARD
        invoke  ProcessMenuItems, hWnd, MI_COLORBLUE
        invoke  SetTimer, hWnd, ID_TIMER1, 500, NULL
    .elseif eax == WM_TIMER
        mov     eax, wParam
        .if eax == ID_TIMER1
            invoke  UpdateInfo 
            .if TimeLimitEnabled == TRUE
                invoke  CheckTimeLimit, hWnd
            .endif           
        .endif
    .elseif eax == WM_DRAWITEM
        mov     eax, wParam
        .if eax == CID_STATIC
            push    ebx
            mov     ebx, lParam
            assume  ebx:ptr DRAWITEMSTRUCT
            invoke  DrawProc, hWnd, [ebx].hdc
            assume  ebx:nothing
            pop     ebx
            xor     eax, eax
            inc     eax
        .else
            xor     eax, eax
        .endif
    .elseif eax == WM_COMMAND
        mov     eax, wParam
        shr     ax, 16
        .if ax == 0     ; menu notification
            invoke  ProcessMenuItems, hWnd, wParam
        .endif    
    .elseif eax == WM_LBUTTONDOWN
        mov     eax, lParam
        and     eax, 0ffffh
        mov     ecx, lParam
        shr     ecx, 16
        invoke  ChildWindowFromPoint, hWnd, eax, ecx
        .if     eax == hStatic      ; Clicked in static window
            invoke  ProcessClick, hWnd, lParam
        .endif
    .elseif eax == WM_DESTROY
        invoke  KillTimer, hWnd, ID_TIMER1
        invoke  DeleteBitmaps
        invoke  PostQuitMessage, NULL
    .else
        invoke  DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .endif
    
    ret

WndProc endp

;======================================================
; Name: InitControls
; Desc: Initialize all the controls on the main window
;======================================================

InitControls proc hWnd:DWORD
    LOCAL DefaultFont:DWORD
    
    ; Create a static window for slide:
    invoke  CreateWindowEx, WS_EX_CLIENTEDGE, addr ClassStatic, NULL, \
            WS_VISIBLE + WS_CHILD + SS_OWNERDRAW, \
            15, 55, 220, 220, \
            hWnd, CID_STATIC, hInstance, NULL
    mov     hStatic, eax
    
    ; Create Toolbar
    invoke  CreateToolbarEx, hWnd, WS_CHILD + WS_VISIBLE + TBSTYLE_FLAT + WS_BORDER, \
            CID_TOOLBAR, 6, hInstance, BMP_TOOLBAR, addr ToolbarButtons, \
            8, 32, 32, 32, 32, sizeof TBBUTTON
    mov     hToolbar, eax
    invoke  SendMessage, eax, TB_AUTOSIZE, NULL, NULL
    
    ; Create Status Bar
    invoke  CreateStatusWindow, WS_CHILD + WS_VISIBLE, addr DefaultStatusText, hWnd, CID_STATUS
    mov     hStatus, eax
    invoke  SendMessage, hStatus, SB_SETPARTS, 5, addr StatusParts
    invoke  SendMessage, hStatus, SB_SETTEXT, 0, addr DefaultStatusText
    
    ret

InitControls endp

;======================================================
; Name: InitBitmaps
; Desc: Initialize Bitmaps on the main window
;======================================================

InitBitmaps proc hWnd:DWORD
    
    ; Create DC's for buckbuffer and current image
    invoke  CreateCompatibleDC, NULL
    mov     BackBufferDC, eax
    
    invoke  CreateCompatibleDC, NULL
    mov     ImageDC, eax
    
    ; Create bitmap for backbuffer
    invoke  GetDC, hWnd
    push    eax
    invoke  CreateCompatibleBitmap, eax, 200+20, 200+20
    mov     hBackBuffer, eax
    pop     eax
    invoke  ReleaseDC, hWnd, eax
    invoke  SelectObject, BackBufferDC, hBackBuffer
    
    ; Create Arial Font for the numbers
    invoke  CreateFont, -30, NULL, NULL, NULL, FW_EXTRABOLD, \
            FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, \
            NULL, addr FontFace
    mov     hFont, eax
    
    ; Select font in ImageDC
    invoke  SelectObject, ImageDC, hFont
    
    invoke  CreateSolidBrush, 0FF8000h
    mov     hBackgroundColor, eax
    invoke  CreateSolidBrush, 0FF8080h
    mov     hTileColor, eax
    
    mov     TextColor, 0800000h
    ret

InitBitmaps endp

;======================================================
; Name: DeleteBitmaps
; Desc: Release Bitmaps from memory
;======================================================

DeleteBitmaps proc
    
    invoke  DeleteDC, BackBufferDC
    invoke  DeleteDC, ImageDC
    invoke  DeleteObject, hImage
    invoke  DeleteObject, hBackBuffer
    invoke  DeleteObject, hFont
    invoke  DeleteObject, hBackgroundColor
    invoke  DeleteObject, hTileColor
    
    ret

DeleteBitmaps endp

;======================================================
; Name: SetBitmap
; Desc: Selects the type of image to use for the tiles
;======================================================

SetBitmap proc hWnd:DWORD, ImageType:DWORD
    
    mov     eax, ImageType
    .if eax == IMAGETYPE_NUMBERS
        ; --- delete old image ---
        invoke  DeleteObject, hImage
        ; --- Get DC ---
        invoke  GetDC, hWnd
        push    eax
        ; --- Create new bitmap for the numbers bitmap ---
        invoke  CreateCompatibleBitmap, eax, 200, 200
        mov     hImage, eax
        pop     eax
        ; --- Release DC ---
        invoke  ReleaseDC, hWnd, eax
        ; --- Select new bitmap in DC ---
        invoke  SelectObject, ImageDC, hImage
        ; --- Draw numbers on the bitmap ---
        invoke  DrawNumbers
        ; --- Create the 3D effect on the bitmap ---
        invoke  CreateTiles
    .elseif eax == IMAGETYPE_STANDARD
        ; --- delete old image ---
        invoke  DeleteObject, hImage
        ; --- load bitmap from resource ---
        invoke LoadBitmap, hInstance, BMP_STARTBITMAP
        ; --- save new handle ---
        mov     hImage, eax
        ; --- select new handle in ImageDC ---
        invoke  SelectObject, ImageDC, eax
        ; --- Create the 3D effect on the bitmap ---
        invoke  CreateTiles
    .elseif eax == IMAGETYPE_BITMAP
        invoke  SelectObject, ImageDC, hImage
        invoke  CreateTiles
    .endif
    ; --- Set the new image type ---
    mov     eax, ImageType
    mov     CurImageType, eax
    
    ret

SetBitmap endp

;======================================================
; Name: DrawNumbers
; Desc: Draws an array of numbers on the new bitmap
;======================================================

DrawNumbers proc uses ebx edi
    
    LOCAL TempRect:RECT
    ; --- Set the textcolor of ImageDC to TextColor
    invoke  SetTextColor, ImageDC, TextColor
    ; --- Fill the ImageDC with the tile color brush ---
    invoke  FillRect, ImageDC, addr Rect200, hTileColor
    ; --- Set the background mode to transparent ---
    invoke  SetBkMode, ImageDC, TRANSPARENT
    
    ; --- Loop through all the numbers and draw them one by one ---
    xor ebx, ebx
    .while ebx < 16
        mov     eax, ebx
        inc     eax
        invoke  GetCoordinates, eax
        mov     dx, ax          ; dx = row
        shr     eax, 16         ; ax = column
        and     edx, 0ffffh     ; make sure that edx = dx
        imul    edx, edx, 50    ; } Multiply edx as well as eax with 50
        imul    eax, 50         ; }
        mov     TempRect.left, eax
        mov     TempRect.top, edx
        add     eax, 50
        add     edx, 50
        mov     TempRect.right, eax
        mov     TempRect.bottom, edx
        mov     eax, ebx
        inc     eax
        invoke  wsprintf, addr Buffer, addr NumberFormat, eax
        invoke  DrawText, ImageDC, addr Buffer, -1, addr TempRect, DT_CENTER or DT_SINGLELINE or DT_VCENTER
        inc ebx
    .endw
    
    ret

DrawNumbers endp

;======================================================
; Name: GetCoordinates
; Desc: TBA
;======================================================

GetCoordinates proc dwTile:DWORD
    
    mov     eax, dwTile
    dec     eax
    cdq
    mov     ecx, 4
    div     ecx
    ; eax = quotient = row
    ; edx = remainder = column
    shl     edx, 16
    add     eax, edx
    
    ret

GetCoordinates endp

;======================================================
; Name: CreateTiles
; Desc: TBA
;======================================================

CreateTiles proc uses ebx esi edi
    
    invoke  GetStockObject, BLACK_PEN
    invoke  SelectObject, ImageDC, eax
    
    ; Dark Lines, vertical. x = 50k - 1 (k = 1,2,3,4)
    ; ebx = k
    ; esi = x
    xor     ebx, ebx
    inc     ebx
    ; ebx is 1 now
    
    .while ebx < 5      ; (ebx = 1,2,3,4)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        dec     esi
        invoke  MoveToEx, ImageDC, esi, 0, NULL
        invoke  LineTo, ImageDC, esi, 199
        inc ebx
    .endw
    
    ; Dark Lines, horizontal. y = 50k - 1 (k = 1,2,3,4)
    ; ebx = k
    ; esi = y
    xor     ebx, ebx
    inc     ebx
    ; ebx is 1 now
    
    .while ebx < 5      ; (ebx = 1,2,3,4)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        dec     esi
        invoke  MoveToEx, ImageDC, 0, esi, NULL
        invoke  LineTo, ImageDC, 199, esi
        inc ebx
    .endw
    
    invoke  GetStockObject, WHITE_PEN
    invoke  SelectObject, ImageDC, eax
    
    ; Light Lines, vertical. x = 50k - 1 (k = 0,1,2,3)
    ; ebx = k
    ; esi = x
    xor     ebx, ebx
    
    .while ebx < 4      ; (ebx = 0,1,2,3)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        invoke  MoveToEx, ImageDC, esi, 0, NULL
        invoke  LineTo, ImageDC, esi, 199
        inc ebx
    .endw
    
    ; Light Lines, horizontal. y = 50k - 1 (k = 0,1,2,3)
    ; ebx = k
    ; esi = y
    xor     ebx, ebx
    
    .while ebx < 4      ; (ebx = 0,1,2,3)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        invoke  MoveToEx, ImageDC, 0, esi, NULL
        invoke  LineTo, ImageDC, 199, esi
        inc ebx
    .endw
    
    ret

CreateTiles endp

;======================================================
; Name: DrawProc
; Desc: Draw the numbers
;======================================================

DrawProc proc uses ebx edi esi hWnd:DWORD, hDC:DWORD
    
    ; Blank the backbuffer with the background colour brush
    invoke FillRect, BackBufferDC, addr Rect220, hBackgroundColor
    
    ; Loop:
    xor     ebx, ebx
    .while ebx < 16
        ; Get the tile that is at tilepos ebx
        xor     ecx, ecx
        mov     cl, byte ptr [offset TileTable + ebx]
        .if ecx == NULL  ; tile = 0 means blank space
            jmp     @blankspace_skip
        .endif
        dec     ecx         ; decrease number (tables are 0-based, tile number 1-based)
        
        ; Get the coordinates of that tile
        shl     ecx, 2      ; multiply tilenr-1 by 4
        mov     eax, dword ptr [offset TilePositions + ecx]
        
        ; The high word of eax is the x coordinate, the low word the y coordinate
        
        mov     cx, ax      ; ecx = source y
        shr     eax, 16     ; eax = source x
        
        ; Get coordinates of tile pos ebx
        mov     edx, ebx
        shl     edx, 2
        mov     edx, dword ptr [offset TilePositions + edx]
        
        xor     edi, edi
        mov     di, dx      ; edi = destination y
        shr     edx, 16     ; edx = destination x
        
        add     edx, 9      ; margin (vertical)
        add     edi, 9      ; margin (horizontal)
        
        invoke  BitBlt, BackBufferDC, edi, edx, 50, 50, ImageDC, ecx, eax, SRCCOPY
        
        @blankspace_skip:
        inc     ebx
    .endw
    
    ; Copy the backbuffer onto the control
    invoke  BitBlt, hDC, 0, 0, 220, 220, BackBufferDC, 0, 0, SRCCOPY
 
    ret

DrawProc endp

;======================================================
; Name: InitGame
; Desc: TBA
;======================================================

InitGame proc hWnd:DWORD
    
    mov     eax, offset TileTable
    mov     dword ptr [eax],     04030201h
    mov     dword ptr [eax+04h], 08070605h
    mov     dword ptr [eax+08h], 0C0B0A09h
    mov     dword ptr [eax+0Ch], 100F0E0Dh
    ;invoke  SetBitmap, hWnd, IMAGETYPE_NUMBERS
    
    ret

InitGame endp

;======================================================
; Name: NewGame
; Desc: TBA
;======================================================

NewGame proc hWnd:DWORD
    
    ; Set initial tile positions
    ; not that the last index id 0, this is the blank space
    mov     eax, offset TileTable
    mov     dword ptr [eax],     04030201h
    mov     dword ptr [eax+04h], 08070605h
    mov     dword ptr [eax+08h], 0C0B0A09h
    mov     dword ptr [eax+0Ch], 000F0E0Dh
    
    mov     CurrentBlankPos, 16
    mov     UserMoves, 0
    mov     StartTime, -1
    mov     LastUM, -1
    mov     LastH, -1
    mov     LastM, -1
    mov     LastS, -1
    invoke  ShuffleTiles
    invoke  InvalidateRect, hWnd, NULL, FALSE
    
    ret

NewGame endp

;======================================================
; Name: ProcessClick
; Desc: TBA
;======================================================

ProcessClick proc uses ebx hWnd:DWORD, Pos:DWORD
    
    LOCAL TempRect:RECT
    LOCAL DestPoint:POINT
    LOCAL TileCoords:POINT
    
    ; --- get the border width of the static control ---
    invoke  GetClientRect, hStatic, addr TempRect
    mov     eax, TempRect.bottom
    mov     edx, 220
    sub     edx, eax
    shr     edx, 1      ; edx contains the border width now
    
    ; --- extract the X and Y coordinates for Pos
    mov     eax, Pos
    mov     ecx, Pos
    shr     ecx, 16     ; ecx = Y (high word of pos)
    and     eax, 0ffffh ; eax = X (low word of pos)
    
    ; The static control is at (15, 55, 220, 220). The X and Y coordinates
    ; (eax and ecx) are relative to the main window, not the static control.
    ; First, the coordinates of the control are subtracted from X and Y
    ; (eax=eax-15, ecx=ecx-55), then the border width (edx) of the control has to
    ; be subtracted from X and T(eax=eax-edx, ecx=ecx-edx)
    
    sub     eax, 15
    sub     ecx, 55
    sub     eax, edx
    sub     ecx, edx
    
    ; The left and top margin is 9 pixels
    ; check if clicked on one of the tiles
    ; this is true id 9<(200+9) and 9<(200+9)
    .if     eax > 8 && eax < 50*4+9
        .if ecx > 8 && ecx < 50*4+9
            ; Get coordinates of tile clicked on (coordinates 0,1,2,3)
            sub     eax, 9
            sub     ecx, 9
            mov     ebx, 50
            cdq
            div     ebx
            mov     TileCoords.x, eax
            mov     eax, ecx
            cdq
            div     ebx
            mov     TileCoords.y, eax
            ; Coordinates are now in TileCoords
            
            ; now look if it can be moved:
            xor     ebx, ebx
            .while  ebx < 4 ; til_above, left, ect
                invoke  GetPosOf, addr TileCoords, addr DestPoint, ebx
                invoke  GetTile, addr DestPoint
                .if     eax != NULL
                    dec     eax
                    mov     edx, eax
                    mov     cl, byte ptr [offset TileTable + eax]
                    
                    ; cl = tile at that pos
                    .if     cl == NULL
                        push    edx
                        invoke  GetTile, addr TileCoords
                        mov     ecx, eax
                        dec     ecx
                        mov     al, byte ptr [offset TileTable + ecx]
                        mov     byte ptr [offset TileTable + ecx], 0
                        pop     edx
                        mov     byte ptr [offset TileTable + edx], al
                        inc     UserMoves
                        .if     UserMoves == 1
                            invoke  GetTickCount
                            mov     StartTime, eax
                        .endif
                        invoke  UpdateInfo
                        .break
                    .endif
                .endif
                inc ebx    
            .endw
        .endif
    .endif
    
    
    invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE
    invoke  CheckIfSolved, hWnd
    .if MoveLimitEnabled == TRUE
        invoke  CheckMoveLimit, hWnd    
    .endif
   
    
    ret

ProcessClick endp

;======================================================
; Name: GetPosOf
; Desc: TBA
;======================================================

GetPosOf proc lpPoint:DWORD, lpPointDest:DWORD, dwType:DWORD
    
    mov     edx, lpPoint
    mov     ecx, lpPointDest
    assume  edx:ptr POINT
    assume  ecx:ptr POINT
    push    [edx].x
    push    [edx].y
    pop     [ecx].y
    pop     [ecx].x
    
    .if     dwType == TILE_ABOVE
        dec [ecx].y
    .elseif dwType == TILE_BELOW
        inc [ecx].y
    .elseif dwType == TILE_LEFT
        dec [ecx].x
    .elseif dwType == TILE_RIGHT
        inc [ecx].x
    .endif
    assume  edx:nothing
    assume  ecx:nothing
    
    ret

GetPosOf endp

;======================================================
; Name: GetTile
; Desc: TBA
;======================================================

GetTile proc lpPoint:DWORD
    
    mov     eax, lpPoint
    assume  eax:ptr POINT
    mov     ecx, [eax].x
    cmp     ecx, 3
    jg      gt_invalid
    cmp     ecx, 0
    jl      gt_invalid
    mov     edx, [eax].y
    cmp     edx, 3
    jg      gt_invalid
    cmp     edx, 0
    jl      gt_invalid
    shl     edx, 2  ; multiply by 4
    add     edx, ecx
    assume  eax:nothing
    mov     eax, edx
    inc     eax
    ret
    
    gt_invalid:
    xor     eax, eax
    ret

GetTile endp

;======================================================
; Name: ProcessMenuItems
; Desc: TBA
;======================================================

ProcessMenuItems proc hWnd:DWORD, wParam:DWORD
   
    mov     eax, wParam
    ; ---------------------------------
    ; Difficulty
    ; ---------------------------------
    .if ax == MI_DIFFICULTYEASY
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYEASY, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYMEDIUM, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYHARD, MF_UNCHECKED
        mov     Difficulty, EASY
        invoke  NewGame, hWnd
        invoke  InitGame, hWnd
        .if MoveLimitEnabled == TRUE
            mov MoveLimit, EASY_MOVELIMIT
        .endif
        .if TimeLimitEnabled == TRUE
            mov TimeLimit, EASY_TIMELIMIT
        .endif
    .elseif ax == MI_DIFFICULTYMEDIUM
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYEASY, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYMEDIUM, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYHARD, MF_UNCHECKED
        mov     Difficulty, MEDIUM
        invoke  NewGame, hWnd
        invoke  InitGame, hWnd
        .if MoveLimitEnabled == TRUE
            mov MoveLimit, MEDIUM_MOVELIMIT
        .endif
        .if TimeLimitEnabled == TRUE
            mov TimeLimit, MEDIUM_TIMELIMIT
        .endif
    .elseif ax == MI_DIFFICULTYHARD
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYEASY, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYMEDIUM, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_DIFFICULTYHARD, MF_CHECKED
        mov     Difficulty, HARD
        invoke  NewGame, hWnd
        invoke  InitGame, hWnd
        .if MoveLimitEnabled == TRUE
            mov MoveLimit, HARD_MOVELIMIT
        .endif
        .if TimeLimitEnabled == TRUE
            mov TimeLimit, HARD_TIMELIMIT
        .endif
    ; ---------------------------------
    ; Move Limit
    ; ---------------------------------
    .elseif ax == MI_MOVELIMITON
        invoke  CheckMenuItem, hMenu, MI_MOVELIMITON, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_MOVELIMITOFF, MF_UNCHECKED
        invoke  NewGame, hWnd
        invoke  InitGame, hWnd
        mov     MoveLimitEnabled, TRUE
        mov     eax, Difficulty
        .if eax == EASY
            mov MoveLimit, EASY_MOVELIMIT
        .elseif eax == MEDIUM
            mov MoveLimit, MEDIUM_MOVELIMIT
        .elseif eax == HARD
            mov MoveLimit, HARD_MOVELIMIT
        .endif
        invoke  SendMessage, hStatus, SB_SETTEXT, 3, addr MoveStatusText       
    .elseif ax == MI_MOVELIMITOFF
        invoke  CheckMenuItem, hMenu, MI_MOVELIMITON, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_MOVELIMITOFF, MF_CHECKED
        mov     MoveLimitEnabled, FALSE
        mov     MoveLimit, 0
        invoke  SendMessage, hStatus, SB_SETTEXT, 3, NULL 
    ; ---------------------------------
    ; Time Limit
    ; ---------------------------------
    .elseif ax == MI_TIMELIMITON
        invoke  CheckMenuItem, hMenu, MI_TIMELIMITON, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_TIMELIMITOFF, MF_UNCHECKED
        invoke  NewGame, hWnd
        invoke  InitGame, hWnd
        mov     TimeLimitEnabled, TRUE        
        mov     eax, Difficulty
        .if eax == EASY
            mov TimeLimit, EASY_TIMELIMIT
        .elseif eax == MEDIUM
            mov TimeLimit, MEDIUM_TIMELIMIT
        .elseif eax == HARD
            mov TimeLimit, HARD_TIMELIMIT
        .endif
        invoke  SendMessage, hStatus, SB_SETTEXT, 4, addr TimeStatusText
     .elseif ax == MI_TIMELIMITOFF
        invoke  CheckMenuItem, hMenu, MI_TIMELIMITON, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_TIMELIMITOFF, MF_CHECKED
        mov     TimeLimitEnabled, FALSE
        mov     TimeLimit, 0
        invoke  SendMessage, hStatus, SB_SETTEXT, 4, NULL
    ; ---------------------------------
    ; Image Type
    ; ---------------------------------
    .elseif ax == MI_USEFILE
        invoke  CheckMenuItem, hMenu, MI_USEFILE, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_USENUMBERS, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_USESTANDARD, MF_UNCHECKED
        invoke  SendMessage, hToolbar, TB_CHECKBUTTON, MI_USEFILE, TRUE
        mov     eax, offset OFN_file
        mov     al, byte ptr [eax]
        .if al == NULL
            invoke  GetOpenFileName, addr BitmapOFN
        .endif
        .if eax != NULL
            invoke  OpenBitmap, hWnd
            invoke  SetBitmap, hWnd, IMAGETYPE_BITMAP
            invoke  InvalidateRect, hWnd, NULL, FALSE
        .endif
    .elseif ax == MI_USENUMBERS
        invoke  CheckMenuItem, hMenu, MI_USEFILE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_USENUMBERS, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_USESTANDARD, MF_UNCHECKED
        invoke  SendMessage, hToolbar, TB_CHECKBUTTON, MI_USENUMBERS, TRUE
        invoke  SetBitmap, hWnd, IMAGETYPE_NUMBERS
        invoke  InvalidateRect, hWnd, NULL, FALSE
    .elseif ax == MI_USESTANDARD
        invoke  CheckMenuItem, hMenu, MI_USEFILE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_USENUMBERS, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_USESTANDARD, MF_CHECKED
        invoke  SendMessage, hToolbar, TB_CHECKBUTTON, MI_USESTANDARD, TRUE
        invoke  SetBitmap, hWnd, IMAGETYPE_STANDARD
        invoke  InvalidateRect, hWnd, NULL, FALSE
    ; ---------------------------------
    ; Colour Scheme
    ; ---------------------------------
    .elseif ax == MI_COLORRED
        invoke SetColors, eax
        invoke  CheckMenuItem, hMenu, MI_COLORRED, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLACK, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORWHITE, MF_UNCHECKED
        invoke  SetBitmap, hWnd, CurImageType
        invoke  InvalidateRect, hWnd, NULL, FALSE
    .elseif ax == MI_COLORBLUE
        invoke SetColors, eax
        invoke  CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLUE, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLACK, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORWHITE, MF_UNCHECKED
        invoke  SetBitmap, hWnd, CurImageType
        invoke  InvalidateRect, hWnd, NULL, FALSE
    .elseif ax == MI_COLORGREEN
        invoke SetColors, eax
        invoke  CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORGREEN, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLACK, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORWHITE, MF_UNCHECKED
        invoke  SetBitmap, hWnd, CurImageType
        invoke  InvalidateRect, hWnd, NULL, FALSE
    .elseif ax == MI_COLORBLACK
        invoke SetColors, eax
        invoke  CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLACK, MF_CHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORWHITE, MF_UNCHECKED
        invoke  SetBitmap, hWnd, CurImageType
        invoke  InvalidateRect, hWnd, NULL, FALSE
    .elseif ax == MI_COLORWHITE
        invoke SetColors, eax
        invoke  CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORBLACK, MF_UNCHECKED
        invoke  CheckMenuItem, hMenu, MI_COLORWHITE, MF_CHECKED
        invoke  SetBitmap, hWnd, CurImageType
        invoke  InvalidateRect, hWnd, NULL, FALSE
    ; ---------------------------------
    ; New Game
    ; ---------------------------------
    .elseif ax == MI_NEWGAME
        invoke  NewGame, hWnd
    ; ---------------------------------
    ; Open Bitmap
    ; ---------------------------------
    .elseif ax == MI_OPENBITMAP
        invoke  GetOpenFileName, addr BitmapOFN
        .if eax != NULL
            invoke  ProcessMenuItems, hWnd, MI_USEFILE
        .endif
    ; ---------------------------------
    ; Help
    ; ---------------------------------
    .elseif ax == MI_HELP
        invoke  SetCurrentDirectory, addr CurrentDir
        invoke  ShellExecute,hWnd,NULL,addr HelpName,NULL,NULL,SW_SHOWNORMAL
    ; ---------------------------------
    ; About
    ; ---------------------------------
    .elseif ax == MI_ABOUT
        invoke  DialogBoxParam, hInstance, ID_ABOUTDIALOG, hWnd, offset DlgProc, NULL
    ; ---------------------------------
    ; Preview
    ; ---------------------------------
    .elseif ax == MI_HINT
        invoke  DialogBoxParam, hInstance, IDD_PREVIEWDIALOG, hWnd, offset PreviewDlgProc, NULL
    .endif
    
    ret

ProcessMenuItems endp

;======================================================
; Name: SetColors
; Desc: TBA
;======================================================

SetColors proc uses ebx cType:DWORD
    
    invoke  DeleteObject, hBackgroundColor
    invoke  DeleteObject, hTileColor
    
    ; ebx = background
    ; edx = text
    ; eax = tile
    mov     eax, cType
    .if ax == MI_COLORRED
        mov     eax, 00000A0h
        mov     edx, 00000FFh
        mov     ebx, 05050E0h
    .elseif ax == MI_COLORBLUE
        mov     eax, 0FF8080h
        mov     edx, 0800000h
        mov     ebx, 0FF8000h     
    .elseif ax == MI_COLORGREEN
        mov     eax, 000A000h
        mov     edx, 000FF00h
        mov     ebx, 050E050h 
    .elseif ax == MI_COLORBLACK
        mov     eax, 0909090h
        mov     edx, 0FFFFFFh
        mov     ebx, 0000000h
    .elseif ax == MI_COLORWHITE
        mov     eax, 0AAAAAAh
        mov     edx, 0000000h
        mov     ebx, 0FFFFFFh         
    .endif
    mov     TextColor, edx
    
    invoke  CreateSolidBrush, eax
    mov     hTileColor, eax
    
    invoke  CreateSolidBrush, ebx
    mov     hBackgroundColor, eax
    ret

SetColors endp

;======================================================
; Name: CheckIfValidBitmap
; Desc: TBA
;======================================================

CheckIfValidBitmap proc     uses edi    hWnd:DWORD, pMem:DWORD, FileSize:DWORD
    
    mov     edi, pMem
    mov     ax, word ptr [edi]
    .if ax != "MB"
        xor     eax, eax
        ret
    .endif
    
    mov     eax, dword ptr [edi+2]
    .if eax != FileSize
        xor     eax, eax
        ret
    .endif
    
    mov     eax, dword ptr [edi+0Eh]
    .if eax != 28h
        xor     eax, eax
        ret
    .endif
    
    mov     eax, dword ptr [edi+12h]
    mov     ecx, dword ptr [edi+16h]
    .if eax != 200 || ecx != 200
        mov     eax, 2
        ret
    .endif
    
    xor     eax, eax
    inc     eax
    
    ret

CheckIfValidBitmap endp

;======================================================
; Name: OpenBitmap
; Desc: TBA
;======================================================

OpenBitmap proc     uses edi esi    hWnd:DWORD
    
    LOCAL   hFile:DWORD
    LOCAL   FileSize:DWORD
    LOCAL   hMem:DWORD
    LOCAL   pMem:DWORD
    LOCAL   BytesRead:DWORD
    
    invoke  DeleteObject, hImage
    invoke  SetCurrentDirectory, addr CurrentDir
    invoke  CreateFile, addr OFN_file, GENERIC_READ, FILE_SHARE_READ,\
            NULL, OPEN_EXISTING, NULL, NULL
    .if eax == INVALID_HANDLE_VALUE
        invoke  MessageBox, NULL, addr ErrorOpenBitmap, addr AppName, MB_OK
        invoke  ProcessMenuItems, hWnd, MI_USESTANDARD  ; fake menu press
        ret
    .endif
    
    mov     hFile, eax
    
    invoke  GetFileSize, hFile, NULL
    mov     FileSize, eax
    
    invoke  GlobalAlloc, GMEM_MOVEABLE, eax
    mov     hMem, eax
    invoke  GlobalLock, eax
    mov     pMem, eax
    
    invoke  ReadFile, hFile, pMem, FileSize, addr BytesRead, NULL
    
    mov     ecx, FileSize
    .if BytesRead != ecx || eax == NULL
        invoke  MessageBox, NULL, addr ErrorReadBitmap, addr AppName, MB_OK
        invoke  ProcessMenuItems, hWnd, MI_USESTANDARD
        jmp     @ob_exit1
    .endif
    
    invoke  CheckIfValidBitmap, hWnd, pMem, FileSize
    .if eax == NULL
        invoke  MessageBox, NULL, addr ErrorBitmapInvalid, addr AppName, MB_OK
        invoke  ProcessMenuItems, hWnd, MI_USESTANDARD
    .elseif eax == 1
        mov     ecx, pMem
        mov     edx, ecx
        mov     edx, dword ptr [edx + 0Ah]
        add     edx, ecx
        add     ecx, 0Eh    ; Bitmapheader
        
        invoke  CreateDIBitmap, ImageDC, ecx, CBM_INIT, \
                edx, ecx, DIB_RGB_COLORS
        mov     hImage, eax
    .elseif eax == 2
        invoke  MessageBox, NULL, addr ErrorBitmapSize, addr AppName, MB_OK
        mov     eax, offset OFN_file
        mov     byte ptr [eax], 0
        invoke  ProcessMenuItems, hWnd, MI_USESTANDARD
    .endif
    
@ob_exit1:
    invoke  GlobalUnlock, hMem
    invoke  GlobalFree, hMem
    invoke  CloseHandle, hFile
    
    ret

OpenBitmap endp

;======================================================
; Name: GetRandomNumber
; Desc: TBA
;======================================================

GetRandomNumber proc    uses edx ecx ebx
    
    mov     eax, Seed
    mov     edx, 84054842h
    mul     edx
    inc     eax
    push    eax
    invoke  GetTickCount
    mov     ebx, eax
    invoke  GetTickCount
    bswap   eax
    mov     ecx, eax
    pop     eax
    add     eax, ecx
    mov     Seed, eax
    add     Seed, ebx
    
    ret

GetRandomNumber endp

;======================================================
; Name: ShuffleTiles
; Desc: TBA
;======================================================

ShuffleTiles proc   uses ebx
    LOCAL   CurrentBlankTile:DWORD
    LOCAL   TempPoint:POINT
    LOCAL   NumOfShuffles:DWORD
    LOCAL   LastBlankTile:DWORD
    
    invoke  GetTickCount            ; Get a new seed from the system timer
    add     Seed, eax
    
    mov     CurrentBlankTile, 16    ; Reset the blank to pos 16
    mov     LastBlankTile, 0        ; will hold the last position of the blank tile
    mov     NumOfShuffles, 0        ; Number of shuffles
    
@st_try_again:
    ; Get Coordinates (column and row) of the tile and extract X and Y
    invoke GetCoordinates, CurrentBlankTile
    mov     ecx, eax
    mov     edx, eax
    and     edx, 0ffffh ; edx = x
    shr     ecx, 16     ; ecx = y
    
    invoke  GetRandomNumber
    
    ; Based on the value of the lowest byte of the random number, 
    ; the row or column is decreased or increased by one.
    .if al < 40h
        dec ecx
    .elseif al >= 40h && al < 80h
        inc edx
    .elseif al >= 80h && al < 0C0h
        inc ecx
    .else
        dec edx
    .endif
    
    ; Store the new row & column values in a POINT structure and get
    ; the tilenumber at that position
    mov     TempPoint.x, ecx
    mov     TempPoint.y, edx
    invoke  GetTile, addr TempPoint
    
    .if eax == NULL
        jmp @st_try_again
    .endif
    
    .if LastBlankTile == eax
        jmp @st_try_again
    .endif
    inc     NumOfShuffles
    
    mov     LastBlankTile, eax
    
    ; Get the numbers of the two tiles that have to be swapped in eax and ecx
    mov     ecx, CurrentBlankTile
    mov     CurrentBlankTile, eax
    
    ; Decrease both to get an index
    dec     eax
    dec     ecx
    
    ; Swap the tiles
    mov     bl, byte ptr [offset TileTable + eax]
    mov     byte ptr [offset TileTable + eax], 0
    mov     byte ptr [offset TileTable + ecx], bl
    
    mov     eax, Difficulty
    .if NumOfShuffles < eax
        jmp @st_try_again
    .endif

    ret
ShuffleTiles endp

;======================================================
; Name: CheckIfSolved
; Desc: TBA
;======================================================

CheckIfSolved proc  uses ebx    hWnd:DWORD
    
    LOCAL hours:DWORD
    LOCAL minutes:DWORD
    LOCAL seconds:DWORD
    
    mov     eax, offset TileTable
    .if     dword ptr [eax] == 04030201h
        .if     dword ptr [eax+4] == 08070605h
            .if     dword ptr [eax+8] == 0C0B0A09h
                .if     dword ptr [eax+0Ch] == 000F0E0Dh
                    mov     dword ptr [eax+0Ch], 100F0E0Dh
                    ; Get Time
                    invoke  GetTickCount
                    sub     eax, StartTime
                    
                    mov     ecx, 1000
                    cdq
                    div     ecx
                    ; eax is number of seconds
                    mov     ecx, 3600
                    cdq
                    div     ecx
                    ; eax is number of hours, edx is remainder (remaining number of seconds)
                    mov     hours, eax
        
                    mov     eax, edx
                    mov     ecx, 60
                    cdq
                    div     ecx
                    ; eax is number of minutes, edx is remaining number of seconds
                    mov     minutes, eax
                    mov     seconds, edx
                    
                    mov     StartTime, -1
                    mov     ebx, UserMoves
                    mov     UserMoves, 0
                    
                    invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE
                    invoke  wsprintf, addr Buffer, addr SolvedFormat, \
                             hours, minutes, seconds, ebx
                    invoke  MessageBox, NULL, addr Buffer, addr AppName, MB_OK + MB_ICONEXCLAMATION
                .endif
            .endif
        .endif
    .endif 
    
    ret

CheckIfSolved endp

;======================================================
; Name: UpdateInfo
; Desc: TBA
;======================================================

UpdateInfo proc     uses ebx edi esi
    LOCAL   hours:DWORD
    LOCAL   minutes:DWORD
    LOCAL   seconds:DWORD
    
    .if StartTime == -1 || UserMoves == 0
        invoke  SendMessage, hStatus, SB_SETTEXT, 1, addr NullString
        invoke  SendMessage, hStatus, SB_SETTEXT, 2, addr NullString
    .else
        mov     eax, UserMoves
        .if eax != LastUM
            .if MoveLimitEnabled == TRUE
                mov     edx, MoveLimit
                sub     edx, eax
                invoke  wsprintf, addr Buffer, addr MovesLimitFormat, edx
                invoke  SendMessage, hStatus, SB_SETTEXT, 1, addr Buffer
            .else
                invoke  wsprintf, addr Buffer, addr MovesFormat, UserMoves
                invoke  SendMessage, hStatus, SB_SETTEXT, 1, addr Buffer
            .endif
        .endif
        
        invoke  GetTickCount
        sub     eax, StartTime
        
        mov     ecx, 1000
        cdq
        div     ecx
        
        .if TimeLimitEnabled == TRUE
            mov ebx, eax
            mov eax, TimeLimit
            sub eax, ebx
        .endif

        ; eax is number of seconds
        mov     ecx, 3600
        cdq
        div     ecx
        ; eax is number of hours, edx is remainder (remaining number of seconds)
        mov     hours, eax
        
        mov     eax, edx
        mov     ecx, 60
        cdq
        div     ecx
        ; eax is number of minutes, edx is remaining number of seconds
        mov     minutes, eax
        mov     seconds, edx
        
        xor     eax, eax
        mov     ecx, LastH
        .if ecx != hours
            inc     eax
        .endif 
        
        mov     ecx, LastM
        .if ecx != minutes
            inc     eax
        .endif
        
        mov     ecx, LastS
        .if ecx != seconds
            inc     eax
        .endif
        
        .if eax != NULL
            invoke  wsprintf, addr Buffer, addr TimeFormat, hours, minutes, seconds
            invoke  SendMessage, hStatus, SB_SETTEXT, 2, addr Buffer 
        .endif       
        
        push    hours
        push    minutes
        push    seconds
        pop     LastS
        pop     LastM
        pop     LastH
        
        push    UserMoves
        pop     LastUM
        
    .endif
    
    ret

UpdateInfo endp

;======================================================
; Name: DlgProc
; Desc: TBA
;======================================================

DlgProc proc hWnd:DWORD, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    
    mov eax, uMsg
    .if eax == WM_COMMAND
        mov     eax, wParam
        shr     eax, 16
        .if ax == BN_CLICKED
            invoke  EndDialog, hWnd, NULL
        .endif
    .elseif eax == WM_DESTROY
        invoke  EndDialog, hWnd, NULL
    .elseif eax == WM_CLOSE
        invoke  EndDialog, hWnd, NULL
    .endif
    
    xor     eax, eax
    ret

DlgProc endp

;======================================================
; Name: PreviewDlgProc
; Desc: TBA
;======================================================

PreviewDlgProc proc hWnd:DWORD, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL ps:PAINTSTRUCT 
    LOCAL hdc:HDC 
    LOCAL hMemDC:HDC 
    LOCAL rect:RECT 

    mov eax, uMsg
    .if eax == WM_INITDIALOG
        ; TBA
    .elseif eax == WM_PAINT
        invoke  BeginPaint, hWnd, addr ps
        mov     hdc, eax
        invoke  CreateCompatibleDC,hdc
        mov     hMemDC,eax         
        invoke  SelectObject, ImageDC, hImage
        invoke  GetClientRect,hWnd,addr rect 
        invoke  BitBlt,hdc,0,0,rect.right,rect.bottom,ImageDC,0,0,SRCCOPY
        invoke  DeleteDC,hMemDC
        invoke  EndPaint,hWnd,addr ps 
    .elseif eax == WM_COMMAND
        mov     eax, wParam
        shr     eax, 16
        .if ax == BN_CLICKED
            invoke  DeleteObject,hBitmap
            invoke  EndDialog, hWnd, NULL
        .endif
    .elseif eax == WM_DESTROY
        invoke  DeleteObject,hBitmap
        invoke  EndDialog, hWnd, NULL
    .elseif eax == WM_CLOSE
        invoke  DeleteObject,hBitmap
        invoke  EndDialog, hWnd, NULL
    .endif
    
    xor     eax, eax
    ret

PreviewDlgProc endp

;======================================================
; Name: CheckMoveLimit
; Desc: TBA
;======================================================

CheckMoveLimit proc hWnd:DWORD   
    
    mov     eax, UserMoves
    .if eax >= MoveLimit
        mov     StartTime, -1
        mov     ebx, UserMoves
        mov     UserMoves, 0
        invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE
        invoke  MessageBox, NULL, addr MoveLimitReached, addr AppName, MB_OK + MB_ICONEXCLAMATION
        mov     eax, offset TileTable
        mov     dword ptr [eax],     04030201h
        mov     dword ptr [eax+04h], 08070605h
        mov     dword ptr [eax+08h], 0C0B0A09h
        mov     dword ptr [eax+0Ch], 100F0E0Dh   
        invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE  
    .endif
    ret

CheckMoveLimit endp

;======================================================
; Name: CheckTimeLimit
; Desc: TBA
;======================================================

CheckTimeLimit proc hWnd:DWORD

    .if StartTime == -1 || UserMoves == 0
        ; Do Nothing
    .else    
        invoke  GetTickCount
        sub     eax, StartTime
        
        mov     ecx, 1000
        cdq
        div     ecx
        ; eax is number of seconds

        .if eax >= TimeLimit
            mov     StartTime, -1
            mov     ebx, UserMoves
            mov     UserMoves, 0
            invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE
            invoke  MessageBox, NULL, addr TimeLimitReached, addr AppName, MB_OK + MB_ICONEXCLAMATION
            mov     eax, offset TileTable
            mov     dword ptr [eax],     04030201h
            mov     dword ptr [eax+04h], 08070605h
            mov     dword ptr [eax+08h], 0C0B0A09h
            mov     dword ptr [eax+0Ch], 100F0E0Dh   
            invoke  InvalidateRect, hWnd, addr RectUpdate, FALSE
        .endif
    
    .endif
    
    ret

CheckTimeLimit endp




end start

