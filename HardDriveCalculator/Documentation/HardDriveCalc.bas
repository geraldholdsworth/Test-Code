DIM code% &1000
MyLog2SectorSize=9
Min_IdLen=MyLog2SectorSize + 3:REM min allowed idlen = log2(bits in a sector)
Max_IdLen=21:REM max allowed idlen
Min_Log2bpmb=7:REM min allowed bytes per map bit
Max_Log2bpmb=12:REM max allowed bytes per map bit
Min_ZoneSpare=32:REM min allowed zonespare
Max_ZoneSpare=64:REM max allowed zonespare
Min_Zones=1:REM min allowed zones
Max_Zones=127:REM max allowed zones
DiscRecord_Log2SectorSize=0
DiscRecord_IdLen=&04
DiscRecord_Log2bpmb=&05
DiscRecord_NZones=&09
DiscRecord_ZoneSpare=&0A
DiscRecord_Root=&0C
DiscRecord_DiscSize=&10
DiscRecord_BigMap_NZones2=&2A
DiscRecord_BigDir_DiscVersion=&2C
NewDirSize=&500
BigDirMinSize=&800
Zone0Bits=60*8
P%=code%
[
SkeletonDiscRec  ; fields marked * need filling in
 DCB MyLog2SectorSize ; Log2SectorSize
 DCB 128 ; SecPerTrk (this is a RAM disc)
 DCB 1 ; Heads
 DCB 0 ; Density
 DCB 0 ; * IdLen
 DCB 0 ; * Log2bpmb
 DCB 0 ; Skew
 DCB 0 ; BootOpt
 DCB 0 ; LowSector
 DCB 0 ; * NZones
 DCW 0 ; * ZoneSpare
 DCD 0 ; * Root
 DCD 0 ; * DiscSize
 DCW 0 ; DiscId
 DCB "RamDisc0",0,0 ; DiscName (padded to 10 bytes)
 DCD 0 ; DiscType
 DCD 0 ; DiscSize2
 DCB 0 ; ShareSize
 DCB 0 ; Flags
 DCB 0 ; * NZones2
 DCB 0 ; Reserved
 DCD 0 ; DiscVersion
 DCD 0 ; RootDirSize
 ALIGN
InitDiscRec
        Push "R0-R11,PC"
        LDR     r5, #SkeletonDiscRec
        MOV     r0, #Min_Log2bpmb                ; init log2bpmb
bpmbloop      ; loop on log2bpmb
        LDR     r4, [r5, #DiscRecord_DiscSize]
        MOV     r4, r4, LSR r0                  ; map bits for disc
        MOV     r1, #Min_ZoneSpare              ; init ZoneSpare
zonespareloop      ; loop on zonespare
        LDR     lr, [r5, #DiscRecord_Log2SectorSize]
        MOV     r6, #8
        MOV     r6, r6, LSL lr                  ; bits in a zone
        SUB     r6, r6, r1                      ; minus sparebits
        ; choose number of zones to suit
        MOV     r2, #Min_Zones                  ; minimum of one zone
        SUB     r7, r6, #Zone0Bits              ; bits in zone 0
zoneloop      ; loop for zones
        CMP     r7, r4                          ; do we have enough allocation bits yet?
        BHS     idlenentry                           ; if we do, then accept this number of zones
        ADD     r7, r7, r6                      ; more map bits
        ADD     r2, r2, #1                      ; and another zone
        CMPS    r2, #Max_Zones
        BLS     zoneloop                           ; still ok
        ; here when too many zones; try a higher Log2bpmb
        B       incbpmb
idlenentry
        ; now we have to choose idlen.  we want idlen to be
        ; the smallest it can be for the disc.
        MOV     r3, #Min_IdLen                  ; minimum value of idlen
idlenloop      ; loop for IdLen
        Push    "R0, R1, R2"
        MOV     r0, r6                          ; allocation bits in a zone
        ADD     r1, r3, #1                      ; idlen+1
        DivRem  r8, r0, r1, r2, norem
        Pull    "R0, R1, R2"
        ; check that IdLen is enough for total possible ids
        MOV     r9, #1                          ; work out 1<<idlen
        MOV     r9, r9, LSL r3                  ;
        MUL     lr, r8, r2                      ; total ids needed
        CMPS    lr, r9                          ; idlen too small?
        BHI     incidlen                           ; yes!
        ; we're nearly there.  now work out if the last zone
        ; can be handled correctly.
        SUBS    lr, r7, r4
        BEQ     resultfound
        CMPS    lr, r3                          ; must be at least idlen+1 bits
        BLE     indidlen
        ; check also that we're not too close to the start of the zone
        SUB     lr, r7, r6                      ; get the start of the zone
        SUB     lr, r4, lr                      ; lr = bits available in last zone
        CMPS    lr, r3
        BLE     incidlen
        ; if the last zone is the map zone (ie nzones <= 2), check it's
        ; big enough to hold 2 copies of the map + the root directory
        CMP     r2, #2
        BGT     resultfound
        LDR     r10, [r5, #DiscRecord_Log2SectorSize]
        MOV     r9, #2
        MOV     r10, r9, LSL r10
        MUL     r10, r2, r10                    ; r10 = 2 * map size (in disc bytes)
        MOV     r11, #1
        RSB     r11, r11, r11, LSL r0           ; r11 = LFAU-1 (in disc bytes), for rounding up
        LDR     r9, [r5, #DiscRecord_BigDir_DiscVersion]
        TEQ     r9, #0
        ADDEQ   r10, r10, #NewDirSize           ; short filename: add dir size to map
        BEQ     mapobject
        ; long filename case - root directory is separate object in map zone
        ADD     r9, r11, #BigDirMinSize
        MOV     r9, r9, LSR r0                  ; r9 = directory size (in map bits)
        CMPS    r9, r3
        ADDLE   r9, r3, #1                      ; ensure at least idlen+1
        SUBS    lr, lr, r9
        BLT     incidlen
        ; fall through to consider map object
mapobject      ADD     r10, r10, r11
        MOV     r10, r10, LSR r0                ; r10 = map (+dir) size (in map bits)
        CMPS    r10, r3
        ADDLE   r10, r3, #1                     ; ensure at least idlen+1
        CMPS    lr, r10
        BLT     incidlen
resultfound      ; we've found a result - fill in the disc record!
        STRB    r3,[r5, #DiscRecord_IdLen]      ; => set idlen
        MOV     r1, r1, LSL #16
        AND     lr, r2, #&FF                    ; LSB of nzones
        ORR     r1, r1, lr, LSL #8
        STR     r1, [r5, #DiscRecord_ZoneSpare - 2]  ; => set ZoneSpare and NZones
        MOV     lr, r2, LSR #8                  ; MSB of nzones
        ASSERT  Max_Zones < &10000
        STRB    lr, [r5, #DiscRecord_BigMap_NZones2]
        STRB    r0, [r5, #DiscRecord_Log2bpmb]  ; => set Log2bpmb
        LDR     lr, [r5, #DiscRecord_BigDir_DiscVersion]
        TEQ     lr, #1                          ; do we have long filenames?
        BNE     notlongfn
        ; the root dir's ID is the first available ID in the middle
        ; zone of the map
        MOVS    r2, r2, LSR #1                  ; zones/2
        MULNE   lr, r2, r8                      ; *idsperzone
        MOVEQ   lr, #3                          ; if if zones/2=0, then only one zone, so the id is 3 (0,1,2 reserved)
        MOV     lr, lr, LSL #8                  ; construct full indirect disc address
        ORR     lr, lr, #1                      ; with sharing offset of 1
        B       setroot
notlongfn
        ; not long filenames
        ; root dir is &2nn where nn is ((zones<<1)+1)

        MOV     lr, r2, LSL #1
        ADD     lr, lr, #1
        ADD     lr, lr, #&200
setroot
        STR     lr, [r5, #DiscRecord_Root]      ; => set Root
        ; other fields in the disc record are fixed-value
        B       exit
incidlen      ; NEXT IdLen
        ADD     r3, r3, #1
        CMPS    r3, #Max_IdLen
        BLS     idlenloop
inczonespare      ; NEXT ZoneSpare
        ADD     r1, r1, #1
        CMPS    r1, #Max_ZoneSpare
        BLS     zonespareloop
incbpmb      ; NEXT Log2bpmb
        ADD     r0, r0, #1
        CMPS    r0, #Max_Log2bpmb               ; is it too much?
        BLS     bpmbloop                           ; back around
exit
        Pull    "R0-R11, PC"
]
SkeletonDiscRec!DiscRecord_DiscSize=52125696:REM 50MB Hard disc
CALL InitDiscRec
PRINT "idlen: ";SkeletonDiscRec?DiscRecord_IdLen
PRINT "log2bpmb: ";SkeletonDiscRec?DiscRecord_Log2bpmb
PRINT "zone_spare: ";SkeletonDiscRec?DiscRecord_ZoneSpare<<8+SkeletonDiscRec?(DiscRecord_ZoneSpare+1)
PRINT "nzones: ";SkeletonDiscRec?DiscRecord_BigMap_NZones2<<8+SkeletonDiscRec?DiscRecord_NZones