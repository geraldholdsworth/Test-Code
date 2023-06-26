unit HFormUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Math;

type
 THForm = class
   UsedBits,
   WholeZones,
   OddBits,
   MapZone,
   SecSize,
   SpareBits,
   MapBits,
   Zone0Bits,
   log2ShareSize,
   Log2Alloc,
   min,
   ShareSize,
   MapAdd,
   Alloc,
   MapLen,
   Zones,
   MinMapObj,
   log2SecSize,
   LinkBits,
   Log,
   SectorsPerDisc,
   RoundSectors,
   BestZones,
   BestCylOff,
   ZoneBits,
   MinLinkBits,
   MaxLinkBits,
   Ids,
   DirSize,
   Crucial,
   Crucial1,
   Crucial2,
   BootAdd,
   BootSize: Integer;
   procedure GetLFAU;
   procedure PROCCalcZones;
   procedure PROCShareSize;
   function FNMinMapObj: Integer;
   function FNdoalloc(Verbose: Boolean;LLog: Integer): Boolean;
  constructor Create;
 public
  destructor Destroy; override;
 end;

implementation

constructor THForm.Create;
begin
 inherited;
 UsedBits:=0;
 WholeZones:=0;
 OddBits:=0;
 MapZone:=0;
 SecSize:=0;
 SpareBits:=0;
 MapBits:=0;
 Zone0Bits:=0;
 log2ShareSize:=0;
 Log2Alloc:=0;
 min:=0;
 ShareSize:=0;
 MapAdd:=0;
 Alloc:=0;
 MapLen:=0;
 Zones:=0;
 MinMapObj:=0;
 log2SecSize:=0;
 LinkBits:=0;
 Log:=0;
 SectorsPerDisc:=0;
 RoundSectors:=0;
 BestZones:=0;
 BestCylOff:=0;
 ZoneBits:=0;
 MinLinkBits:=0;
 MaxLinkBits:=0;
 Ids:=0;
 DirSize:=0;
 Crucial:=0;
 Crucial1:=0;
 Crucial2:=0;
 BootAdd:=0;
 BootSize:=0;
end;

destructor THForm.Destroy;
begin
 inherited;
end;

procedure THForm.GetLFAU;
begin
 Log2Alloc:=7;
 if Log2Alloc<Log2SecSize then Log2Alloc:=Log2SecSize;
 Alloc:=Round(IntPower(2,Log2Alloc));
 Log:=Log2Alloc;
 while not FNdoalloc(FALSE,Log) do
 begin
  Alloc:=Round(IntPower(2,Log2Alloc));
  Log:=Log2Alloc;
 end;
 repeat
  Log:=7;
  repeat
   inc(Log);
  until Alloc=IntPower(2,Log);
 until FNdoalloc(True,Log);
end;

procedure THForm.PROCCalcZones;
begin
 UsedBits:=SecSize*8-SpareBits;
 WholeZones:=(MapBits+Zone0Bits)div UsedBits;
 OddBits:=(MapBits+Zone0Bits)mod UsedBits;
 if OddBits<>0 then Zones:=WholeZones+1 else Zones:=WholeZones;
 PROCShareSize;
 MapZone:=Zones div 2;
 if MapZone=0 then
  MapAdd:=0
 else
  if Alloc>secsize then
   MapAdd:=(UsedBits*MapZone-Zone0Bits)*(Alloc div secsize)
  else
   MapAdd:=(UsedBits*MapZone-Zone0Bits)div(secsize div Alloc);
 MapLen:=Zones*SecSize;
end;

procedure THForm.PROCShareSize;
var Lmin : Integer;
begin
 Lmin:=MinMapObj shl Log2Alloc;
 log2ShareSize:=0;
 while (log2ShareSize<16) and (255*(SecSize shl log2ShareSize)<Lmin) do
  inc(log2ShareSize);
 ShareSize:=1 shl log2ShareSize;
end;

function THForm.FNMinMapObj: Integer;
var
 Lmin,t: Integer;
begin
 if (log2ShareSize>log2Alloc) then
  Lmin:=1 shl (log2SecSize-log2Alloc)
 else
  Lmin:=1;
 t:=Lmin;
 while (t<(LinkBits+1)) do
  inc(t,Lmin);
 Result:=t;
end;

function THForm.FNdoalloc(Verbose: Boolean;LLog: Integer): Boolean;
begin
 Log2Alloc:=Log;
 MapBits:=FNMapBits(SectorsPerDisc,Log2Alloc,Log2SecSize);
 RoundSectors:=FNRoundSectors(MapBits,Log2Alloc,Log2SecSize);
 BestZones:=1 shl 30;
 BestCylOff:=1 shl 30;
// FOR DummySpare:=1 TO 1 do
  FOR SpareBits:=4*8 TO ZoneBits-Zone0Bits-8*8 do
  begin
   PROCCalcZones;
   LinkBits:=MinLinkBits-1;
   REPEAT
    inc(LinkBits);
    PROCCalcIds;
   UNTIL(Ids<=Round(IntPower(2,LinkBits)))AND(LinkBits>=(Log2SecSize+3));
   IF(SpareBits-4*8>0)AND(SpareBits-4*8<=LinkBits)then;//NEXT SpareBits%
   IF(OddBits>0)AND(OddBits<=LinkBits)then;// NEXT SpareBits%
   IF(LinkBits>MaxLinkBits)THEN
   begin
    inc(Log2Alloc);
//   NEXT DummySpare%
    Result:=FALSE;
    exit;
   END;
   IF Zones<=BestZones THEN
   begin
    IF LinkBits<=15 THEN
    begin
     IF Zones>127 THEN
     begin
      inc(Log2Alloc);
      // NEXT DummySpare%
      Result:=FALSE;
      exit;
     END;
     Crucial:=FNRoundUpShare(Zones*2)*SecSize+DirSize;
     IF MapZone=0 then Crucial:=BootAdd*SecSize+BootSize;
     IF Crucial<Alloc*FNMinMapObj then Crucial:=Alloc*FNMinMapObj;
     IF Crucial MOD FNGranularity<>0 then inc(Crucial,FNGranularity-Crucial MOD FNGranularity);
    end
    ELSE
    begin
     Crucial1=FNRoundUpShare(Zones*2)*SecSize;
     IF Crucial1<Alloc*FNMinMapObj then Crucial1=Alloc*FNMinMapObj;
     IF Crucial1 MOD FNGranularity<>0 then inc(Crucial1,FNGranularity-Crucial1 MOD FNGranularity);
     Crucial2:=DirSize;
     IF Crucial2<Alloc*FNMinMapObj then Crucial2=Alloc*FNMinMapObj;
     IF Crucial2 MOD FNGranularity<>0 then inc(Crucial2,FNGranularity-Crucial2 MOD FNGranularity);
     Crucial:=Crucial1+Crucial2%;
    END;
    IF (Crucial>((ZoneBits-SpareBits)shl Log2Alloc)) THEN
    begin
     inc(Log2Alloc);
     //NEXT DummySpare%
     Result:=FALSE;
     exit;
    END;
    CrucialEnd:=MapAdd+Crucial div SecSize;
    CylOff:=MapAdd MOD (SecsPerTrk*Heads);
    IF CylOff<BestCylOff THEN
    begin
     BestCylOff:=CylOff;
     BestLinkBits:=LinkBits;
     BestSpare:=SpareBits;
     BestZones:=Zones;
    END;
    IF BestCylOff then;// NEXT SpareBits%
//   NEXT DummySpare%
//  ELSE
//   NEXT DummySpare%
  END;
 end;
 Result:=TRUE;
end;

