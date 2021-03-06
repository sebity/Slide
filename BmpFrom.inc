BmpFromMemory       PROTO   :DWORD, :DWORD
BmpFromPicture      PROTO   :DWORD
BmpFromResource     PROTO   :DWORD, :DWORD
BitmapFromFile   	PROTO   :DWORD

.data

sIID_IPicture       TEXTEQU <{07BF80980H, 0BF32H, 0101AH,   \
                             {08BH, 0BBH, 000H, 0AAH, 000H, 030H, 00CH, 0ABH}}>
                             
IID_IPicture        GUID    sIID_IPicture

IPicture STRUCT
    ; IUnknown methods
    QueryInterface          DWORD   ?
    AddRef                  DWORD   ?
    Release                 DWORD   ?
    ; IPicture methods
    get_Handle              DWORD   ?
    get_hPal                DWORD   ?
    get_Type                DWORD   ?
    get_Width               DWORD   ?
    get_Height              DWORD   ?
    Render                  DWORD   ?	
    set_hPal                DWORD   ?
    get_CurDC               DWORD   ?
    SelectPicture           DWORD   ?
    get_KeepOriginalFormat  DWORD   ?
    put_KeepOriginalFormat  DWORD   ?
    PictureChanged          DWORD   ?
    SaveAsFile              DWORD   ?
    get_Attributes          DWORD   ?
IPicture ENDS

HIMETRIC_INCH       EQU     2540

szImage             BYTE    "IMAGE", 0

.code
;-------------------------------------------------------------------------------
BmpFromMemory  PROC  pMemory:DWORD, dwFileSize:DWORD

    LOCAL hResource:DWORD,  pGlobal:DWORD,      pStream:DWORD
    LOCAL hImage:DWORD,     pPicture:DWORD,     hBitmap:DWORD

    mov pStream, NULL
    mov pPicture, NULL    ; NULL pointers for later use
    invoke CoTaskMemAlloc, dwFileSize   ; copy picture into task memory
    mov pGlobal, eax
    invoke MemCopy, pMemory, pGlobal, dwFileSize

    ; create a stream for the picture object's creator
    invoke CreateStreamOnHGlobal, pGlobal, TRUE, ADDR pStream
    invoke OleLoadPicture, pStream, NULL, TRUE, ADDR IID_IPicture, ADDR pPicture

    ; now we are ready to get the hBipmap, we farm this out for reuseability
    invoke BmpFromPicture, pPicture
    push eax
    pop eax
    .IF !eax
        ; we didn't get the bitmap
        ; BmpFromPicture called SetLastError for us, so just return
        mov eax, NULL
        ret
    .ENDIF
    mov hBitmap, eax

    ; release the stream
    mov eax, pStream
    push eax
    mov eax, [eax]
    call [eax].IPicture.Release         

    ; release the Picture object
    mov eax, pPicture
    push eax
    mov eax, [eax]
    call [eax].IPicture.Release         

;    invoke CoTaskMemFree, pGlobal   ; free task memory
    mov eax, hBitmap                ; hBitpap is our return value, stuff it

    ret                             ; we're all done