{ BBC BASIC source of !HForm.!RunImage (2.76 10th October 2020)
REM >!HForm.!RunImage

REM Formatter for ST506, IDE, SCSI and SDIO discs
REM The formatter runs in one of three modes, selected at the
REM start by probing for which filing systems there are.

REM To provide internal consistency, all disc addresses are
REM represented as sector numbers - in a similar way to the
REM FileCore changes.  For backwards compatability, we can
REM convert the disc address at the last instant to be a
REM byte address.

REM Gratuitous use of an include file
#include "Global/FSNumbers.h"

ON ERROR: ON ERROR OFF: PRINT REPORT$;" at line ";ERL:END

REM Default closing status indicates a panic
*set HForm$EndStatus 1

#ifdef DEBUG
Verbose%=TRUE
#else
Verbose%=FALSE
#endif

REM Pointer into RMA, so set to zero up front for robustness on errors.
REM Also flag so we can default to English if Messages file fails.
msgs_file_desc%=0
msgs_file_open%=FALSE

ON ERROR PROCabort(REPORT$, 1)

PROCInit

PROCGetDriveToUse

PROCProbeDriveDetails

PROCGetShape

REM Check that disc not too big
IF NOT myfsisbig% THEN
  IF (DiscSize2%<>0 OR (DiscSize% AND &E0000000)<>0) THEN
    PROCmessage_print_1("DiscSizeError",myfsname$)
    PROCfinish
  ENDIF
ENDIF
FormatFlag%=(FNChoose("Q01:","FormatOrInitChoose","FI","I")="F")
SoakStyle$=FNChoose("Q02:","SoakTestChoose","LSN", "N")
BootOpt$=FNChoose("BootOpt:","BootOptChoose","YN", "Y")

REM Determine if the Filecore version we have supports long filenames
IF FNPeekModuleVersion("FileCore")<=298 THEN
  BigDir%=FALSE
ELSE
  BigDir%=FNChoose("BigDir:","BigDirChoose","YN","Y")="Y"
ENDIF
IF NOT BigDir% THEN MaxLinkBits%=15

REM Pick a nice LFAU
IF NewMap% THEN
  Log2Alloc%=7
  IF Log2Alloc%<Log2SecSize% THEN Log2Alloc%=Log2SecSize%

  REM Check for sensible default
  Alloc%=2^Log2Alloc%:Log%=Log2Alloc%
  WHILE FNdoalloc(FALSE,Log%)=FALSE
    Alloc%=2^Log2Alloc%:Log%=Log2Alloc%
  ENDWHILE

  REM allocation size loop
  REPEAT
    REPEAT
      Alloc%=FNAsk("AllocUnitAsk",2^Log2Alloc%,SecSize%)
      ispow2%=(Alloc%<>0) AND ((Alloc% AND (Alloc%-1))=0)
      IF NOT ispow2% THEN PROCmessage_print_0("Pow2Alloc")
    UNTIL ispow2%
    Log%=7
    REPEAT
      Log%+=1
    UNTIL Alloc%=2^Log%
  UNTIL FNdoalloc(TRUE,Log%)
ENDIF

IF DriveCanon$<>"" THEN
  REM Warn of impending gun/foot incidents
  IF INSTR(FNcanon(FNreadvarval("Boot$Dir")),DriveCanon$)=1 THEN
    PROCmessage_print_0("WarnBootFmt")
  ELSE
    IF INSTR(FNcanon(FNreadvarval("HForm$Dir")),DriveCanon$)=1 THEN
      PROCmessage_print_0("WarnCDirFmt")
    ENDIF
  ENDIF
ENDIF

REM Last chance to bail out
PRINT
IF FNchoose_no_lookup("Q03:",FNmessage_lookup_2("SureChoose",myfsname$,STR$(Drive%)),"YN", "")="N" THEN PROCfinish

PROCDisableEscape
PROCMoanOp(Specify%,0,0,0)
IF FormatFlag% THEN
  PROCFormat
ENDIF
IF SoakStyle$<>"N" THEN
  SoakFlag%=(SoakStyle$="L")
  PROCVerify
ENDIF
PRINT
PROCStructure
PROCRestoreEscape

OSCLI("-"+myfsname$+"-%MOUNT :"+STR$Drive%)
OSCLI("-"+myfsname$+"-%FREE :"+STR$Drive%)
OSCLI("-"+myfsname$+"-%DISMOUNT :"+STR$Drive%)

REM All OK - return a successful status
*set HForm$EndStatus 0
PROCexit
:

REM *****************************************************************
DEF PROCInit
LOCAL DriveOffset%
LOCAL width%,sy%,ex%,ey%,fg%
LOCAL gotadfs%,gotscsifs%,infoptr%
DIM   modevar% 8

REM Opens the message file as its first action.
PROCopen_message_file("<HForm$Dir>.Messages")

VDU26,12,10,10,32:REM 2 lines down, 1 character in
width%=POS
PROCmessage_print_0("Banner")
PROCmessage_print_0("_Version")
width%=POS-width%
modevar%!0=155:REM Text foreground colour
modevar%!4=-1
SYS"OS_ReadVduVariables",modevar%,modevar%
GCOLmodevar%!0
SYS"OS_ReadModeVariable",-1,2 TO,,sy%:sy%=sy%+1
SYS"OS_ReadModeVariable",-1,4 TO,,ex%:ex%=8<<ex%
SYS"OS_ReadModeVariable",-1,5 TO,,ey%:ey%=8<<ey%
REM Draw a rectangle with half character border
RECTANGLE ex%/2,(sy%*ey%)-(ey%/2)-(2*ey%)-ey%,(width%+1)*ex%,2*ey%
PRINT''

xbit%=1<<17
autoreply$=FNreadvarval("HForm$Autoreply")

REM MaxLinkBits% sets the maximum value of idlen
REM For formatting with idlen>15, we have to allow the formatter
REM to select a larger idlen value.
IF FNPeekModuleVersion("FileCore")<=374 THEN
  MaxLinkBits%=19
ELSE
  MaxLinkBits%=21: REM no spare indirect disc address bits now
ENDIF
MaxFreeLinkBits%=15: REM maximum number of bits for a free link
MinLinkBits%=10
Log2ShareSize%=0:REM Unit of sharing
ShareSize%=1<<Log2ShareSize%:REM Sharing multiple
EndDefect%=1<<29:REM Terminator for defects up to 512MB
EndDefectBig%=1<<30:REM Terminator word for a second defect list

REM See which known filing systems are active
SYS"XOS_Module",18,"FileCore%ADFS" TO;F%
gotadfs%=(F%AND1)=0
SYS"XOS_Module",18,"FileCore%SCSI" TO;F%
gotscsifs%=(F%AND1)=0
SYS"XOS_Module",18,"FileCore%SDFS" TO;F%
gotsdfs%=(F%AND1)=0
IF(NOTgotadfs%)AND(NOTgotscsifs%)AND(NOTgotsdfs%) THEN
  PROCmessage_print_0("NoFSModule"):PROCfinish
ENDIF

availablefs$=""
IFgotadfs% availablefs$+="A"
IFgotscsifs% availablefs$+="S"
IFgotsdfs% availablefs$+="M"
IF LEN(availablefs$)>1 THEN
  REM Prompt for preferred
  IF INSTR(availablefs$,"S") defaultfs$="S" ELSE defaultfs$=LEFT$(availablefs$,1)
  chosenfs$=FNChoose("WhichFS:","WhichFS"+availablefs$,availablefs$,defaultfs$)
  gotadfs%=chosenfs$="A"
  gotscsifs%=chosenfs$="S"
  gotsdfs%=chosenfs$="M"
ENDIF

REM Now reduced to one from a list
IFgotadfs% THEN
  myfs%=fsnumber_adfs
  myfsname$="ADFS"
  myfsmodule$="ADFS"
  myfsmiscop%=&4024C
ENDIF
IFgotscsifs% THEN
  myfs%=fsnumber_SCSIFS
  myfsname$="SCSI"
  myfsmodule$="SCSIFS"
  myfsmiscop%=&4098C
ENDIF
IFgotsdfs% THEN
  myfs%=fsnumber_SDFS
  myfsname$="SDFS"
  myfsmodule$="SDFS"
  myfsmiscop%=&59049
ENDIF

REM Deduce its version
myfsversion%=FNPeekModuleVersion(myfsmodule$)

REM Filing system specific initialisation
CASE myfs% OF
  WHEN fsnumber_adfs:
    REM ADFS can have fixed number of drives or autodetected
    SYS"XOS_SWINumberFromString",,"ADFS_IDEDeviceInfo" TO;F%
    IF (F%AND1) THEN
      autodetected_ide%=FALSE
    ELSE
      autodetected_ide%=TRUE
    ENDIF

    REM Count candidates for formatting
    SYS"ADFS_Drives" TO,,HDiscs%:REM Hard only
  WHEN fsnumber_SCSIFS:
    REM Check vaguely modern
    IF myfsversion%<114 THEN
      PROCmessage_print_0("SCSIFSTooOld"):PROCfinish
    ENDIF

    REM SCSIFS with USB needs a minimum amount of RMA to mount a drive
    SYS"XOS_Module",5 TO,,,size%
    IFsize%<32*1024 THEN
      newsize%=(32*1024)-size%
      SYS"XOS_ChangeDynamicArea",1,newsize% TO;F%
      IF (F%AND1) THEN PROCmessage_print_0("NoSpareRMA"):PROCfinish
    ENDIF

    REM Count candidates for formatting
    SYS"SCSIFS_Drives" TO,F%,HDiscs%:HDiscs%+=F%:REM Hard+Floppy
  WHEN fsnumber_SDFS:
    SYS"SDFS_Drives" TO,F%,HDiscs%:HDiscs%+=F%:REM Hard+Floppy
ENDCASE

IF HDiscs%=0 PROCmessage_print_0("NoHardDiscs"):PROCfinish

REM See if sector addressing is possible
SYS xbit%+myfsmiscop%,6 TOinfoptr%
myfsisbig%=((!infoptr%)AND(1<<9))<>0
CASE myfs% OF
  WHEN fsnumber_adfs:
    IF myfsisbig% THEN
      myfsdiscop%=&4024D:REM ADFS_SectorDiscOp
    ELSE
      myfsdiscop%=&40240:REM ADFS_DiscOp
    ENDIF
  WHEN fsnumber_SCSIFS:
    IF myfsisbig% THEN
      myfsdiscop%=&4098D:REM SCSIFS_SectorDiscOp
    ELSE
      myfsdiscop%=&40980:REM SCSIFS_DiscOp
    ENDIF
  WHEN fsnumber_SDFS:
    IF myfsisbig% THEN
      myfsdiscop%=&5904A:REM SDFS_SectorDiscOp
    ELSE
      myfsdiscop%=&59040:REM SDFS_DiscOp
    ENDIF
ENDCASE

ENDPROC

REM *****************************************************************
DEF PROCGetDriveToUse

LOCAL i%,j%,k%,select%
DIM   buf% 128
DIM   Dev%(7)

CASE myfs% OF
  WHEN fsnumber_adfs:
    DriveOffset%=INSTR(autoreply$,"Drive=")
    IF (DriveOffset%<>0) THEN
      Drive%=VAL(MID$(autoreply$,DriveOffset%+6))
    ELSE
      REPEAT
        Drive%=FNAsk("DriveAskHdd",4,4)
      UNTIL Drive%>=4 AND Drive%<=7
    ENDIF
    select%=Drive%-4:REM Make 0s based
  WHEN fsnumber_SCSIFS:
    PROCmessage_print_0("DriveList")
    Dev%()=-1
    FOR i%=0 TO 31:REM For each of 8 devices on 4 SCSI cards
      FOR k%=i% TO &FF STEP &20:REM For each of 8 LUNs in that device
        ?buf%=&7F:REM Look like LUN not present if fatal
        SYS"XSCSI_Initialise",2,k%,buf% TO;F%
        IF ?buf%=&7F THEN
          k%=&100:REM Nothing attached, exit FOR
        ELSE
          REM Only consider 'Direct-access' devices
          IF ((F%AND1)=0) AND (?buf%=0) THEN
            REM Only consider devices SCSIFS knows about
            SYS"SCSIFS_Partitions",1,k% TO,,j%
            IF j%>=0 AND j%<8 THEN Dev%(j%)=k%
          ENDIF
        ENDIF
      NEXT
    NEXT
    REM List out devices in SCSIFS order
    j%=TRUE
    FOR i%=0 TO 7
      k%=Dev%(i%)
      IF k%<>-1 THEN
        REM Get its human readable name
        SYS"SCSI_Initialise",3,k%,buf%,128
        PRINT "SCSI::";i%;" : ";
        SYS"OS_Write0",buf%
        SYS"OS_NewLine"
        j%=FALSE
      ENDIF
    NEXT
    IFj% THENPROCmessage_print_0("NoHardDiscs"):PROCfinish
    SCSIID%=-1
    REPEAT
      Drive%=FNAsk("DriveAskFddHdd",0,0)
      IF Drive%>=0 AND Drive%<8 THEN SCSIID%=Dev%(Drive%)
    UNTIL SCSIID%<>-1
    select%=Drive%
  WHEN fsnumber_SDFS:
    REPEAT
      Drive%=FNAsk("DriveAskFddHdd",0,0)
    UNTIL Drive%>=0 AND Drive%<=7
    select%=Drive%
ENDCASE
IF select%>=HDiscs% THEN
  PROCmessage_print_1("SillyDiscNum", STR$(HDiscs%))
  PROCfinish
ENDIF

ENDPROC
:

REM *****************************************************************
DEF PROCProbeDriveDetails

REM Selected a drive, find out what we are really dealing with here

CASE myfs% OF
  WHEN fsnumber_adfs:
    IF myfsversion% < 210 THEN
      IDE%=FALSE
    ELSE
      SYS"ADFS_ControllerType",Drive% TO DriveType%
      IF DriveType%=0 THEN
        PROCmessage_print_1("DriveNotPresent", STR$(Drive%))
        PROCfinish
      ELSE
        IF DriveType%=3 PROCmessage_print_1("DriveIsST506", STR$(Drive%))
        IF DriveType%=4 PROCmessage_print_1("DriveIsIDE", STR$(Drive%))
      ENDIF
      IDE%=DriveType%=4
    ENDIF
    IF IDE% THEN DIM IDEid% 512
    IF autodetected_ide% THEN
      REM Determine physical drive number which corresponds to logical drive
      REM First try for a newer ADFS that will tell us it directly
      SYS "XADFS_IDEDeviceInfo",2,Drive% TO ,B%,IDEdrive%,D%;F%
      IF ((F% AND1)=0) THEN
        IF (B%<>1) THEN IDEdrive%=-1
      ELSE
        REM Try for two controllers for a maximum of 4 drives
        IDEdrive%=-1
        FOR N%=0 TO 3
          SYS "XADFS_IDEDeviceInfo",0,N% TO ,B%,C%,D%;F%
          IF ((F% AND1)=0) AND (C%=Drive%) AND (B%=1) THEN
            IDEdrive%=N%*8
            N%=4
          ENDIF
        NEXT
      ENDIF
      IF IDEdrive%=-1 THEN
        fail%=TRUE
      ELSE
        REM copy the data from the device ID to a local copy of it
        FOR A%=0 TO 512-4 STEP 4
          IDEid%!A%=D%!A%
        NEXT
        fail%=FALSE
      ENDIF
    ELSE
      REM Determine whether this is IDE drive 0/1
      SYS"XADFS_ControllerType",Drive%-1 TO A%;F%
      IF ((F%AND1)=0) AND (A%=4) THEN IDEdrive%=8 ELSE IDEdrive%=0
      DIM IDEpb% 7
      IDEpb%!0=0
      IDEpb%!4=0
      IDEpb%?5=&A0+(IDEdrive%<<1)
      IDEpb%?6=&EC
      SYS"ADFS_IDEUserOp",1<<24,,IDEpb%,IDEid%,512 TO r0%,,,,r4%
      IF r0%<>0 OR r4%<>0 THEN
        fail%=TRUE
      ELSE
        fail%=FALSE
      ENDIF
    ENDIF
    IF fail% THEN
      PROCmessage_print_1("DiscIdError", STR$~(r0%))
      IDEcyls%=0:IDEheads%=0:IDEsecs%=0
    ELSE
      IDEcyls%=(IDEid%!2)AND&FFFF
      IDEheads%=(IDEid%!6)AND&FFFF
      IDEsecs%=(IDEid%!12)AND&FFFF
      IDECapacity%=IDEcyls%*IDEheads%*IDEsecs%
      IDEAddressSpace%=(IDEid%!(60*2))
      IF (((IDEid%!98)>>9)AND1)<>0 THEN IDEHasLBA%=1 ELSE IDEHasLBA%=0
      IDEname$=""
      FOR I%=27*2 TO 46*2+1
        A%=(IDEid%?(I%EOR1))
        IF (A%<32) OR (A%>=127) A%=ASC"."
        IDEname$+=CHR$(A%)
      NEXT
      IDEfirm$=""
      FOR I%=23*2 TO 26*2+1
        A%=(IDEid%?(I%EOR1))
        IF (A%<32) OR (A%>=127) A%=ASC"."
        IDEfirm$+=CHR$(A%)
      NEXT
      PROCmessage_print_4("IDEDescription",myfsname$, STR$(Drive%), IDEname$, IDEfirm$)
      PROCmessage_print_3("IDEConfiguration", STR$(IDEcyls%), STR$(IDEheads%), STR$(IDEsecs%))
      IF IDEHasLBA%<>0 THEN
        PROCmessage_print_0("IDEHasLBA")
        IF ((IDEid%!(83*2))AND&C400)=&4400 THEN IDEHasLBA48%=1 ELSE IDEHasLBA48%=0
        IF IDEHasLBA48%<>0 THEN
          IDEAddressSpace%=(IDEid%!(100*2))
          IDEAddressSpace2%=(IDEid%!(102*2))
          IF (IDEAddressSpace% AND &E0000000) OR IDEAddressSpace2% THEN
            IDEAddressSpace%=2^29:REM 512M sectors = 256GB
          ENDIF
        ENDIF
        PROCmessage_print_1("IDELBASize", STR$(IDEAddressSpace%))
        IF IDEAddressSpace%>IDECapacity% THEN
          IDEheads%=16
          IDEcyls%=IDEAddressSpace% DIV IDEheads%
          IDEsecs%=255
          WHILE IDEcyls% MOD IDEsecs% AND IDEsecs%>63
            IDEsecs%-=1
          ENDWHILE
          IDEcyls%=IDEcyls% DIV IDEsecs%
          PROCmessage_print_3("IDEConfSuggest", STR$(IDEcyls%), STR$(IDEheads%), STR$(IDEsecs%))
        ENDIF
      ENDIF
    ENDIF
  WHEN fsnumber_SCSIFS:
    REM Determine drive info
    SYS"XSCSI_Initialise",2,SCSIID%,buf% TO;F%
    IF (F%AND1) THENPROCmessage_print_1("DriveNotPresent",STR$(Drive%)):PROCfinish
    SecSize%=buf%!12
    Cap=((buf%!8)*SecSize%)/(1024*1024)
    PROCmessage_print_1("DriveCapacity",STR$(INT(Cap+0.5)))
    IDEAddressSpace%=buf%!8
    IF (IDEAddressSpace% AND &E0000000) THEN
      IDEAddressSpace%=2^29:REM Max idlen
      Cap=(IDEAddressSpace%*SecSize%)/(1024*1024)
      PROCmessage_print_1("DriveTooLarge",STR$(INT(Cap+0.5)))
    ENDIF
    IDE%=1:REM Fool code below to use 512 sector size
    IDEHasLBA%=1
    IDEname$=""
    IDEcyls%=0
    IDEheads%=16
    IDEsecs%=63
    REPEAT
      IDEheads%+=1
      IDEcyls%=IDEAddressSpace% DIV IDEheads%
      IDEsecs%=63
      WHILE IDEcyls% MOD IDEsecs%
        IDEsecs%-=1
      ENDWHILE
      IDEcyls%=IDEcyls% DIV IDEsecs%
    UNTIL((IDEcyls%<=65535) AND (IDEheads%<=255))
    REM Note the above algorithm will break down for drives above 65535*255*63 sectors = 502 GB

    PROCmessage_print_3("IDEConfSuggest", STR$(IDEcyls%), STR$(IDEheads%), STR$(IDEsecs%))
    EnglishMake$="OTHER"
    Cyls%=IDEcyls%:Heads%=IDEheads%:SecsPerTrk%=IDEsecs%:ParkCyl%=Cyls%+1
    InitFlag%=1:LBAFlag%=1
  WHEN fsnumber_SDFS:
    REM determine drive info
    SYS "SDFS_ReadCardInfo",0,Drive% TO ,,IDEAddressSpace%,IDEAddressSpace2%
    REM convert to sectors, cap at current FileCore limit
    IDEAddressSpace% = (IDEAddressSpace%>>>9) OR (IDEAddressSpace2%<<23)
    IDEAddressSpace2% = IDEAddressSpace2%>>>9
    IF (IDEAddressSpace% AND &E0000000) OR IDEAddressSpace2% THEN
       IDEAddressSpace%=&20000000:REM 512M sectors = 256GB
    ENDIF
    IDEname$=""
    REM Determine physical drive address which corresponds to logical drive
    SYS "XSDFS_ReadCardInfo",1,Drive% TO ,,A%;F%
    IF (F%AND1)=0 THEN
      REM Retrieve the card identity block
      DIM SDIOid% 16
      SYS "SDIO_ReadRegister",2,A%,SDIOid%
      FOR I%=13 TO 7 STEP -1
        IF (SDIOid%?I% >= 32) AND (SDIOid%?I% <> 127) THEN IDEname$+=CHR$(SDIOid%?I%)
        IF (I%=12) AND (LEN(IDEname$) > 0) THEN IDEname$+=" ":REM Gap between OEM and product names
      NEXT
      IF IDEname$ = "" THEN IDEname$=FNmessage_lookup_0("TypeOTHER")
      IDEfirm$=CHR$(48 + ((SDIOid%?6) >> 4))+"."+CHR$(48 + ((SDIOid%?6) AND&F))
      PROCmessage_print_4("IDEDescription",myfsname$, STR$(Drive%), IDEname$, IDEfirm$)
    ENDIF
    PROCmessage_print_1("DriveCapacity",STR$(INT(IDEAddressSpace%/1024/1024*512+0.5)))
    IDE%=1:REM Fool code below to use 512 sector size
    IDEHasLBA%=1
    BestWastedSectors%=(1<<31)-1
    FOR IDEsecs%=63 TO 16 STEP -1
    FOR IDEheads%=255 TO 16 STEP -1
      WastedSectors%=IDEAddressSpace% MOD (IDEsecs%*IDEheads%)
      IF WastedSectors%<BestWastedSectors% THEN
        BestIDEsecs%=IDEsecs%
        BestIDEheads%=IDEheads%
        BestWastedSectors%=WastedSectors%
      ENDIF
    NEXT,
    IDEsecs%=BestIDEsecs%
    IDEheads%=BestIDEheads%
    IDEcyls%=IDEAddressSpace% DIV (IDEsecs%*IDEheads%)

    PROCmessage_print_3("IDEConfSuggest", STR$(IDEcyls%), STR$(IDEheads%), STR$(IDEsecs%))
    EnglishMake$="OTHER"
    Cyls%=IDEcyls%:Heads%=IDEheads%:SecsPerTrk%=IDEsecs%:ParkCyl%=Cyls%-1
    InitFlag%=1:LBAFlag%=1
ENDCASE

MakeParams%=7
VerifyRetries%=1
DefectRetries%=5
Verify%=0
Read%=1
Write%=2
WriteTrack%=4
Restore%=6
Specify%=&F
AltDefectBit%=&10
DiscStruc%=&14

IF IDE% THEN
 Log2SecSize%=9
 LowSector%=1
ELSE
 Log2SecSize%=8
 LowSector%=0
ENDIF
SecSize%=2^Log2SecSize%
Zone0Bits%=60*8
ZoneBits%=SecSize%*8

OldMapAdd%=0
OldMapSize%=&200
DirSize%=&800

BootAdd%=&C00/SecSize%
BootSize%=&200

REM space for defects is a bootblock size (512),
REM less 64 bytes for disc record, reserved bytes and checksum,
REM less 16 bytes for hardware-specific parameters,
REM less 4  bytes for a end-of-space fencepost (used by *defect)
REM less 4  bytes for a terminator.

MaxDefects%=(BootSize%-64-&10-4-4)DIV4

REM If the disc is >512M bytes then we have an extra word
REM required for a terminator.  Hence we have 4 bytes less
REM for the defect list.  ie one less defect allowed

BigMaxDefects%=MaxDefects%-1

OldLWM%=&E00
FreeLink%=1
CrossCheck%=3
PROCmessage_print_0("Dismount")

AdfsDiscErr%=&108C7
MaxVerifyBad%=16
Patterns%=8
BufSize%=&40000
DIM Buf% BufSize%, DiscRec% 64+BootSize%, Defect% BootSize%, DirMark% 5, Bad%(MaxVerifyBad%),mc% 100, Pattern%(Patterns%-1)
Boot%=DiscRec%+64
BootRec%=Boot%+BootSize%-64
REM
REM DiscRec +---------+ 0
REM         |         |
REM Boot    +---------+ &40
REM         |         |
REM         |         |
REM         |         |
REM BootRec +---------+ &200
REM         |         |
REM         +---------+ &240
REM
Pattern%(2)=&FFFFFF
Pattern%(3)=&6DB6DB
Pattern%(4)=0
Pattern%(5)=&2CB2CB
Pattern%(6)=&5A5A5A
Pattern%(7)=&4D34D3
CASE myfs% OF
  WHEN fsnumber_adfs:
    SecsPerTrk%=32:Heads%=1:Cyls%=1:ParkCyl%=1
  OTHERWISE:
    REM Nothing to do
ENDCASE
IF IDE% THEN
 InitFlag%=0
 LBAFlag%=0
ELSE
 LowCurrentCyl%=1:PreCompCyl%=1
ENDIF

IF myfsisbig%
   RootDirAdd%=&400/512
ELSE
   RootDirAdd%=&400
ENDIF

Log2Alloc%=10:LinkBits%=MinLinkBits%
IF LinkBits%<=MaxFreeLinkBits% THEN FreeLinkBits%=LinkBits% ELSE FreeLinkBits%=15
IndRootDirAdd%=RootDirAdd%

REM Having SectorsPerDisc% makes various calculations for
REM DiscSize% and DiscSize2% much easier.


IF IDEHasLBA% THEN
  SectorsPerDisc%=IDEAddressSpace%
ELSE
  SectorsPerDisc%=IDECapacity%
ENDIF

DiscSize%=(SectorsPerDisc% AND ((1<<(32-Log2SecSize%))-1))<<Log2SecSize%
DiscSize2%=(SectorsPerDisc%>>(32-Log2SecSize%))
IF ((DiscSize% AND &E0000000)<>0) OR (DiscSize2%<>0) THEN
  BigDisc%=TRUE
ELSE
  BigDisc%=FALSE
ENDIF

REM Capture the drive name (if already formatted) before dismounting
DriveCanon$=FNcanon(myfsname$+"::"+STR$Drive%+".$")

old_retries%=FNFixedDiscRetries(0)
LOCAL ERROR
ON ERROR LOCAL : ON ERROR OFF : old_retries%=FNFixedDiscRetries(old_retries%) : PROCAsm : ENDPROC
OSCLI("-"+myfsname$+"-%DISMOUNT :"+STR$Drive%)
ON ERROR OFF
old_retries%=FNFixedDiscRetries(old_retries%)
PROCAsm

ENDPROC

REM *****************************************************************
DEF PROCGetShape
LOCAL old_retries%

Formatted% = FALSE
PROCInitBootDefects
PROCInitDiscRec

old_retries%=FNFixedDiscRetries(0)
PROCMoanOp(Restore%,0,0,0)
PROCOp(Read%,BootAdd%,Boot%,BootSize%)
old_retries%=FNFixedDiscRetries(old_retries%)

IF Result%<>0 OR NOT FNGoodDefects THEN
 PROCmessage_print_0("NoValidFormat")
ELSE
 PROCOldShape
 PROCOp(Verify%,0,0,SecSize%*SecsPerTrk%)
 IF FNConfirmMake THEN Formatted% = TRUE
ENDIF

IF NOT Formatted% THEN
  CASE myfs% OF
    WHEN fsnumber_adfs:
      IF IDE% THEN
        IF NOT FNCompareMake THEN
          REM Drive not recognised - offer choice or custom specs.
          IF INSTR(autoreply$,"NOunknown") PROCabort(FNmessage_lookup_0("UnknownDriveType"),1)
          PROCAskMake
        ENDIF
      ELSE
        REM ST506 drives do not identify themselves .. ask the user.
        PROCAskMake
      ENDIF
    OTHERWISE:
      PROCAskMake
  ENDCASE

  FOR I%=0 TO BootSize%-1 STEP4
    Boot%!I%=0
  NEXT I%
  Boot%!0=EndDefect%
  Boot%!4=EndDefectBig%
ENDIF

PROCAskShape((NOT Formatted%) AND EnglishMake$="OTHER")

IF NOT Formatted% THEN
 PROCInitBootDefects
ENDIF

PROCmessage_print_1("WillFormat", TransMake$)
PROCprintshape(IDE%)
PRINT
ENDPROC
:

REM *****************************************************************
DEF PROCOldShape
SecsPerTrk%=BootRec%?1
Heads%=BootRec%?2
Log2Alloc%=BootRec%?5
DiscSize%=BootRec%!&10
DiscSize2%=BootRec%!&24

IF ((DiscSize% AND &E0000000)<>0) OR (DiscSize2%<>0) THEN
    BigDisc%=TRUE
ELSE
    BigDisc%=FALSE
ENDIF

SectorsPerDisc%=(DiscSize%>>>Log2SecSize%)+(DiscSize2%<<(32-Log2SecSize%))

Cyls%=SectorsPerDisc% DIV (SecsPerTrk%*Heads%)
IF myfs%=fsnumber_adfs THEN
  IF IDE% THEN
    InitFlag%=(BootRec%?-5)
    LBAFlag%=(BootRec%?-6)
  ELSE
   LowCurrentCyl%=(BootRec%!-8) AND &3FF
   PreCompCyl%=(BootRec%!-6) AND &3FF
  ENDIF
ELSE
  REM Other filing systems don''t use the hardware specific parameters. But we
  REM need to set LBAFlag% to persuade various bits of code to behave as required.
  InitFlag%=0
  LBAFlag%=1
ENDIF
IF BigDisc% THEN
    ParkCyl%=(BootRec%!-4)DIV(SecsPerTrk%*Heads%)
ELSE
    ParkCyl%=(BootRec%!-4)DIV(SecSize%*SecsPerTrk%*Heads%)
ENDIF
PROCInitDiscRec
ENDPROC
:
REM *****************************************************************
DEF PROCAskMake
CASE myfs% OF
  WHEN fsnumber_adfs:
    PROCrestoreparams(IDE%)
    Makes%=0
    I%=INSTR(autoreply$,"DriveType:")
    IF I%<>0 THEN
      I%+=LEN("DriveType:")
      Make%=EVAL(MID$(autoreply$,I%,INSTR(autoreply$,",",I%)-I%))
    ELSE
      PROCmessage_print_0("DriveDisclaim")
      REPEAT : REM list all the drive descriptions available
        READ EnglishMake$, TokenMake$
        TransMake$=FNmessage_lookup_0(TokenMake$)
        Makes%+=1
        PROCmessage_print_2("MakeMenu", RIGHT$(" "+STR$Makes%,2), TransMake$)
        FOR I%=1 TO MakeParams%
          READ A$
        NEXT I%
      UNTIL EnglishMake$="OTHER"
      PRINT
      Make%=FNInputDec("ManufacturerDec",1,Makes%)
      PROCrestoreparams(IDE%)
    ENDIF
    I%=(Make%-1)*(MakeParams%+2)
    WHILE I%>0
      READ A$
      I%-=1
    ENDWHILE
    IF IDE% THEN
      READ EnglishMake$, TokenMake$, SecsPerTrk%, Heads%, Cyls%, InitFlag%, Dummy%, ParkCyl%, LBAFlag%
    ELSE
      READ EnglishMake$, TokenMake$, SecsPerTrk%, Heads%, Cyls%, LowCurrentCyl%, PreCompCyl%, ParkCyl%
    ENDIF
    TransMake$=FNmessage_lookup_0(TokenMake$)
  OTHERWISE:
    TransMake$="":REM No translation
ENDCASE

IF IDE% THEN
  IF (EnglishMake$="OTHER") AND (IDEcyls%<>0) THEN
    SecsPerTrk%=IDEsecs%
    Heads%=IDEheads%
    Cyls%=IDEcyls%
    InitFlag%=1
    LBAFlag%=1
    IF INSTR(autoreply$,"LBA:On")<>0 THEN
      LBAFlag%=1
    ELSE
      IF INSTR(autoreply$,"LBA:Off")<>0 THEN
        LBAFlag%=0
      ENDIF
    ENDIF
  ENDIF
ENDIF
ENDPROC
:

REM *****************************************************************
DEF FNConfirmMake
LOCAL matched%
CASE myfs% OF
  WHEN fsnumber_adfs:
    PROCrestoreparams(IDE%)
    REPEAT
      READ EnglishMake$, TokenMake$, P1%, P2%, P3%, P4%, P5%, P6%
      IF IDE% THEN
        READ P7%
        IF P7%<>0 THEN P7%=1
      ENDIF
      TransMake$=FNmessage_lookup_0(TokenMake$)
      IF EnglishMake$="OTHER" THEN
        PROCmessage_print_0("NonStandardShape")
        PROCprintshape(IDE%)
        PRINT
        =FNChoose("Q04:","RetainShapeChoose","YN","")="Y"
      ENDIF
      IF P1%<>SecsPerTrk% OR P2%<>Heads% OR P3%<>Cyls% OR P6%<>ParkCyl% THEN
        matched%=FALSE
      ELSE
        matched%=TRUE
        IF IDE% THEN
          IF P4%<>InitFlag% OR P7%<>LBAFlag% THEN matched%=FALSE
        ELSE
          IF P4%<>LowCurrentCyl% OR P5%<>PreCompCyl% THEN matched%=FALSE
        ENDIF
      ENDIF
    UNTIL matched%

    PROCmessage_print_1("StandardShape", TransMake$)

  OTHERWISE:
    TransMake$=""
    IF EnglishMake$="OTHER" THEN
      PROCmessage_print_0("NonStandardShape")
      PROCprintshape(IDE%)
      PRINT
      =FNChoose("Q04:","RetainShapeChoose","YN","")="Y"
    ENDIF
ENDCASE

PROCprintshape(IDE%)
PRINT
=FNChoose("Q05:","UseShapeChoose","YN","")="Y"
:

REM *****************************************************************
DEF PROCprintshape(itype%)
PROCmessage_print_3("PrintShape", STR$(Cyls%), STR$(Heads%), STR$(SecsPerTrk%))
IF myfs%=fsnumber_adfs THEN
  IF itype% THEN
    PROCmessage_print_3("PrintShape3IDE", STR$(ParkCyl%), STR$(InitFlag%), STR$(LBAFlag%))
  ELSE
    PROCmessage_print_3("PrintShape2ST506", STR$(ParkCyl%), STR$(LowCurrentCyl%), STR$(PreCompCyl%))
  ENDIF
ELSE
  PROCmessage_print_1("PrintShape4Generic", STR$(ParkCyl%))
ENDIF
ENDPROC
:


REM *****************************************************************
DEF FNCompareMake
PROCrestorePROD
REPEAT
 READ EnglishMake$, TokenMake$, SecsPerTrk%, Heads%, Cyls%, InitFlag%, Dummy%, ParkCyl%, LBAFlag%
 TransMake$=FNmessage_lookup_0(TokenMake$)
 IF EnglishMake$="OTHER" THEN
   PROCmessage_print_0("UnknownDriveMake")
   =FALSE
 ENDIF
UNTIL FNmatchstrings(EnglishMake$,IDEname$)
=FNChoose("Q06:","StandardShapeChoose","YN","")="Y"
:


REM *****************************************************************
DEF PROCAskShape(tailored%)

IF IDE% OR (INSTR(autoreply$,"NewMap")<>0) THEN
 NewMap%=TRUE
ELSE
 NewMap%=(FNChoose("OldOrNewMap:", "OldNewMapChoose", "ON", "N")="N")
ENDIF

IF tailored% THEN
  IF myfs%=fsnumber_adfs THEN
    IF IDE% THEN
         IF IDEHasLBA% THEN
           LBAFlag%=1
           IF INSTR(autoreply$,"LBA:On")<>0 THEN
               LBAFlag%=1
           ELSE
               IF INSTR(autoreply$,"LBA:Off")<>0 THEN
                   LBAFlag%=0
               ELSE
                   LBAFlag%=FNAsk("LBAAsk",LBAFlag%,0)
               ENDIF
           ENDIF
        ELSE
           LBAFlag%=0
        ENDIF
    ENDIF
  ELSE
    REM Other filing systems always use LBA addressing
    LBAFlag%=1
  ENDIF

    IF IDE% THEN
        REPEAT
            Heads%=FNAsk("IDEHeadsAsk",Heads%,1)
            IF Heads%>16 AND LBAFlag%=0 PROCmessage_print_0("IDEHeads16")
            IF Heads%>255 PROCmessage_print_0("Heads255")
        UNTIL Heads%<=255 AND (LBAFlag%=1 OR Heads%<=16)
    ELSE
        Heads%=FNAsk("ST506HeadsAsk",Heads%,1)
        IF Heads%>8 PROCmessage_print_0("ST506Heads8")
    ENDIF
    REPEAT
        SecsPerTrk%=FNAsk("SectorsAsk",SecsPerTrk%,1)
        IF SecsPerTrk%>255 PROCmessage_print_0("Secs255")
    UNTIL SecsPerTrk%<=255
    Cyls%=FNAsk("CylindersAsk",Cyls%,1)

  IF myfs%=fsnumber_adfs THEN
    IF IDE% THEN
        InitFlag%=FNAsk("InitAsk",InitFlag%,0)
    ELSE
        LowCurrentCyl%=FNAsk("LowCylinderAsk",LowCurrentCyl%,0)
        PreCompCyl%=FNAsk("PrecompCylinderAsk",PreCompCyl%,0)
    ENDIF
  ELSE
    REM Other filing systems don''t have this concept. Since IDE% is set for them
    REM to avoid taking ST506 code paths, we need to assign InitFlag% a value
    InitFlag%=0
  ENDIF
    ParkCyl%=FNAsk("ParkCylinderAsk",ParkCyl%,0)
ENDIF

DiscRec%?1=SecsPerTrk%
DiscRec%?2=Heads%

REM Again, calculations for DiscSize% and DiscSize2%
SectorsPerDisc%=SecsPerTrk%*Heads%*Cyls%
IF IDE% THEN
    IF IDEHasLBA% THEN IDELimit%=IDEAddressSpace% ELSE IDELimit%=IDECapacity%
       IF SectorsPerDisc%>IDELimit% THEN
           SectorsPerDisc%=IDELimit%
           Cyls%=SectorsPerDisc% DIV (SecsPerTrk%*Heads%)
           IF ParkCyl%>=Cyls% THEN ParkCyl%=Cyls%-1
       ENDIF
    ENDIF
    IF LBAFlag%=0 AND SectorsPerDisc%>16514064 PROCmessage_print_0("IDECHSMax")
ENDIF

DiscSize%=(SectorsPerDisc% AND ((1<<(32-Log2SecSize%))-1))<<Log2SecSize%
DiscSize2%=(SectorsPerDisc%>>(32-Log2SecSize%))

IF ((DiscSize% AND &E0000000)<>0) OR (DiscSize2%<>0) THEN
    BigDisc%=TRUE
ELSE
    BigDisc%=FALSE
ENDIF

DiscRec%!&10=DiscSize%
DiscRec%!&24=DiscSize2%
DiscRec%?&28=Log2ShareSize%

REM If disc is large then flag this fact in disc record.
IF ((DiscSize% AND &E0000000)<>0 OR (DiscSize2%<>0)) THEN
    DiscRec%?&29=1
ELSE
    DiscRec%?&29=0
ENDIF

FOR I%=0 TO BootSize%-4 STEP 4
 Defect%!I%=Boot%!I%
NEXT I%
Boot%!0=EndDefect%
REPEAT
    ptr%=0
    defectlist%=0
    IF BigDisc% THEN
        IF Defect%!ptr%>=EndDefect% THEN
            IF Defect%!(ptr%+4)<EndDefectBig% PROCmessage_print_0("CurrentDefects")
        ELSE
            PROCmessage_print_0("CurrentDefects")
        ENDIF
    ELSE
        IF Defect%!(ptr%)<EndDefect% PROCmessage_print_0("CurrentDefects")
    ENDIF
    WHILE ((Defect%!ptr%<EndDefect%) AND NOT BigDisc%) OR (Defect%!ptr%<EndDefectBig% AND BigDisc%)
        IF ((Defect%!ptr% AND &E0000000)=EndDefect%) THEN
            ptr%+=4
            defectlist%=1
        ELSE
            IF defectlist%=0 THEN
                defect%=Defect%!ptr%
                defect%=defect% DIV SecSize%
                sector%=(defect% MOD SecsPerTrk%) + LowSector%
                defect%=defect% DIV SecsPerTrk%
                PRINT TAB(((ptr%DIV4)MOD6)*13);"(";defect%DIVHeads%;",";defect%MODHeads%;",";sector%;")";
                ptr%=ptr%+4
            ELSE
                defect%=Defect%!ptr%
                sector%=(defect% MOD SecsPerTrk%) + LowSector%
                defect%=defect% DIV SecsPerTrk%
                PRINT TAB((((ptr%-4)DIV4)MOD6)*13);"(";defect%DIVHeads%;",";defect%MODHeads%;",";sector%;")";
                ptr%=ptr%+4
            ENDIF
        ENDIF
    ENDWHILE
    IF BigDisc% THEN
        Defects%=(ptr%DIV4)-1
    ELSE
        Defects%=ptr%DIV4
    ENDIF
    IF INSTR(autoreply$,"NOadddefects")=0 THEN
        PRINT : PRINT
        PROCmessage_print_0("DefectNoMore")
        PROCmessage_print_0("DefectAdd")
        IF NewMap% THEN
            PROCmessage_print_0("DefectAddDisc")
        ELSE
            PROCmessage_print_0("DefectAddLogical")
        ENDIF
        PROCmessage_print_0("DefectRemove")
    ENDIF
    opt$=FNChoose("Q07:","ABCDChoose","ABCD","")
    PRINT
    CASE opt$ OF
        WHEN "B","D":
            cyl%=FNInputDec("CylinderDec",0,Cyls%-1)
            head%=FNInputDec("HeadDec",0,Heads%-1)
            IF IDE% THEN
                sector%=FNInputDec("SectorDec",1,SecsPerTrk%)
            ELSE
                sector%=FNInputDec("IndexMFMDec",1-SecsPerTrk%,&10000)
                IF sector%>=0 THEN
                    sector%=sector% DIV 320
                ELSE
                    sector%=-sector%
                ENDIF
            ENDIF
            defect%=((cyl%*Heads%+head%)*SecsPerTrk%+(sector%-LowSector%))
            IF opt$="B" THEN
                PROCAddPhysDefect(defect%)
            ELSE
                PROCRemovePhysDefect(defect%)
            ENDIF
        WHEN "C":
            IF NewMap% THEN
                PROCAddPhysDefect((FNInputHex2("DiscAddrHex")))
            ELSE
                PROCmessage_print_1("DFormatDefect1",myfsname$)
                PROCmessage_print_0("DFormatDefect2")
                PROCmessage_print_0("DFormatDefect3")
                defect%=(FNInputHex("LogicalAddrHex")DIVSecSize%)
                PROCAddPhysDefect(FNLogToPhys(defect%))
            ENDIF
    ENDCASE
UNTIL LEFT$(opt$,1)="A"
FOR I%=0 TO DiscStruc%-4 STEP 4
 BootRec%!I%=DiscRec%!I%
NEXT I%
PROCInitHardDesc
ENDPROC
:
REM *****************************************************************
DEF PROCFormat
TIME=0
LOCAL I%,J%,cyl%,head%
PROCMoanOp(Specify%,0,0,0)
PROCMoanOp(Restore%,0,0,0)

PROCmessage_print_0("Formatting")
IF IDE% THEN
 FOR I%=0 TO 512-4 STEP 4:Buf%!I%=0:NEXT
 FOR I%=0 TO SecsPerTrk%-1
  Buf%?(2*I%+0)=&00  :REM format good
  Buf%?(2*I%+1)=I%+1 :REM this sector
 NEXT
ELSE
 FOR I%=0 TO 512-4 STEP 4:Buf%!I%=&077F03FF:NEXT
ENDIF
FOR cyl%=0 TO Cyls%-1
 VDU13:PRINTcyl%;
 FOR head%=0 TO Heads%-1
  IF cyl%<>0 OR head%<>0 OR NOT Formatted% THEN
   IF NOT IDE% THEN
    J%=cyl% OR (head%<<24)
    FOR I%=0 TO (SecsPerTrk%-1)*4 STEP 4:Buf%!I%=J% OR (I%<<14):NEXT
   ENDIF
   REM If its a big ADFS version then we use the big address form
   PROCOp(WriteTrack%,(cyl%*Heads%+head%)*SecsPerTrk%,Buf%,512)
   IF Result% PROCmessage_print_0("FormatError")
  ENDIF
 NEXT
NEXT
ENDPROC
:
REM *****************************************************************
DEF PROCVerify
IF SoakFlag% PROCmessage_print_0("SoakPrompt")
LOCAL add%,ptr%,sector%,head%,cyl%,defectlist%
Cycle%=1:ErrorCycle%=-100
CylSize%=SecsPerTrk%*Heads%
suspects%=0:MaxSuspects%=1000
REM Now we know a verify is needed, extend the slot for that + 32k slack
END=END+(CylSize%*SecSize%)+(5*MaxSuspects%)+&8000
DIM CylBuf% CylSize%*SecSize%+4, SusAdd%(MaxSuspects%), SusCount% MaxSuspects%
VDU 13 : PROCmessage_print_0("Verifying")
REPEAT
    IF Cycle%>1 THEN
        I%=Cycle% MOD Patterns%
        IF I%>1 THEN
            J%=Pattern%(I%)
            J%=(J%>>>1) OR ((J% AND 1)<<23)
            Pattern%(I%)=J%
        ELSE
            J%=RND(&1000000)-1
        ENDIF
        IF NOT SoakFlag% THEN
            VDU 13
            PROCmessage_print_1("Pattern", STR$~(J%))
        ENDIF
        FOR I%=CylBuf% TO CylBuf%+CylSize% STEP 3:!I%=J%:NEXT
        ptr%=0
        defectlist%=0
        IF myfsisbig% THEN
            IF Formatted% add%=SecsPerTrk% ELSE add%=0
        ELSE
            IF Formatted% add%=SecSize%*SecsPerTrk% ELSE add%=0
        ENDIF
        REPEAT
            IF Defect%!ptr%>EndDefect% AND Defect%!ptr%<EndDefectBig% AND myfsisbig% AND BigDisc% AND defectlist%=0 THEN
                ptr%+=4
                defectlist%=1
            ENDIF

            CylEnd%=add% - (add% MOD CylSize%) + CylSize%

            IF (defectlist%=1) THEN
                REM Second defect list, no need to adjust
                defect%=Defect%!ptr%
            ELSE
                REM First defect list, have to adjust
                defect%=(Defect%!ptr%) DIV SecSize%
            ENDIF

            IF defect%>CylEnd% OR defect%<add% THEN
             length%=(CylEnd%-add%)*SecSize%
            ELSE
             length%=(defect%-add%)*SecSize%
            ENDIF

            PROCOp(Write%,add%,CylBuf%,length%)

            IF Result% THEN
                 IF myfsisbig% THEN
                     add%=(ErrDiscAdd% AND &1FFFFFFF)+1
                 ELSE
                     add%=((ErrDiscAdd% AND &1FFFFF00) DIV SecSize%)+1
                 ENDIF
            ELSE
                 add%+=length%
            ENDIF
            IF add%=defect% THEN add%+=1:ptr%+=4
        UNTIL add%>=SectorsPerDisc%
    ENDIF
    IF SoakFlag% PRINT ".";
    REM should start with add%=SecSize%*SecsPerTrk% since
    REM cannot not cope with error in track 0, head 0
    add%=0
    ptr%=0
    defectlist%=0
    PROCMoanOp(Restore%,0,0,0)
    REPEAT
     IF defectlist%=0 THEN
         REPEAT
             IF (Defect%!ptr% AND &E0000000)<>EndDefect% THEN
                 IF ((Defect%!ptr%)DIV SecSize%)<add% THEN
                     ptr%+=4
                 ENDIF
             ELSE
                 IF BigDisc% THEN
                     defectlist%=1
                     ptr%+=4
                 ENDIF
             ENDIF
         UNTIL defectlist%=1 OR ((Defect%!ptr%)DIV SecSize%)>=add%
     ENDIF

     IF defectlist%=1 THEN
         WHILE (Defect%!ptr%)<add%
             ptr%+=4
         ENDWHILE
     ENDIF
     IF defectlist%=0 THEN
         defect%=(Defect%!ptr%) DIV SecSize%
     ELSE
         defect%=Defect%!ptr%
     ENDIF

     IF defect%>SectorsPerDisc% THEN
      length%=SectorsPerDisc%-add%
     ELSE
      length%=defect%-add%
     ENDIF

     IF length%>1024 THEN length%=1024

     PROCOp(Verify%,add%,0,length%*SecSize%)

     IF Result% THEN
      IF myfsisbig% THEN
          add%=ErrDiscAdd% AND &1FFFFFFF
      ELSE
          add%=(ErrDiscAdd% AND &1FFFFF00) DIV SecSize%
      ENDIF
      Try%=0
      REPEAT
       Try%+=1
       PROCMoanOp(Restore%,0,0,0)
       PROCOp(Verify%,add%,0,SecSize%)
   REM **   PROCOp(Verify%,add%,0,SecSize%,&100)
      UNTIL Result%=0 OR Try%=5
      IF Result% Try%+=1
      sector%=add%:REM DIV SecSize%
      head%=sector% DIV SecsPerTrk%
      sector%=sector% MOD SecsPerTrk%
      cyl%=head% DIV Heads%
      head%=head% MOD Heads%
      PROCmessage_print_3("VerifyData", STR$(cyl%), STR$(head%), STR$(sector%+LowSector%))
      sus%=0
      WHILE sus%<suspects% AND SusAdd%(sus%)<>add%:sus%+=1:ENDWHILE
      IF sus%=suspects% THEN
       IF suspects%=MaxSuspects% THEN
        sus%=RND(MaxSuspects%)-1
       ELSE
        suspects%+=1
       ENDIF
       SusAdd%(sus%)=add%
       SusCount%?sus%=0
      ENDIF
      score%=2^(Try%-1)-1
      IF NOT SoakFlag% score%=score%*4
      SusCount%?sus%+=score%
#ifdef DEBUG
      IF TRUE THEN
#else
      IF (SusCount%?sus%>30) THEN
#endif
       IF SoakFlag% THEN
        PROCmessage_print_1("DefectTIME", TIME$)
       ELSE
        PROCmessage_print_0("Defect")
       ENDIF
       PROCAddPhysDefect(add%)
       ErrorCycle%=Cycle%
      ELSE
       IF SoakFlag% THEN
        TIME=0:REPEAT UNTIL TIME>500:VDU 13:PRINTSPC(78);:VDU13
       ELSE
        PROCmessage_print_1("Retries", STR$(Try%))
       ENDIF
      ENDIF
      add%=add%+1
     ELSE
      add%=add%+length%+1
     ENDIF
     IF add%>defect% THEN
      ptr%+=4
     ENDIF
    UNTIL add%>=SectorsPerDisc%
    IF SoakFlag% THEN
     REPEAT
      Key%=INKEY(0)
     UNTIL Key%=-1 OR Key%=32
     done%=(Key%=32)
    ELSE
     done%=Cycle%>ErrorCycle%+2
    ENDIF
    Cycle%+=1
    IF SoakFlag% VDU &2E
UNTIL done%
ENDPROC
:

REM *****************************************************************
DEF PROCStructure
IF NewMap% THEN
 PROCNewStructure
ELSE
 PROCOldStructure
ENDIF
ENDPROC
:

REM *****************************************************************
DEF PROCOldStructure
PROCWriteDefectList
PROCWriteOldFsMap
PROCWriteRootDir
ENDPROC
:

REM *****************************************************************
DEF FNRoundUpShare(Secs%)
IF Log2ShareSize%=0 THEN =Secs%
=((Secs%+ShareSize%-1)DIVShareSize%)*ShareSize%

REM Calculate the number of map bits required

REM *****************************************************************
DEF FNMapBits(Secs%,Lg%,Lg2SecSize%)
    LOCAL Shift%
    Shift%=Lg2SecSize%-Lg%
    IF (Shift%>0) THEN
        =Secs%<<Shift%
    ELSE
        =Secs%>>(-Shift%)
    ENDIF

REM *****************************************************************
DEF FNRoundSectors(Bits%,Lg%,Lg2SecSize%)
    LOCAL Shift%
    Shift%=Lg2SecSize%-Lg%
    IF (Shift%>0) THEN
        =Bits%>>(Shift%)
    ELSE
        =Bits%<<(-Shift%)
    ENDIF

REM *****************************************************************
DEF FNMinMapObj
  LOCAL min%, t%

  IF (Log2SecSize%>Log2Alloc%) THEN
    min%=1<<(Log2SecSize%-Log2Alloc%)
  ELSE
    min%=1
  ENDIF

  t%=min%

  WHILE(t%<(LinkBits%+1))
    t%+=min%
  ENDWHILE

  =t%

REM *****************************************************************
DEF FNdoalloc(Verbose%,Log%)
 Log2Alloc%=Log%
 MapBits%=FNMapBits(SectorsPerDisc%,Log2Alloc%,Log2SecSize%)
 RoundSectors%=FNRoundSectors(MapBits%,Log2Alloc%,Log2SecSize%)
 BestZones%=1 << 30      :REM init to rogue values
 BestCylOff%=1 << 30
 FOR DummySpare%=1 TO 1
 FOR SpareBits% = 4*8 TO ZoneBits%-Zone0Bits%-8*8
  PROCCalcZones
  LinkBits%=MinLinkBits%-1
  REPEAT LinkBits%+=1
   PROCCalcIds
  UNTIL Ids%<=2^LinkBits% AND LinkBits%>=(Log2SecSize%+3)
  IF SpareBits%-4*8>0 AND SpareBits%-4*8<=LinkBits% NEXT SpareBits%
  IF OddBits%>0 AND OddBits%<=LinkBits% NEXT SpareBits%
  IF LinkBits%>MaxLinkBits% THEN
   IF Verbose% THEN PROCmessage_print_0("TooSmallAlloc")
   Log2Alloc%+=1
   NEXT DummySpare%
   =FALSE  :REM restart alloc size loop
  ENDIF
  IF Zones% <= BestZones% THEN
   IF LinkBits%<=15 THEN
     IF Zones% > 127 THEN
       Log2Alloc%+=1
       NEXT DummySpare%
       =FALSE  :REM restart alloc size loop
     ENDIF
     Crucial%=FNRoundUpShare(Zones%*2)*SecSize%+DirSize%
     IF MapZone%=0 Crucial%=BootAdd%*SecSize%+BootSize%
     IF Crucial%<Alloc%*FNMinMapObj Crucial%=Alloc%*FNMinMapObj
     IF Crucial% MOD FNGranularity<>0 Crucial%+=FNGranularity-Crucial% MOD FNGranularity
   ELSE
     Crucial1%=FNRoundUpShare(Zones%*2)*SecSize%
     IF Crucial1%<Alloc%*FNMinMapObj Crucial1%=Alloc%*FNMinMapObj
     IF Crucial1% MOD FNGranularity<>0 Crucial1%+=FNGranularity-Crucial1% MOD FNGranularity

     Crucial2%=DirSize%
     IF Crucial2%<Alloc%*FNMinMapObj Crucial2%=Alloc%*FNMinMapObj
     IF Crucial2% MOD FNGranularity<>0 Crucial2%+=FNGranularity-Crucial2% MOD FNGranularity
     Crucial%=Crucial1%+Crucial2%
   ENDIF
   IF (Crucial%>((ZoneBits%-SpareBits%)<<Log2Alloc%)) THEN
     IF Verbose% THEN PROCmessage_print_0("TooSmallAlloc")
     Log2Alloc%+=1
     NEXT DummySpare%
     =FALSE  :REM restart alloc size loop
   ENDIF
   CrucialEnd%=MapAdd%+Crucial%/SecSize%
   defectlist%=0:REM We are in the first defect list
   DefPtr%=Defect%
   REPEAT
    defect%=!DefPtr%
    DefPtr%+=4
    IF defect%>=EndDefect% AND defectlist%=0 AND BigDisc% THEN
        defect%=!DefPtr%
        DefPtr%+=4
        defectlist%=1
    ENDIF
    IF defectlist%=0 AND defect%<EndDefect% THEN defect%=defect%/SecSize%
   UNTIL defect%>=EndDefect% OR (defect%>=MapAdd% AND defect%<CrucialEnd%)
   CylOff%=MapAdd% MOD (SecsPerTrk%*Heads%)
   IF defect%>=EndDefect% AND CylOff%<BestCylOff% THEN
    BestCylOff%=CylOff%
    BestLinkBits%=LinkBits%
    BestSpare%=SpareBits%
    BestZones%=Zones%
   ENDIF
   IF BestCylOff% NEXT SpareBits%
   NEXT DummySpare%
  ELSE
   NEXT DummySpare%
  ENDIF
IF BestZones%=(1<<30) AND Verbose%=TRUE THEN PROCmessage_print_0("InvalidAllocSize"):=FALSE
=TRUE

REM *****************************************************************
DEF PROCNewStructure
LinkBits%=BestLinkBits%
IF LinkBits%<=MaxFreeLinkBits% THEN FreeLinkBits%=LinkBits% ELSE FreeLinkBits%=15
SpareBits%=BestSpare%
PROCCalcZones
PROCCalcIds
 IF LinkBits%<=15 THEN
   Crucial%=FNRoundUpShare(Zones%*2)*SecSize%+DirSize%
   IF MapZone%=0 Crucial%=BootAdd%*SecSize%+BootSize%
   IF Crucial%<Alloc%*FNMinMapObj Crucial%=Alloc%*FNMinMapObj
   IF Crucial% MOD FNGranularity<>0 Crucial%+=FNGranularity-Crucial% MOD FNGranularity
 ELSE
   Crucial1%=FNRoundUpShare(Zones%*2)*SecSize%
   IF Crucial1%<Alloc%*FNMinMapObj Crucial1%=Alloc%*FNMinMapObj
   IF Crucial1% MOD FNGranularity<>0 Crucial1%+=FNGranularity-Crucial1% MOD FNGranularity

   Crucial2%=DirSize%
   IF Crucial2%<Alloc%*FNMinMapObj Crucial2%=Alloc%*FNMinMapObj
   IF Crucial2% MOD FNGranularity<>0 Crucial2%+=FNGranularity-Crucial2% MOD FNGranularity
   Crucial%=Crucial1%+Crucial2%
 ENDIF

IF MapZone%=0 THEN
 RootDirAdd%=BootAdd%+BootSize%/SecSize%
 IndRootDirAdd%=&200 + (BootAdd%*SecSize%+BootSize%) DIV SecSize% + 1
ELSE
 IF LinkBits%<=15 THEN
   RootDirAdd%=MapAdd%+FNRoundUpShare((MapLen%*2)/SecSize%)
   IndRootDirAdd%=&200+FNRoundUpShare(Zones%*2)/ShareSize%+1
 ELSE
   RootDirAdd%=MapAdd%+(Crucial1%)/SecSize%
   IndRootDirAdd%=((MapZone%*IdsPerZone%)<<8)+1
 ENDIF
ENDIF
DiscRec%?4=LinkBits%
DiscRec%?5=Log2Alloc%
IF BootOpt$="Y" THEN DiscRec%!7=2 ELSE DiscRec%!7=0
DiscRec%?8=LowSector%
DiscRec%?9=Zones%
DiscRec%?&A=SpareBits% MOD 256
DiscRec%?&B=SpareBits% DIV 256
DiscRec%!&C=IndRootDirAdd%
DiscRec%?&28=Log2ShareSize%
DiscRec%?&2a=Zones%>>8
IF BigDir% THEN
  DiscRec%!&2C=1
  DiscRec%!&30=2048
ENDIF
BootRec%!4=DiscRec%!4
BootRec%!8=DiscRec%!8
BootRec%!&C=DiscRec%!&C
BootRec%!&24=DiscRec%!&24
BootRec%!&28=DiscRec%!&28
BootRec%!&2C=DiscRec%!&2C
BootRec%!&30=DiscRec%!&30
PROCWriteDefectList
PROCWriteDOSBootSec(Buf%)
PROCmessage_print_0("CreatingMap")
FOR I%=0 TO BufSize%-1 STEP 4
 Buf%!I%=0
NEXT I%
FOR I%=0 TO 60-4 STEP 4
 Buf%!(I%+4)=DiscRec%!I%
NEXT I%
ptr%=0
DefectStart%=0
defectlist%=0
DiscEndBit%=FNDiscToMap(SectorsPerDisc%)
ZoneStart%=Buf%
ZoneWindow%=0:REM Zone number of base of the window into the map currently being built in Buf%
ZoneStartBit%=0
BootStartBit%=0
BootEndBit%=0
MapStartBit%=0
MapEndBit%=0
PROCmessage_print_0("WritingMap")
FOR zone%=0 TO Zones%-1
 !ZoneStart%=1<<(15+FreeLink%*8)
 ZoneEndBit%=ZoneStartBit%+ZoneBits%
 UsedZoneEndBit%=ZoneEndBit%-SpareBits%+4*8
 IF UsedZoneEndBit%>DiscEndBit% THEN
  UsedZoneEndBit%=DiscEndBit%
 ENDIF
 PreFree%=ZoneStartBit%+FreeLink%*8
 ZoneBit%=ZoneStartBit%+4*8
 IF zone%=0 THEN
  BootStartBit%=ZoneBit%
  ZoneBit%=ZoneBit%+Zone0Bits%
  length%=(BootAdd%*SecSize%+BootSize%) DIV Alloc%
  IF length%<FNMinMapObj length%=FNMinMapObj
  PROCWriteFragLink(ZoneBit%,2)
  PROCWriteFragLength(ZoneBit%,length%)
  ZoneBit%=ZoneBit%+length%
  BootEndBit%=ZoneBit%
 ELSE
  IF zone%=MapZone% THEN
   MapStartBit%=ZoneBit%
   IF LinkBits%<=15 THEN
    length%=Crucial% DIV Alloc%
    PROCWriteFragLink(ZoneBit%,2)
    PROCWriteFragLength(ZoneBit%,length%)
    ZoneBit%=ZoneBit%+length%
   ELSE
    length%=Crucial1% DIV Alloc%
    PROCWriteFragLink(ZoneBit%,2)
    PROCWriteFragLength(ZoneBit%,length%)
    ZoneBit%=ZoneBit%+length%
    length%=Crucial2% DIV Alloc%
    PROCWriteFragLink(ZoneBit%,IndRootDirAdd%>>8)
    PROCWriteFragLength(ZoneBit%,length%)
    ZoneBit%=ZoneBit%+length%
   ENDIF
   MapEndBit%=ZoneBit%
  ENDIF
 ENDIF
 REPEAT
  REM All defects that do not fit are removed here
  IF ZoneBit%>DefectStart% THEN
   IF defectlist%=0 THEN
       IF Defect%!ptr%>=EndDefect% AND BigDisc% THEN
           ptr%+=4
           defectlist%=1
           DefectStart%=FNDiscToMap(Defect%!ptr%)
       ELSE
           DefectStart%=FNDiscToMap((Defect%!ptr%)/SecSize%)
       ENDIF
   ELSE
       DefectStart%=FNDiscToMap(Defect%!ptr%)
   ENDIF
   WHILE ((zone%=0 AND (DefectStart%>=BootStartBit% AND DefectStart%<BootEndBit%))) OR ((zone%=MapZone% AND (DefectStart%>=MapStartBit% AND DefectStart%<MapEndBit%)))
       IF defectlist%=0 THEN
           defectaddr$=FNhexaddr((Defect%!ptr%)/SecSize%)
       ELSE
           defectaddr$=FNhexaddr(Defect%!ptr%)
       ENDIF
       IF zone%=0 THEN
           PROCmessage_print_1("BootDefectError",defectaddr$)
       ELSE
           PROCmessage_print_1("MapDefectError",defectaddr$)
       ENDIF
       ptr%+=4
       IF defectlist%=0 THEN
           IF Defect%!ptr%>=EndDefect% THEN
               ptr%+=4
               defectlist%=1
               DefectStart%=FNDiscToMap(Defect%!ptr%)
           ELSE
               DefectStart%=FNDiscToMap((Defect%!ptr%)/SecSize%)
           ENDIF
       ELSE
           DefectStart%=FNDiscToMap(Defect%!ptr%)
       ENDIF
   ENDWHILE
   IF DefectStart%>=UsedZoneEndBit% THEN
    DefectStart%=ZoneEndBit%
   ELSE
    DefectEnd%=DefectStart%+1
    ptr%+=4
    REPEAT
     done1%=TRUE
     REPEAT
      done2%=TRUE
      IF defectlist%=1 THEN
         IF Defect%!ptr%>=EndDefect% THEN
            NextDefect%=EndDefect%
         ELSE
            NextDefect%=FNDiscToMap(Defect%!ptr%)
         ENDIF
      ELSE
          IF Defect%!ptr%>=EndDefect% THEN ptr%+=4:defectlist%=1
          IF defectlist%=1 THEN
            IF Defect%!ptr%>=EndDefect% THEN
               NextDefect%=EndDefect%
            ELSE
               NextDefect%=FNDiscToMap(Defect%!ptr%)
            ENDIF
          ELSE
            NextDefect%=FNDiscToMap((Defect%!ptr%)/SecSize%)
          ENDIF
      ENDIF
      IF NextDefect%<UsedZoneEndBit% THEN
       IF NextDefect%>ZoneEndBit%-FNMinMapObj THEN
        NextDef%=ZoneEndBit%-FNMinMapObj
       ELSE
        NextDef%=NextDefect%
       ENDIF
       IF NextDef%-DefectEnd%<FNMinMapObj THEN
        IF NextDefect%+1>DefectEnd% THEN
         DefectEnd%=NextDefect%+1
        ENDIF
        ptr%+=4
        done2%=FALSE
       ENDIF
      ENDIF
     UNTIL done2%
     IF DefectEnd%-DefectStart%<FNMinMapObj THEN
      DefectEnd%=DefectStart%+FNMinMapObj
      IF DefectEnd%>ZoneEndBit% THEN
       DefectEnd%=ZoneEndBit%
      ENDIF
      done1%=FALSE
     ENDIF
     IF DefectEnd%>ZoneEndBit%-(FNMinMapObj) AND DefectEnd%<>ZoneEndBit% THEN
      DefectEnd%=ZoneEndBit%
      done1%=FALSE
     ENDIF
     IF DefectEnd%-DefectStart%<FNMinMapObj THEN
      DefectStart%=DefectEnd%-FNMinMapObj
     ENDIF
    UNTIL done1%
   ENDIF
  ENDIF
  IF ZoneBit%>DefectStart% PROCmessage_print_0("ERROR1"):PROCfinish
  IF DefectStart%-ZoneBit% <= LinkBits% THEN DefectStart%=ZoneBit%
  IF DefectStart%>ZoneBit% THEN
   PROCWriteFreeLink(PreFree%,ZoneBit%-PreFree%)
   IF DefectStart%>=UsedZoneEndBit% THEN
    PROCWriteFreeLength(ZoneBit%,UsedZoneEndBit%-ZoneBit%)
    IF ZoneEndBit%>UsedZoneEndBit% THEN
     PROCWriteFragLink(UsedZoneEndBit%,1)
     PROCWriteFragLength(UsedZoneEndBit%,ZoneEndBit%-UsedZoneEndBit%)
    ENDIF
   ELSE
    PROCWriteFreeLength(ZoneBit%,DefectStart%-ZoneBit%)
   ENDIF
  PreFree%=ZoneBit%
  ENDIF
  IF DefectStart%<ZoneEndBit% THEN
   IF DefectEnd%>UsedZoneEndBit%-FNMinMapObj THEN
    DefectEnd%=ZoneEndBit%
   ENDIF
   PROCWriteFragLink(DefectStart%,1)
   PROCWriteFragLength(DefectStart%,DefectEnd%-DefectStart%)
   ZoneBit%=DefectEnd%
  ELSE
   ZoneBit%=ZoneEndBit%
  ENDIF
 UNTIL ZoneBit%=ZoneEndBit%
 PROCWriteFreeLink(PreFree%,0)
 IF zone%=0 THEN
  ZoneStart%?CrossCheck%=&FF
 ELSE
  ZoneStart%?CrossCheck%=0
 ENDIF
 ?ZoneStart%=FNNewMapCheck(ZoneStart%,SecSize%)
 ZoneStart%=ZoneStart%+SecSize%
 ZoneStartBit%=ZoneEndBit%
 IF (ZoneStart%=Buf%+BufSize%) OR (zone%=Zones%-1) THEN
   REM Flush out the buffer
   PROCMoanOp(Write%,MapAdd%+       ZoneWindow%,Buf%,ZoneStart%-Buf%)
   PROCMoanOp(Write%,MapAdd%+Zones%+ZoneWindow%,Buf%,ZoneStart%-Buf%)
   REM Reset for the subsequent zones
   FOR I%=0 TO BufSize%-1 STEP 4
    Buf%!I%=0
   NEXT
   ZoneStart%=Buf%
   ZoneWindow%=zone%+1
 ENDIF
NEXT zone%
PROCWriteRootDir
ENDPROC
:
REM *****************************************************************
DEF PROCCalcZones
UsedBits%=SecSize%*8-SpareBits%
WholeZones%=(MapBits%+Zone0Bits%) DIV UsedBits%
OddBits%=(MapBits%+Zone0Bits%) MOD UsedBits%
IF OddBits% Zones%=WholeZones%+1 ELSE Zones%=WholeZones%
PROCShareSize
MapZone%=Zones% DIV 2
IF MapZone%=0 THEN
     MapAdd%=0
ELSE
     IF (Alloc%>SecSize%) THEN
         MapAdd%=(UsedBits%*MapZone%-Zone0Bits%)*(Alloc% DIV SecSize%)
     ELSE
         MapAdd%=(UsedBits%*MapZone%-Zone0Bits%) DIV (SecSize% DIV Alloc%)
     ENDIF
ENDIF
MapLen%=Zones%*SecSize%
ENDPROC
:
REM *****************************************************************
DEF PROCCalcIds
IdsPerZone%=UsedBits% DIV (LinkBits%+1)
Ids%=IdsPerZone% * WholeZones% + OddBits% DIV (LinkBits%+1)
ENDPROC
:

REM discadd% is now a sector address of course

REM *****************************************************************
DEF FNDiscToMap(discadd%)
LOCAL bit%,zone%
IF discadd%>=EndDefect% THEN =EndDefect%
IF (Alloc%>SecSize%) THEN
    bit%=(discadd% DIV (Alloc% DIV SecSize%))+Zone0Bits%
ELSE
    bit%=(discadd% * (SecSize% DIV Alloc%))+Zone0Bits%
ENDIF
zone%=bit% DIV UsedBits%
bit%=bit%+(bit% DIV UsedBits%)*SpareBits%+4*8
= bit%


REM *****************************************************************
DEF PROCWriteFragLink(off%,link%)
IF link%>=2^LinkBits% PROCmessage_print_0("ERROR2"):PROCfinish
LOCAL bit%,add%,mask%,base%
base%=Buf%-(ZoneWindow%*SecSize%)
bit%=off% MOD 8
add%=base%+off% DIV 8
mask%=2^LinkBits%-1
!add%=(!add% AND NOT (mask%<<bit%)) OR link%<<bit%
ENDPROC

REM *****************************************************************
DEF PROCWriteFragLength(off%,len%)
IF len%<=LinkBits% PROCmessage_print_0("ERROR3"):PROCfinish
LOCAL base%
base%=Buf%-(ZoneWindow%*SecSize%)
off%=off%+len%-1
base%?(off%DIV8)+=2^(off%MOD8)
ENDPROC

REM *****************************************************************
DEF PROCWriteFreeLink(off%,link%)
IF link%>=2^FreeLinkBits% PROCmessage_print_0("ERROR2"):PROCfinish
LOCAL bit%,add%,mask%,base%
base%=Buf%-(ZoneWindow%*SecSize%)
bit%=off% MOD 8
add%=base%+off% DIV 8
mask%=2^FreeLinkBits%-1
!add%=(!add% AND NOT (mask%<<bit%)) OR link%<<bit%
ENDPROC

REM *****************************************************************
DEF PROCWriteFreeLength(off%,len%)
IF len%<=LinkBits% PROCmessage_print_0("ERROR3"):PROCfinish
LOCAL base%
base%=Buf%-(ZoneWindow%*SecSize%)
off%=off%+len%-1
base%?(off%DIV8)+=2^(off%MOD8)
ENDPROC

REM *****************************************************************
DEF PROCWriteDefectList
PROCmessage_print_0("WritingDefects")
ptr%=0
check%=0
WHILE Defect%!ptr%<EndDefect%
 Boot%!ptr%=Defect%!ptr%
 PROCCheckPut(Boot%!ptr%)
 ptr%=ptr%+4
ENDWHILE
check%=check% EOR (check%>>>16)
check%=(check% EOR (check%>>>8))AND &FF
Boot%!ptr%=EndDefect% OR check%

REM If we have a second defect list then do that too
IF BigDisc% THEN
    ptr%+=4
    check%=0
    WHILE Defect%!ptr%<EndDefect%
        Boot%!ptr%=Defect%!ptr%
        PROCCheckPut(Boot%!ptr%)
        ptr%=ptr%+4
    ENDWHILE
    check%=check% EOR (check%>>>16)
    check%=(check% EOR (check%>>>8))AND &FF
    Boot%!ptr%=EndDefectBig% OR check%
ENDIF

REM zero out the remainder of the defect list
WHILE ptr%<(MaxDefects%*4)
 ptr%=ptr%+4
 Boot%!ptr%=0
ENDWHILE
PROCSum(Boot%,BootSize%)
PROCMoanOp(Write%,BootAdd%,Boot%,BootSize%)
ENDPROC
:
REM *****************************************************************
DEF PROCWriteOldFsMap
PROCmessage_print_0("WritingFreeSpace")
LOCAL s%,I%
s%=OldMapSize% DIV 2
FOR I%=0 TO OldMapSize%-4 STEP 4:Buf%!I%=0:NEXT
!Buf%=OldLWM% DIV &100
Buf%!s%=(DiscSize%-OldLWM%-Defects%*SecSize%) DIV &100
!(Buf%+s%-4)=DiscSize% DIV &100
!(Buf%+OldMapSize%-5)=RND(&10000)-1
!(Buf%+OldMapSize%-2)=3
PROCSum(Buf%,s%)
PROCSum(Buf%+s%,s%)
PROCMoanOp(Write%,OldMapAdd%,Buf%,OldMapSize%)
ENDPROC
:
REM *****************************************************************
DEF PROCWriteRootDir
PROCmessage_print_0("WritingRootDir")
IF BigDir% THEN
  PROCWriteBigRootDir
ELSE
  LOCAL BF%
  FOR I%=0 TO DirSize%-4 STEP 4:Buf%!I%=0:NEXT
  IF NewMap% THEN
   $DirMark%="Hugo"
  ELSE
   $DirMark%="Hugo"
  ENDIF
  Buf%!1=!DirMark%
  BF%=Buf%+DirSize%
  IF NewMap% THEN
   BF%!-38=IndRootDirAdd%
  ELSE
   BF%!-38=IndRootDirAdd% DIV &100
  ENDIF
  BF%?-35=ASC"$"
  BF%?-16=ASC"$"
  BF%!-5=!DirMark%
  check%=0
  PROCCheckPut(!Buf%)
  PROCCheckPut(Buf%?4)
  I%=BF%-40
  WHILE I%AND3
   PROCCheckPut(?I%)
   I%=I%+1
  ENDWHILE
  WHILE I%<BF%-4
   PROCCheckPut(!I%)
   I%=I%+4
  ENDWHILE
  check%=check% EOR (check%>>>16)
  check%=(check% EOR (check%>>>8))AND &FF
  BF%?-1=check%
ENDIF
PROCMoanOp(Write%,RootDirAdd%,Buf%,DirSize%)
ENDPROC
:
REM *****************************************************************
DEF PROCWriteBigRootDir
FOR I%=0 TO DirSize%-4 STEP 4:Buf%!I%=0:NEXT
LOCAL hp%
hp%=Buf%+4
$hp%="SBPr"
hp%+=4
!hp%=1
hp%+=4
!hp%=DirSize%
hp%+=4
!hp%=0:REM no entries
hp%+=4
!hp%=0:REM space for names
hp%+=4
!hp%=IndRootDirAdd%
hp%+=4
?hp%=ASC"$"
hp%?1=13:REM the Ursula FileCore spec says this should be CR-terminated
REM there are no entries.  so just do the tail.

hp%=Buf%+DirSize%-8
$hp%="oven"
hp%+=4
!hp%=0

REM now do the check byte

check%=0
FOR I%=0 TO 28 STEP 4
  PROCCheckPut(Buf%!I%)
NEXT I%

I%=DirSize%-8

PROCCheckPut(Buf%!I%)
I%+=4
PROCCheckPut(Buf%?I%)
I%+=1
PROCCheckPut(Buf%?I%)
I%+=1
PROCCheckPut(Buf%?I%)
I%+=1

check%=check% EOR (check%>>>16)
check%=(check% EOR (check%>>>8))AND &FF
Buf%?I%=check%
ENDPROC
:
REM *****************************************************************
DEF FNLogToPhys(add%)
LOCAL ptr%
ptr%=0
WHILE add%>=(Defect%!ptr%) DIV SecSize%
 ptr%=ptr%+4
 add%=add%+SecSize%
ENDWHILE
=add%
:

REM This function used to take the defect address as a byte
REM address - this is now the sector number.

REM *****************************************************************
DEF PROCAddPhysDefect(add%)
LOCAL ptr%,ptr2%,defect%,defectlist%
REM Check defect is physically on the disc
IF (add%>=SectorsPerDisc%) THEN
    PROCmessage_print_0("DefectTooBig")
ELSE
    IF NOT BigDisc% THEN
        REM Here we have a single defect list which we adjust accordingly
        IF Defects%<MaxDefects% THEN
            WHILE ((Defect%!ptr%) DIV SecSize%)<add%
                ptr%=ptr%+4
            ENDWHILE
            defect%=(Defect%!ptr%)/SecSize%
            IF defect%=add% THEN
                PROCmessage_print_0("ExistingDefect")
            ELSE
                ptr2%=Defects%*4
                WHILE ptr2%>=ptr%
                    Defect%!(ptr2%+4)=Defect%!ptr2%
                    ptr2%=ptr2%-4
                ENDWHILE
                Defect%!ptr%=add%*SecSize%
                Defects%=Defects%+1
            ENDIF
        ELSE
            PROCmessage_print_0("FullDefectList")
        ENDIF
    ELSE
        REM Here we have a twin defect list
        IF Defects%<BigMaxDefects% THEN
            IF (add% < (EndDefect%>>>Log2SecSize%)) THEN
                REM Defect before 512M
                defectlist%=0
            ELSE
                REM Defect after 512M
                defectlist%=1
                WHILE (Defect%!ptr%<EndDefect%)
                    ptr%+=4
                ENDWHILE
                ptr%+=4
            ENDIF
            IF defectlist%=1 THEN
                WHILE (Defect%!ptr%)<add%
                    ptr%+=4
                ENDWHILE
            ELSE
                WHILE ((Defect%!ptr%)/SecSize%)<add%
                    ptr%+=4
                ENDWHILE
            ENDIF
            IF defectlist%=0 THEN
                defect%=(Defect%!ptr%)/SecSize%
            ELSE
                defect%=(Defect%!ptr%)
            ENDIF
            IF defect%=add% THEN
                PROCmessage_print_0("ExistingDefect")
            ELSE
                ptr2%=Defects%*4+4
                WHILE ptr2%>=ptr%
                    Defect%!(ptr2%+4)=Defect%!ptr2%
                    ptr2%=ptr2%-4
                ENDWHILE
                IF defectlist%=0 THEN
                    Defect%!ptr%=add%*SecSize%
                ELSE
                    Defect%!ptr%=add%
                ENDIF
                Defects%=Defects%+1
            ENDIF
        ELSE
            PROCmessage_print_0("FullDefectList")
        ENDIF
    ENDIF
ENDIF
ENDPROC
:

REM *****************************************************************
DEF PROCRemovePhysDefect(add%)
LOCAL ptr%,ptr2%,defect%,defectlist%
ptr%=0
defectlist%=1
WHILE ((Defect%!ptr%)/SecSize%)<add% AND (Defect%!ptr%<EndDefect%)
    ptr%=ptr%+4
ENDWHILE
IF Defect%!ptr%>=EndDefect% THEN
    defectlist%=2
    ptr%+=4
    WHILE (Defect%!ptr%)<add% AND (Defect%!ptr%)<EndDefect%
        ptr%=ptr%+4
    ENDWHILE
ENDIF
IF defectlist%=1 THEN
    defect%=(Defect%!ptr%)/SecSize%
ELSE
    defect%=Defect%!ptr%
ENDIF
IF defect%=add% THEN
    IF BigDisc% THEN
        WHILE ptr%<(Defects%*4+4)
            Defect%!ptr%=Defect%!(ptr%+4)
            ptr%=ptr%+4
        ENDWHILE
        Defects%=Defects%-1
    ELSE
        WHILE ptr%<Defects%*4
            Defect%!ptr%=Defect%!(ptr%+4)
            ptr%=ptr%+4
        ENDWHILE
        Defects%=Defects%-1
    ENDIF
    Defects%=Defects%-1
ELSE
     PROCmessage_print_0("MissingDefect")
ENDIF
ENDPROC
:


REM Checks the initial (byte address) defect list.

REM *****************************************************************
DEF FNGoodOldDefectList
ptr%=-4
check%=0
last%=-1
good%=TRUE
REPEAT
 ptr%=ptr%+4
 defect%=Boot%!ptr%
 IF defect%<=last% good%=FALSE
 last%=defect%
 IF defect%<EndDefect% PROCCheckPut(defect%)
UNTIL (defect% >= EndDefect%) OR NOT good%
OldDefects%=ptr%DIV4
check%=check% EOR (check%>>>16)
check%=(check% EOR (check%>>>8))AND &FF
= good% AND ((defect%AND&FF) = check%)

REM *****************************************************************
DEF FNGoodNewDefectList
ptr%=4*OldDefects%
check%=0
last%=-1
good%=TRUE
REPEAT
 ptr%=ptr%+4
 defect%=Boot%!ptr%
 IF defect%<=last% good%=FALSE
 last%=defect%
 IF defect%<EndDefectBig% PROCCheckPut(defect%)
UNTIL (defect% >= EndDefectBig%) OR NOT good%
NewDefects%=ptr%DIV4-OldDefects%-1
check%=check% EOR (check%>>>16)
check%=(check% EOR (check%>>>8))AND &FF
= good% AND ((defect%AND&FF) = check%)


REM *****************************************************************
DEF FNGoodDefects
bothgood%=FNGoodOldDefectList
REM Only check second list if disc is big enough to have it
IF (((BootRec%!&10) AND &E0000000)<>0 OR (BootRec%!&26)<>0) AND bothgood% THEN
    bothgood%=bothgood% AND FNGoodNewDefectList
ENDIF
= bothgood% AND (FNsum(Boot%,BootSize%)=Boot%?(BootSize%-1))
:


REM *****************************************************************
DEF PROCInitDiscRec
FOR I%=0 TO 64-4 STEP 4
 DiscRec%!I%=0
NEXT I%
?DiscRec%=Log2SecSize%
DiscRec%?1=SecsPerTrk%
DiscRec%?2=Heads%
DiscRec%?8=LowSector%
DiscRec%!&C=IndRootDirAdd%
DiscRec%!&10=DiscSize%
DiscRec%!&24=DiscSize2%
DiscRec%?&28=Log2ShareSize%
REM If disc is large then flag this fact in disc record.
IF ((DiscSize% AND &E0000000)<>0 OR (DiscSize2%<>0)) THEN
    DiscRec%?&29=1
ELSE
    DiscRec%?&29=0
ENDIF
DiscRec%!&14=RND(&10000)-1

$(DiscRec%+&16)="HardDisc"+STR$Drive%

DiscRec%?&22=Drive%
ENDPROC
:

REM Initialises an empty boot block defect list.  As we do not know
REM at this point type of defect list to use, we assume a large one.

REM *****************************************************************
DEF PROCInitBootDefects
!Boot%=EndDefect%
Boot%!4=EndDefectBig%

REM We record two defect counts - one for defects in the
REM first 512M and one for defects later in the disc.

OldDefects%=0
NewDefects%=0
IF ((DiscSize% AND &E0000000)<>0) OR (DiscSize2%<>0) THEN
    BigDisc%=TRUE
ELSE
    BigDisc%=FALSE
ENDIF
PROCInitHardDesc
ENDPROC
:

REM *****************************************************************
DEF PROCInitHardDesc
IF IDE% THEN
 BootRec%!-&10=0
 BootRec%!-&C=0
 IF myfs%=fsnumber_adfs THEN
  BootRec%?-5=InitFlag%
  BootRec%?-6=LBAFlag%
 ENDIF
ELSE
 BootRec%!-&10= &00000000      :REM SL xxxxxx
 BootRec%!-&C = &0D0C200A      :REM GPL2 GPL3 SH GPL1
 REM BootRec%!-&10= &16000000  slow stepping alternative
 REM BootRec%!-&C = &0D0CA80A  slow stepping alternative
 BootRec%!-8  = LowCurrentCyl% OR (PreCompCyl%<<16)
ENDIF

REM If BigDisc% then park address is a sector number
IF BigDisc% THEN
    BootRec%!-4  = SecsPerTrk%*Heads%*ParkCyl%
ELSE
    BootRec%!-4  = SecSize%*SecsPerTrk%*Heads%*ParkCyl%
ENDIF

BootRec%!-&14= &FFFFFFFF       :REM fencepost for end-of-defect-space
ENDPROC
:

REM *****************************************************************
DEF FNAsk(string$,Default%,min%)
LOCAL X,Y,reply$,value%
IF INSTR(autoreply$,"Defaults") AND Default%>=min% THEN
 =Default%
ENDIF
PRINT:VDU11
PROCmessage_print_0(string$): VDU32: X=POS: Y=VPOS
LOCAL ERROR
ON ERROR LOCAL IF ERR=17 PROCabort(REPORT$,1)
REPEAT
 PRINT TAB(X,Y);Default%;SPC3;TAB(X,Y);
 *FX 15,1
 INPUT ""reply$
 IF reply$="" THEN
  value%=Default%
 ELSE
  value%=EVAL(reply$)
 ENDIF
UNTIL value%>=min%
PRINT TAB(X,Y);value%;SPC3
=value%
:

REM *****************************************************************
DEF FNInputDec(string$,min%,max%)
LOCAL X,Y,reply$,value%
PRINT:VDU11
PROCmessage_print_2(string$,STR$(min%),STR$(max%)): X=POS: Y=VPOS
LOCAL ERROR
ON ERROR LOCAL IF ERR=17 PROCabort(REPORT$,1)
REPEAT
 PRINT TAB(X,Y);SPC12;TAB(X,Y);: INPUT ""reply$
 value%=EVAL(reply$)
UNTIL value%>=min% AND value%<=max%
= value%
:

REM *****************************************************************
DEF FNInputHex(string$)
LOCAL X,Y,reply$,value%
PRINT:VDU11
PROCmessage_print_0(string$): X=POS: Y=VPOS
LOCAL ERROR
ON ERROR LOCAL IF ERR=17 PROCabort(REPORT$,1)
PRINT TAB(X,Y);SPC12;TAB(X,Y);: INPUT ""reply$
=EVAL("&"+reply$)

REM *****************************************************************
DEF FNInputHex2(string$)
LOCAL X,Y,reply$,value%
PRINT:VDU11
PROCmessage_print_0(string$): X=POS: Y=VPOS
REMLOCAL ERROR
REMON ERROR LOCAL IF ERR=17 PROCabort(REPORT$,1)
PRINT TAB(X,Y);SPC12;TAB(X,Y);: INPUT ""reply$
=FNSectorAddr(reply$)
:

REM *****************************************************************
DEF FNSectorAddr(reply$)
LOCAL add%, add2%
add%=0
add2%=0

WHILE INSTR("abcdefABCDEF0123456789",LEFT$(reply$,1))<>0 AND LEN(reply$)<>0
    add2%=(add2%<<4)+(add%>>>28)
    add%=add%<<4
    add%=add%+EVAL("&"+LEFT$(reply$,1))
    reply$=MID$(reply$,2)
ENDWHILE
=(add%>>>Log2SecSize%)+(add2%<<(32-Log2SecSize%))

:

REM *****************************************************************
DEF FNChoose(select$, string$, opt$, default$)
=FNchoose_no_lookup(select$, FNmessage_lookup_0(string$), opt$, default$)
:

REM *****************************************************************
DEF FNchoose_no_lookup(select$,prompt$,english_opt$,english_default$)
LOCAL X,Y,reply$,start,end, opt$, default$
opt$=FNmessage_lookup_0(english_opt$)
IF english_default$<>"" THEN
  default$=MID$(opt$, INSTR(english_opt$, english_default$), 1)
ELSE
  default$=""
ENDIF

IF autoreply$<>"" THEN
  start = INSTR(autoreply$,select$)
  end = INSTR(autoreply$,",",start+1)
  IF end=0 THEN end = LEN(autoreply$) + 1
  IF start=0 THEN
    PROCmessage_print_2("FailedAuto", select$, prompt$)
    PROCfinish
  ENDIF
  start+=LEN(select$)
  IF start<>end THEN
#ifdef DEBUG
    PRINTprompt$;" ";MID$(autoreply$,start,end-start)
#endif
    =MID$(autoreply$,start,end-start)
  ENDIF
ENDIF
PRINT:VDU11
PRINT prompt$;" ";: X=POS: Y=VPOS
REPEAT
 REPEAT
  PRINT TAB(X,Y);default$;SPC12;TAB(X,Y);: INPUT ""reply$
  IF reply$="" THEN reply$=default$
 UNTIL LEN(reply$)=1
 IF INSTR(opt$, reply$)=0 THEN reply$=CHR$(ASC(reply$)AND&DF)
UNTIL INSTR(opt$,reply$)
:
REM Translate option selected back to one of the token options
=MID$(english_opt$, INSTR(opt$, reply$), 1)
:

REM *****************************************************************
DEF FNreadvarval(varname$)
LOCAL varlen%, varbuf%
DIM  varbuf% 256
SYS "XOS_ReadVarVal",varname$,varbuf%,256,0,3 TO ,,varlen%
varbuf%?varlen% = 13
=$varbuf%
:

REM *****************************************************************
DEF FNcanon(object$)
LOCAL canon$,I%,F%,table%
SYS"XOS_FSControl",37,object$,STRING$(255," "),,,255 TO,,canon$;F%
IF (F%AND1)=1 THEN=""
SYS"Territory_UpperCaseTable",-1 TO table%
FOR I%=1 TO LEN(canon$)
  MID$(canon$,I%,1)=CHR$(table%?ASC(MID$(canon$,I%,1)))
NEXT
=canon$
:

REM *****************************************************************
DEF PROCCheckPut(I%)
check%=(check% >>> 13) EOR ((check% AND (2^13-1)) << (32-13)) EOR I%
ENDPROC
:

REM *****************************************************************
DEF FNsum(base%,len%)
sum%=0:c%=0
FOR I%=len%-2 TO 0 STEP-1
sum%=sum%+base%?I%+c%
IF sum%<&100 c%=0 ELSE sum%=sum% AND &FF:c%=1
NEXT I%
=sum%
:
REM *****************************************************************
DEF PROCSum(base%,len%)
base%?(len%-1)=FNsum(base%,len%)
ENDPROC
:
REM *****************************************************************
DEF FNNewMapCheck(B%,C%)=USR(NewCheck%)
:
REM *****************************************************************
DEF PROCAsm
FOR opt%=0 TO 2 STEP 2
 P%=mc%
 [ OPT opt%
.NewCheck%
 MOV  R0,#0
 ADDS R2,R1,R2  \C=0
.loop%
 LDR  R3,[R2,#-4]!
 ADCS R0,R0,R3
 TEQS R2,R1
 BNE  loop%
 AND  R3,R3,#&FF
 SUB  R0,R0,R3
 EOR  R0,R0,R0,LSR #16
 EOR  R0,R0,R0,LSR #8
 AND  R0,R0,#&FF
 MOV  PC,R14
 ]
NEXT opt%
ENDPROC
:
REM *****************************************************************
DEF PROCDisableEscape
SYS "XOS_Byte",200,1,0 TO r0%,OldEscState%
SYS "XOS_Byte",247,%10101010,0 TO r0%,OldBreakState%
ENDPROC
:
REM *****************************************************************
DEF PROCRestoreEscape
SYS "XOS_Byte",200,OldEscState%,0
SYS "XOS_Byte",247,OldBreakState%,0
ENDPROC
:
REM *****************************************************************
REM SCSIFS rejects the Specify reason code to DiscOp. Rather than simply
REM ignoring all errors in the SCSI case, as was done previously, we filter out
REM those specific calls.

DEF PROCMoanOp(b%, C%, D%, E%)
IF b%=Specify% AND myfs%=fsnumber_SCSIFS THEN ENDPROC
IF myfsisbig% THEN
  SYS myfsdiscop%,0,b% OR AltDefectBit% OR (DiscRec%<<6),C% OR Drive%<<29,D%,E%
ELSE
  SYS myfsdiscop%,0,b% OR AltDefectBit% OR (DiscRec%<<6),(C%*SecSize%) OR Drive%<<29,D%,E%
ENDIF
ENDPROC
:

REM *****************************************************************
DEF PROCOp(b%, C%, D%, E%)
IF myfsisbig% THEN
  SYS xbit%+myfsdiscop%,0,b% OR AltDefectBit% OR (DiscRec%<<6),C% OR Drive%<<29,D%,E% TO Result%,R1%,ErrDiscAdd%
ELSE
  SYS xbit%+myfsdiscop%,0,b% OR AltDefectBit% OR (DiscRec%<<6),(C%*SecSize%) OR Drive%<<29,D%,E% TO Result%,R1%,ErrDiscAdd%
ENDIF
IF Result% THEN
 IF Verbose% THEN
  PRINT"(""";
  I%=Result%+4:WHILE ?I% VDU?I%:I%+=1:ENDWHILE
  PROCmessage_print_1("OpError", STR$~(!Result%))
 ENDIF
 IF !Result% AND (1 << 31) THEN
  PROCmessage_print_1("Error", STR$~(!Result% AND &3FFFFFFF))
  PROCfinish
 ELSE
  IF ((!Result%) AND &FF00FF)=(AdfsDiscErr% AND &FF00FF) THEN
   Result%=!Result% AND &FF : REM probably the original intention
  ELSE
   PROCmessage_print_1("Error", STR$~(!Result%)):VDU 32
   I%=4
   WHILE Result%?I%
    VDU Result%?I%
    I%=I%+1
   ENDWHILE
   PROCfinish
  ENDIF
 ENDIF
ELSE
ENDIF
ENDPROC
:

REM *****************************************************************
DEF FNmatchstrings(str1$,str2$)
LOCAL II%,JJ%,LI%,LJ%
II% = 0 : LI%=LEN(str1$)
JJ% = 0 : LJ%=LEN(str2$)
REPEAT
  REM skip spaces
  WHILE II%<LI% AND ASC(MID$(str1$,II%+1,1))=ASC(" ") : II%+=1 : ENDWHILE
  WHILE JJ%<LJ% AND ASC(MID$(str2$,JJ%+1,1))=ASC(" ") : JJ%+=1 : ENDWHILE
  IF II%<LI% AND JJ%<LJ% THEN
    IF ASC(MID$(str1$,II%+1,1))<>ASC(MID$(str2$,JJ%+1,1)) THEN
      =FALSE : REM characters differ in str1$ and str2$
    ENDIF
  ELSE
    IF II%=LI% EOR JJ%=LJ% =FALSE : REM _only_ one string ended
  ENDIF
  IF II%<LI% II%+=1
  IF JJ%<LJ% JJ%+=1
UNTIL II%=LI% AND JJ%=LJ%
=TRUE
:

REM basic -Report error and die
REM *****************************************************************
DEF PROCabort(why$,failcode%)
LOCAL dummy$
LOCAL ERROR
ON ERROR OFF

IF ERR=17 THEN
  PROCmessage_print_0("UserQuit")
  PROCfinish
ENDIF

IF msgs_file_open% THEN
  PROCmessage_print_2("HFormFailed", why$, STR$(ERL))
ELSE
  PRINT"HForm failed : ";why$;" at line ";ERL
ENDIF

IF INSTR(autoreply$,"NOprompts")=0 THEN
  IF msgs_file_open% THEN
    PROCmessage_print_0("PressKey")
  ELSE
    PRINT "Press Return to continue ";
  ENDIF
  INPUT ""dummy$
ENDIF
PROCfinish
ENDPROC
:

REM Unsuccessful termination - return a FAIL status and clean up
REM *****************************************************************
DEF PROCfinish
*set HForm$EndStatus 20
PROCexit
ENDPROC
:

REM tidy termination
REM *****************************************************************
DEF PROCexit
PROCclose_message_file
END
ENDPROC
:

REM *****************************************************************
DEF FNFixedDiscRetries(V%)
CASE myfs% OF
 WHEN fsnumber_adfs:
   SYS"ADFS_Retries",&FF,V% TO,,V%
 OTHERWISE:
   REM Not applicable
   V%=0
ENDCASE
=V%

REM *****************************************************************
DEF PROCrestoreparams(iface%)
IF iface% THEN
  PROCrestorePROD
ELSE
  PROCrestoreST506
ENDIF
ENDPROC
:

REM *****************************************************************
DEF PROCrestorePROD
RESTORE+1
ENDPROC
:
REM Production IDE drives
REM For automatic determination of IDE drive, the printing characters in
REM the string below must *exactly* match those produced by the drives
REM identify command. However, the 'space' character is ignored.
REM The user never sees the burnt in name - the one in the Messages file
REM is always displayed instead.
REM For comparison with previous format parameters, the drive parameter
REM lists must all be slightly different (otherwise, the drive type
REM reported will always be the FIRST matching entry)

REM Identification, name token, Sectors per track, heads, cylinders, Needs init, dummy, parking cylinder, lba flag

DATA Conner Peripherals 40MB - CP3044,     TypeCP3044,     40,  4,   526, 1, 0,   525,  0
DATA Conner Peripherals 42MB - CP2044,     TypeCP2044PK,   38,  4,   548, 1, 0,   547,  0: REM Sticker says CP2044PK
DATA Conner Peripherals 63MB - CP2064,     TypeCP2064,     38,  4,   823, 1, 0,   822,  0
DATA Conner Peripherals 210MB - CFS210A,   TypeCFS210A,    38, 16,   685, 1, 0,   684,  0
DATA Conner Peripherals 270MB - CFS270A,   TypeCFS270A,    63, 14,   600, 1, 0,   599,  0
DATA Conner Peripherals 420MB - CFS420A,   TypeCFS420A,    63, 16,   826, 1, 0,   825,  0
DATA Conner Peripherals 425MB - CFS425A,   TypeCFS425A,    62, 16,   839, 1, 0,   838,  0
DATA Conner Peripherals 850MB - CFS850A,   TypeCFS850A,    63, 16,  1651, 1, 0,  1650,  1
DATA Maxtor 2B010H1,                       Type2B010H1,   189, 16,  6618, 1, 0,  6617,  1
DATA Maxtor 2B020H1,                       Type2B020H1,    63, 16, 39703, 1, 0, 39702,  1
DATA Maxtor 4D040H2,                       Type4D040H2,   252, 16, 19852, 1, 0, 19851,  1
DATA SAMSUNG SV8004H,                      TypeSV8004H,   249, 16, 39249, 1, 0, 39248,  1

DATA OTHER,                                TypeOTHER,      1,  1,      1, 1, 1,     1,  1: REM Must be last, numbers irrelevant (except must be non zero).

REM *****************************************************************
DEF PROCrestoreST506
RESTORE+1
ENDPROC
:
REM fast stepping ST506 drives
REM Manufacturer, Sectors per track, heads, cylinders, low current cylinder, precompensation cylinder, parking cylinder
DATA 20Mb Miniscribe 8425,                      Type8425,       32, 4, 615, &3FF,  128, 663
DATA 53Mb Rodime RO3065,                        TypeRO3065,     32, 7, 872, &3FF,  650, 871
DATA 20Mb Kalok KL320,                          TypeKL320,      32, 4, 615, 615,   300, 615
REM DATA 20Mb Western Digital WD362/Tandon TM362,   TypeTM362,      32, 4, 615, &3FF, &3FF, 663
DATA OTHER,                                     TypeOTHER,      32, 4, 612, &3FF,  128, 611:REM MUST BE LAST

:
REM OSS Added message file handling functions during internationalisation.
REM Note that some RMA space is claimed, because MessageTrans (in its
REM infinite wisdom) needs its 16 byte block and the filename in the RMA.
REM Thus we must be very careful to free this block up ROBUSTLY whenever
REM the program terminates. The file itself is held in application space.
:
REM *****************************************************************
DEF PROCopen_message_file(filename$)
LOCAL flags%, size%
SYS "MessageTrans_FileInfo", ,filename$ TO flags%,,size%
IF (flags% AND 1) THEN msgs_file_buf%=0 ELSE DIM msgs_file_buf% size%
SYS "OS_Module", 6,,,17+LEN(filename$) TO ,,msgs_file_desc%
$(msgs_file_desc%+16)=filename$
SYS "MessageTrans_OpenFile", msgs_file_desc%,msgs_file_desc%+16,msgs_file_buf%
msgs_file_open%=TRUE
msg_lookup_buf_size%=256
DIM msg_lookup_buf% msg_lookup_buf_size%
ENDPROC
:
REM Robust procedure - called during error handling. Report errors but
REM always continue execution.
:
REM *****************************************************************
DEF PROCclose_message_file
LOCAL flags%
LOCAL ERROR
ON ERROR OFF

IF msgs_file_open% THEN
  SYS "XMessageTrans_CloseFile", msgs_file_desc% TO r0%;flags%
  msgs_file_open%=FALSE
  IF (flags% AND 1) THEN SYS "XOS_Write0",r0%+4
ENDIF

IF msgs_file_desc% THEN
  SYS "XOS_Module", 7,,msgs_file_desc% TO r0%;flags%
  msgs_file_desc%=0
  IF (flags% AND 1) THEN SYS "XOS_Write0",r0%+4
ENDIF
ENDPROC
:
REM Procedure for lookups, with one to four parameters. Make sure there
REM are no |M s in the strings for these, or BASIC will think it is
REM the end of the string.
:
REM *****************************************************************
DEF FNmessage_lookup_0(tag$)
=FNmessage_lookup_4(tag$, "", "", "", "")
:
REM *****************************************************************
DEF FNmessage_lookup_1(tag$, arg1$)
=FNmessage_lookup_4(tag$, arg1$, "", "", "")
:
REM *****************************************************************
DEF FNmessage_lookup_2(tag$, arg1$, arg2$)
=FNmessage_lookup_4(tag$, arg1$, arg2$, "", "")
:
REM *****************************************************************
DEF FNmessage_lookup_3(tag$, arg1$, arg2$, arg3$)
=FNmessage_lookup_4(tag$, arg1$, arg2$, arg3$, "")
:
REM *****************************************************************
DEF FNmessage_lookup_4(tag$, arg1$, arg2$, arg3$, arg4$)
LOCAL len%
SYS "MessageTrans_GSLookup", msgs_file_desc%,tag$,msg_lookup_buf%,msg_lookup_buf_size%,arg1$,arg2$,arg3$,arg4$ TO ,,,len%
msg_lookup_buf%?len%=13
=$msg_lookup_buf%
:
REM Procedures for printing a looked string - cannot use PRINT as we want
REM to put |M s (char 13 - end of BASIC string) in the strings.
:
REM *****************************************************************
DEF PROCmessage_print_0(tag$)
PROCmessage_print_4(tag$, "", "", "", "")
ENDPROC
:
REM *****************************************************************
DEF PROCmessage_print_1(tag$, arg1$)
PROCmessage_print_4(tag$, arg1$, "", "", "")
ENDPROC
:
REM *****************************************************************
DEF PROCmessage_print_2(tag$, arg1$, arg2$)
PROCmessage_print_4(tag$, arg1$, arg2$, "", "")
ENDPROC
:
REM *****************************************************************
DEF PROCmessage_print_3(tag$, arg1$, arg2$, arg3$)
PROCmessage_print_4(tag$, arg1$, arg2$, arg3$, "")
ENDPROC
:
REM *****************************************************************
DEF PROCmessage_print_4(tag$, arg1$, arg2$, arg3$, arg4$)
LOCAL len%
SYS "MessageTrans_GSLookup", msgs_file_desc%,tag$,msg_lookup_buf%,msg_lookup_buf_size%,arg1$,arg2$,arg3$,arg4$ TO ,,,len%
SYS "OS_WriteN", msg_lookup_buf%, len%
ENDPROC
:

REM *****************************************************************
REM This used to increase min% if it was less than Zones%*SecSize%, but only if
REM LinkBits% was <= 15. This makes no sense, and the LinkBits% dependency
REM suggests that during Ursula development it was questioned, but behaviour
REM for smaller discs was retained for compatibility. Instead, I argue that
REM it should be removed outright, by the following reasoning:
REM
REM If this value of min% were to apply, then we gradually increase
REM Log2ShareSize% until Zones%*SecSize% <= (253*SecSize%)<<Log2ShareSize%
REM but for LinkBits% <= 15 and 512-byte sectors (every case for which HForm
REM has ever been used), the number of zones is less than 253, so this doesn''t
REM constrain Log2ShareSize at all - it''s true even if it is 0.
REM
REM Also, the constant ought to be 255, not 253, although this doesn''t currently
REM make any difference considering that there are no ways to configure the
REM map such that the minimum fragment block is between 15*2^x and 2^(x+1) bits
REM long, unless the maximum idlen is increased - these correspond to 240 and
REM 128 share units per disc object respectively.
REM
REM We also ought to limit Log2ShareSize% to 15, since only bits 0-3 of byte 40
REM in the disc record are documented to be used for this purpose.

REM Old version
REM DEF PROCShareSize
REM     LOCAL min%, min2%
REM     min2%=Zones%*SecSize%
REM     min%=FNMinMapObj<<Log2Alloc%
REM     IF (min%<min2%) AND (LinkBits%<=15) THEN min%=min2%
REM     Log2ShareSize%=0
REM     WHILE (253*(SecSize%<<Log2ShareSize%)<min%)
REM         Log2ShareSize%+=1
REM     ENDWHILE
REM     ShareSize%=1<<Log2ShareSize%
REM ENDPROC

DEF PROCShareSize
    LOCAL min%
    min%=FNMinMapObj<<Log2Alloc%
    Log2ShareSize%=0
    WHILE (Log2ShareSize%<16) AND (255*(SecSize%<<Log2ShareSize%)<min%)
        Log2ShareSize%+=1
    ENDWHILE
    ShareSize%=1<<Log2ShareSize%
ENDPROC

REM *****************************************************************
DEF FNhexaddr(Sector%)
LOCAL high$,low$
high$=STR$~(Sector%>>>(32-Log2SecSize%))
WHILE (LEN(high$)<8)
    high$="0"+high$
ENDWHILE
low$=STR$~(Sector%<<(Log2SecSize%))
WHILE (LEN(low$)<8)
    low$="0"+low$
ENDWHILE
=high$+low$

REM *****************************************************************
DEF FNGranularity

  IF Log2SecSize%>Log2Alloc% THEN
    =1<<Log2SecSize%
  ELSE
    =1<<Log2Alloc%
  ENDIF

REM *****************************************************************
DEF FNPeekModuleVersion(mod$)
LOCAL code%,help$,help%

SYS "OS_Module",18,mod$ TO,,,code%
help$=""
help%=(code%!&14)+code%
WHILE (?help%)<>0
  help$+=CHR$?help%
  help%+=1
ENDWHILE

=INT(VAL(MID$(help$,INSTR(help$,".")-1))*100)

REM *****************************************************************
DEF PROCWriteDOSBootSec(DOSBuf%)
 LOCAL i%,brec%
 FORi%=0TO511STEP4
   DOSBuf%!i%=0
 NEXTi%

 REM Preload a basic boot sector
 DOSBuf%!&00=&00903CEB
 $(DOSBuf%+3)="Castle"+CHR$0+CHR$0
 :
 DOSBuf%!&28=&4E326000
 DOSBuf%!&2c=&414E204F
 DOSBuf%!&30=&2020454D
 DOSBuf%!&34=&20202020
 DOSBuf%!&38=&20202020
 DOSBuf%!&3c=&31FA2020
 DOSBuf%!&40=&BCD08EC0
 DOSBuf%!&44=&8EFB7C00
 DOSBuf%!&48=&0000E8D8
 DOSBuf%!&4c=&19C6835E
 DOSBuf%!&50=&FC0007BB
 DOSBuf%!&54=&74C084AC
 DOSBuf%!&58=&CD0EB406
 DOSBuf%!&5c=&30F5EB10
 DOSBuf%!&60=&CD16CDE4
 DOSBuf%!&64=&4E0A0D19
 DOSBuf%!&68=&732D6E6F
 DOSBuf%!&6c=&65747379
 DOSBuf%!&70=&6964206D
 DOSBuf%!&74=&0A0D6B73
 DOSBuf%!&78=&73657250
 DOSBuf%!&7c=&6E612073
 DOSBuf%!&80=&656B2079
 DOSBuf%!&84=&6F742079
 DOSBuf%!&88=&62657220
 DOSBuf%!&8c=&0D746F6F
 DOSBuf%!&90=&0000000A

 brec%=DOSBuf%+&b

 brec%?0  =   SecSize%         :REM Secsize lo byte
 brec%?1  =   SecSize%>>8      :REM Secsize hi byte
 brec%?2  =   0                :REM secs/cluster
 brec%?3  =   0                :REM reserved secs lo byte
 brec%?4  =   0                :REM reserved secs hi byte
 brec%?5  =   0                :REM FATS
 brec%?6  =   0                :REM Root entries lo byte
 brec%?7  =   0                :REM Root entries hi byte
 brec%?8  =   0                :REM Small Secs lo byte
 brec%?9  =   0                :REM Small Secs hi byte
 brec%?10 =   0                :REM Media Descr
 brec%?11 =   0               :REM Secs/FAT lo byte
 brec%?12 =   0               :REM Secs/FAT hi byte
 brec%?13 =   SecsPerTrk%     :REM Secs/track lo byte
 brec%?14 =   SecsPerTrk%>>8  :REM Secs/track hi byte
 brec%?15 =   Heads%          :REM Heads lo byte
 brec%?16 =   Heads%>>8       :REM Heads hi byte
 DOSBuf%!32 = ( (Cyls% * (Heads%+1) ) * SecsPerTrk%) + SecsPerTrk% -1 :REM Large disc sectors

 DOSBuf%?510=&55
 DOSBuf%?511=&aa

 REM Write it out
 PROCMoanOp(Write%,0,DOSBuf%,&200)
ENDPROC
}

end.