BmpFromMemory    ENDP
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
BmpFromPicture PROC pPicture:DWORD
    LOCAL tempDC:DWORD,  tempBitmap:DWORD,  OldBitmap:DWORD
    LOCAL dwWidth:DWORD, dwHeight:DWORD,    compDC:DWORD
    LOCAL hmWidth:DWORD, hmHeight:DWORD,    neghmHeight:DWORD

    ; check we have an object
    .IF pPicture == 0
        ; whoops, no object passed in
        invoke SetLastError, ERROR_INVALID_PARAMETER
        mov eax, 0
        ret
    .ENDIF
    
    ; get a DC to work with
    invoke GetDC, NULL          ; screen DC
    mov compDC, eax
    invoke CreateCompatibleDC, compDC
    .IF !eax
        ; whoops, didn't get a DC
        ; but at least we had SetLastError called for us
        ret
    .ENDIF
    mov tempDC, eax

    ; read out the width and height of the IPicture object
    ; (IPicture)pPicture::get_Width(*hmWidth)
    lea eax, hmWidth
    push eax
    mov eax, pPicture
    push eax
    mov eax, [eax]
    call [eax].IPicture.get_Width

    ; (IPicture)pPicture::get_Height(*hmHeight)
    lea eax, hmHeight
    push eax
    mov eax, pPicture
    push eax
    mov eax, [eax]
    call [eax].IPicture.get_Height

    ; convert himetric to pixels
    invoke GetDeviceCaps, compDC, LOGPIXELSX
    invoke MulDiv, hmWidth, eax, HIMETRIC_INCH
    mov dwWidth, eax

    invoke GetDeviceCaps, compDC, LOGPIXELSY
    invoke MulDiv, hmHeight, eax, HIMETRIC_INCH
    mov dwHeight, eax
    xor eax, eax
    sub eax, hmHeight
    mov neghmHeight, eax

    invoke CreateCompatibleBitmap, compDC, dwWidth, dwHeight
    .IF !eax
        ; whoops, didn't get a bitmap
        ; but at least we had SetLastError called for us\
        ; clean up the DC
        invoke DeleteDC, tempDC
        ret
    .ENDIF
    mov tempBitmap, eax

    invoke SelectObject, tempDC, tempBitmap
    .IF !eax
        ; whoops, didn't select our bitmap
        ; but at least we had SetLastError called for us
        invoke DeleteDC, tempDC
        invoke DeleteObject, tempBitmap
        ret
    .ENDIF
    mov OldBitmap, eax

    ; ok, now we have our bitmap mounted onto our temporary DC, let's blit to it
    ; (IPicture)pPicture::Render(hdc, x, y, cx, cy,                            \
    ;                            xpos_himetric, ypos_himetric,                 \
    ;                            xsize_himetric, ysize_himetric, *rectBounds)
    push NULL   ; *rectBounds
    push neghmHeight
    push hmWidth
    push hmHeight
    push 0
    push dwHeight
    push dwWidth
    push 0
    push 0 
    push tempDC
    mov eax, pPicture
    push eax
    mov eax, [eax]
    call [eax].IPicture.Render
    test eax, eax
    .IF SIGN?
        ; the call failed!
        push eax
        ; do some clean up first
        invoke DeleteDC, tempDC
        invoke DeleteObject, tempBitmap
        pop eax
        ; need to parse out the return fail value
        .IF eax == E_FAIL
        .ELSEIF eax == E_INVALIDARG
        .ELSEIF eax == E_OUTOFMEMORY
        .ELSEIF eax == E_POINTER 
        .ELSE
        .ENDIF    
        invoke SetLastError, eax
        mov eax, 0
        ret
    .ENDIF

    ; we now have the bitmap blitted, let's get it off the dc and clean up.
    ; we're not going to check for errors, cause we did our importaint thing
    ; and if these fail now, other things will fall apart anyway
    invoke SelectObject, tempDC, OldBitmap
    invoke DeleteDC, tempDC
    invoke ReleaseDC,NULL,compDC

    mov eax, tempBitmap     ; the bitmap handle is the return value
    ret                     ; we're all done

BmpFromPicture ENDP                

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
BmpFromResource  PROC hModule: dword, ResNumber:DWORD
    LOCAL hResource:DWORD,  dwFileSize:DWORD, hImage:DWORD

    ; get a resource handle (address) and resource length from the executable
    invoke FindResource, NULL, ResNumber, ADDR szImage
    mov hResource, eax
    invoke LoadResource, NULL, eax
    invoke LockResource, eax
    mov hImage, eax
    invoke SizeofResource, NULL, hResource
    mov dwFileSize, eax
    .IF dwFileSize      ; we use the resource size to determine if we got a
                        ; legit image file to open
        invoke BmpFromMemory, hImage, dwFileSize
    .ELSE
        invoke SetLastError, ERROR_FILE_NOT_FOUND
        mov eax, NULL
    .ENDIF

    ; everything's been done for us now, just return
    ret                     ; we're all done

BmpFromResource  ENDP    
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
BitmapFromFile PROC public pszFileName:DWORD
    LOCAL pwszFileName:DWORD, dwLength:DWORD, pPicture:DWORD, hNewBmp:DWORD

    invoke CoInitialize, NULL
    mov pPicture, NULL    ; NULL pointer for later use

    ; first, we need the filename in Unicode
    invoke lstrlen, pszFileName
    mov dwLength, eax
    inc dwLength
    rol eax, 1      ; double eax
    add eax, 2      ; allow for trailing zero
    invoke CoTaskMemAlloc, eax
    .IF !eax
        ; we didn't get the memory
        invoke SetLastError, ERROR_NOT_ENOUGH_MEMORY
        mov eax, NULL
        ret
    .ENDIF
    mov pwszFileName, eax

    invoke MultiByteToWideChar, CP_ACP, 0, pszFileName, -1, pwszFileName, dwLength
    ; now we can create out picture object
    invoke OleLoadPicturePath, pwszFileName, NULL, NULL, NULL, ADDR IID_IPicture, ADDR pPicture
    .IF  eax > 80000000H  ; hresult failed
        ; we didn't get the file to open, assume bad filename
        invoke SetLastError, ERROR_FILE_NOT_FOUND
        mov eax, NULL
        ret
    .ENDIF

    ; now we are ready to get the hBipmap, we farm this out for reuseability
    invoke BitmapFromPicture, pPicture
    mov hNewBmp, eax
    invoke CoUninitialize           ; all done with COM
    .IF !hNewBmp
        ; we didn't get the bitmap
        ; BitmapFromPicture called SetLastError for us, so just return
        mov eax, NULL
        ret
    .ENDIF

    ; release the Picture object
    mov eax, pPicture
    push eax
    mov eax, [eax]
    call [eax].IPicture.Release         

    mov eax, hNewBmp    ; hBitpap is our return value, stuff it

    ret                 ; we're all done

BitmapFromFile ENDP                
;-------------------------------------------------------------------------------
