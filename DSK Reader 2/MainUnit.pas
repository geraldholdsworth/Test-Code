unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type
 TDIByteArray = array of Byte;
 TDSKSector = record
  ID        : Byte;
  Size      : Word;
  Offset    : Cardinal;
 end;
 TDSKTrack = record
  Sectors   : array of TDSKSector;
  Offset    : Cardinal;
  Size      : Word;
  Number    : Byte;
  Side      : Byte;
  Filler    : Byte;
  Sector    : Word;
  Boot      : Boolean;
  BootSize  : Byte;
  Valid     : Boolean;
 end;
 TDSKImage = record
  Creator    : String;
  Reserved   : array[0..1] of Integer;
  NumTracks  : Word;
  Sides      : Byte;
  Tracks     : array of TDSKTrack;
  Capacity   : Cardinal;
  Used       : Cardinal;
  DataAreas  : Byte;
  NumBlocks  : Word;
 end;
 TDSKHeaderType = (diNone,diSOFT968,diPLUS3DOS,diOther);
 TFile = record
  UserNumber: Byte;
  Filename  : String;
  Extension : String;
  ReadOnly  : Boolean;
  Hidden    : Boolean;
  Archive   : Boolean;
  Deleted   : Boolean;
  Length    : Cardinal;
  Clusters  : array of Word;
  Side      : Byte;
  HeaderType: TDSKHeaderType;
 end;

  { TMainForm }

  TMainForm = class(TForm)
   Panel1: TPanel;
   Memo1: TMemo;
   //DiscImage Functions
   function ReadString(ptr,term: Integer;control: Boolean=True): String;
   function ReadByte(Ptr: Cardinal): Byte;
   function Read16b(offset: Cardinal): Word;
   function GetDataLength: Cardinal;
   function GetMajorFormatNumber: Word;
   //DSK Functions
   function ID_Sinclair: Boolean;
   function ReadDSK: Boolean;
   function GetDSKOffset(Cluster: Word;Side: Byte;First:Boolean=True): Cardinal;
   function GetDSKTrackSector(Cluster: Word;Side:Byte;First:Boolean=True): Word;
   function CheckForDSKBoot(Ptr: Cardinal): Boolean;
   function GetDSKHeaderType(Ptr: Cardinal): TDSKHeaderType;
   function ExtractSpectrumFile(FileDetails: TFile;
                                             var buffer: TDIByteArray): Boolean;
   //Form functions
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
   FData      : TDIByteArray;
   FFormat    : Word;
   FDSKImage  : TDSKImage;
   Files      : array of TFile;
   const
    diSinclair   = $003;
    diInvalidImg = $00FF;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

//TDiscImage generic functions

function TMainForm.ReadString(ptr,term: Integer;control: Boolean=True): String;
var
 x : Integer=0;//Counter
 c : Byte=0;
 r : Byte=0;
begin
 //Dummy result
 Result:='';
 //Are we excluding control characters?
 if control then c:=32 else c:=0;
 //Start with the first byte (we pre-read it to save multiple reads)
 r:=FData[ptr+x];
 while(r>=c)and //Test for control character
    (((r<>term)and(term>=0))or //Test for terminator character
     ((x<abs(term))and(term<0)))do //Test for string length
 begin
  if r>=c then Result:=Result+chr(r); //Add it to the string
  inc(x);                //Increase the counter
  r:=Fdata[ptr+x];    //Read the next character
 end;
end;

function TMainForm.ReadByte(Ptr: Cardinal): Byte;
begin
 Result:=FData[Ptr];
end;

function TMainForm.Read16b(offset: Cardinal): Word;
begin
 Result:=FData[offset+1]<<8+FData[offset];
end;

function TMainForm.GetDataLength: Cardinal;
begin
 Result:=Length(FData);
end;

function TMainForm.GetMajorFormatNumber: Word;
begin
 Result:=FFormat>>4;
end;

//DSK Functions

{-------------------------------------------------------------------------------
Identifies a Spectrum disc
-------------------------------------------------------------------------------}
function TMainForm.ID_Sinclair: Boolean;
var
 IDStr: String='';
begin
 if FFormat=diInvalidImg then
  //Check that the image is actually big enough for the smallest DSK
  if GetDataLength>=176*1024 then
  begin
   //Check for signature
   IDStr:=ReadString(0,-$21);
   if LeftStr(IDStr,11)='MV - CPCEMU'       then FFormat:=diSinclair<<4+0;
   if LeftStr(IDStr,16)='EXTENDED CPC DSK'  then FFormat:=diSinclair<<4+1;
   //Check for correct number of sides
   if(ReadByte($31)<>1)and(ReadByte($31)<>2)then FFormat:=diInvalidImg;
  end;
 Result:=FFormat<>diInvalidImg;
end;

{-------------------------------------------------------------------------------
Read Spectrum Disc into DSK container
-------------------------------------------------------------------------------}
function TMainForm.ReadDSK: Boolean;
var
 Index    : Integer=0;
 Index1   : Integer=0;
 Ptr      : Cardinal=0;
 Ref      : Cardinal=0;
 TrackID  : String='';
 S        : Byte=0;
 IDBase   : Byte=0;
 DirTrack : Byte=0;
 DirSector: Byte=0;
 Temp     : TFile=();
begin
 Result:=False;
 //Ensure that the format has been read and is valid
 if GetMajorFormatNumber=diSinclair then
 begin
  SetLength(Files,0);
  SetLength(FDSKImage.Tracks,0);
  FDSKImage.Reserved[0]:=-1;
  FDSKImage.Reserved[1]:=-1;
  //Get the creator
  FDSKImage.Creator  :=ReadString($22,-14);
  FDSKImage.NumTracks:=ReadByte($30); //Number of tracks per side
  FDSKImage.Sides    :=ReadByte($31); //Number of tracks
  //Reset some counters
  FDSKImage.Capacity :=0;
  FDSKImage.DataAreas:=0;
  //Set up the container for the track information
  SetLength(FDSKImage.Tracks,FDSKImage.NumTracks*FDSKImage.Sides);
  Ptr:=$100;
  //Get the track information
  for Ref:=0 to Length(FDSKImage.Tracks)-1 do
  begin
   //Tracks are stored interleaved, but we'll have them linear
   Index:=(Ref MOD FDSKImage.Sides)*FDSKImage.NumTracks
         +(Ref DIV FDSKImage.Sides);
   //Track size
   if(FFormat AND$F)=0 then FDSKImage.Tracks[Index].Size:=Read16b($32);
   if(FFormat AND$F)=1 then FDSKImage.Tracks[Index].Size:=ReadByte($34+Index)<<8;
   //Add this to the total capacity
   inc(FDSKImage.Capacity,FDSKImage.Tracks[Index].Size);
   //Make a note of the offset for this track
   FDSKImage.Tracks[Index].Offset:=Ptr;
   //Make sure the track info signature is valid
   TrackID:='';
   for Index1:=$00 to $0B do TrackID:=TrackID+Chr(ReadByte(Ptr+Index1));
   if TrackID='Track-Info'#$0D#$0A then
   begin
    //Boot block?
    FDSKImage.Tracks[Index].Boot  :=CheckForDSKBoot(Ptr+$100);
    //Add this to our counter
    if FDSKImage.Tracks[Index].Boot then inc(FDSKImage.DataAreas);
    //Track number
    FDSKImage.Tracks[Index].Number:=ReadByte(Ptr+$10);
    //Side it is on
    FDSKImage.Tracks[Index].Side  :=ReadByte(Ptr+$11);
    //Size of each sector
    FDSKImage.Tracks[Index].Sector:=ReadByte(Ptr+$14)<<8;
    //Filler byte
    FDSKImage.Tracks[Index].Filler:=ReadByte(Ptr+$17);
    //It is a valid track
    FDSKImage.Tracks[Index].Valid :=True;
    //Set up the container for the sectors
    SetLength(FDSKImage.Tracks[Index].Sectors,ReadByte(Ptr+$15));
    //Get the Sector ID Base
    IDBase:=ReadByte(Ptr+$18+$2);
    //Now read the sector information for this track
    for Index1:=0 to Length(FDSKImage.Tracks[Index].Sectors)-1 do
    begin
     //Valid sector? Match size, track and sides
     if (ReadByte(Ptr+$18+Index1*$8+$3)=ReadByte(Ptr+$14))
     and(ReadByte(Ptr+$18+Index1*$8+$0)=ReadByte(Ptr+$10))
     and(ReadByte(Ptr+$18+Index1*$8+$1)=ReadByte(Ptr+$11))then
     begin
      //Sector ID
      S:=ReadByte(Ptr+$18+Index1*$8+$2);
      //We need to make sure it is not a duplicate
      if FDSKImage.Tracks[Index].Sectors[S-IDBase].ID<>S then
       FDSKImage.Tracks[Index].Sectors[S-IDBase].ID:=S
      else
      begin //Otherwise, we'll need to add it to the end
       FDSKImage.Tracks[Index].Sectors[Index1].ID:=S;
       S:=Index1+IDBase;
      end;
      //Each sector information contains it's own size
      FDSKImage.Tracks[Index].Sectors[S-IDBase].Size:=
                                                 Read16b(Ptr+$18+Index1*$8+$6);
      //Work out the offset - this is based on the track information
      FDSKImage.Tracks[Index].Sectors[S-IDBase].Offset:=
                                         FDSKImage.Tracks[Index].Offset+$100
                                        +Index1*FDSKImage.Tracks[Index].Sector;
     end;
    end;
    //Move the offset along
    inc(Ptr,FDSKImage.Tracks[Index].Size);
   end else FDSKImage.Tracks[Index].Valid:=False; //Invalid track
  end;
  if FDSKImage.DataAreas=0 then FDSKImage.DataAreas:=FDSKImage.Sides;
  //Calculate the total number of blocks
  FDSKImage.NumBlocks:=(FDSKImage.Capacity div FDSKImage.DataAreas)div$400;
  //Read in the boot blocks
  DirTrack:=0;
  FDSKImage.Used:=0;
  //So we go through the tracks and find the ones with boot blocks
  while DirTrack<Length(FDSKImage.Tracks) do
  begin
   if FDSKImage.Tracks[DirTrack].Boot then
   begin
    if FDSKImage.Reserved[FDSKImage.Tracks[DirTrack].Side]=-1 then
     FDSKImage.Reserved[FDSKImage.Tracks[DirTrack].Side]:=
                                               DirTrack
                                              -FDSKImage.NumTracks
                                              *FDSKImage.Tracks[DirTrack].Side;
    //Where are we?
    Ptr:=FDSKImage.Tracks[DirTrack].Sectors[DirSector].Offset;
    DirSector:=0; //Sector counter
    FDSKImage.Tracks[DirTrack].BootSize:=1;
    //Read in the data (which could span multiple sectors)
    while(CheckForDSKBoot(Ptr))and(Ptr<GetDataLength)do
    begin
     //Get the filename, ignoring all spaces
     Temp.Filename:='';
     for Index:=1 to $8 do
      if(ReadByte(Ptr+Index)>32)and(ReadByte(Ptr+Index)<127)then
       Temp.Filename:=Temp.Filename+Chr(ReadByte(Ptr+Index));
     //Now get the extension, removing the top bit and ignoring spaces
     Temp.Extension:='';
     for Index:=$9 to $B do
      if ReadByte(Ptr+Index)AND$7F>32 then
       Temp.Extension:=Temp.Extension+Chr(ReadByte(Ptr+Index)AND$7F);
     //Check the extent is zero (user number of 0xE5 means a deleted file)
     if(ReadByte(Ptr+$C)=$00)or(ReadByte(Ptr)=$E5)then
     begin
      //We can then add a new entry
      Index1:=Length(Files);
      SetLength(Files,Index1+1);
      Files[Index1].Length:=0;
     end
     else
     begin
      //Otherwise, we need to find the first entry
      Index1:=0;
      while(Index1<Length(Files))
        and(Files[Index1].Filename+'.'+Files[Index1].Extension
            <>Temp.Filename+'.'+Temp.Extension)
        and(not Files[Index1].Deleted)do
       inc(Index1);
      //But if we fail to find it, then just create a new one anyway
      if Index1>=Length(Files) then
      begin
       SetLength(Files,Index1+1);
       Files[Index1].Length:=0;
      end;
     end;
     //Populate the fields
     //User number (<16)
     Files[Index1].UserNumber:=ReadByte(Ptr);
     //Filename
     Files[Index1].Filename  :=Temp.Filename;
     //Read only flag
     Files[Index1].ReadOnly  :=(ReadByte(Ptr+$9)AND$80)=$80;
     //Hidden flag
     Files[Index1].Hidden    :=(ReadByte(Ptr+$A)AND$80)=$80;
     //Archived flag
     Files[Index1].Archive   :=(ReadByte(Ptr+$B)AND$80)=$80;
     //Deleted?
     Files[Index1].Deleted   :=(ReadByte(Ptr   )       =$E5)
                             or(ReadByte(Ptr+$C)       =$E5);
     //Extension
     Files[Index1].Extension :=Temp.Extension;
     //Reported length
     Files[Index1].Length    :=Files[Index1].Length+ReadByte(Ptr+$F)*$80;
     //Which side is it on?
     Files[Index1].Side      :=FDSKImage.Tracks[DirTrack].Side;
     //Calculate the used space
     if not Files[Index1].Deleted then
      inc(FDSKImage.Used,ReadByte(Ptr+$F)*$80);
     //Read in the clusters
     Index:=$10;
     //Are we reading them as 8-bit or 16-bit values?
     if FDSKImage.NumBlocks<256 then S:=0 else S:=1;
     //So, read them until we reach the end or find a 'hole'
     while(Index<$20)
       and((ReadByte(Ptr+Index+S)<<(8*S)OR ReadByte(Ptr+Index))<>$00)do
     begin
      //Add new entry
      Ref:=Length(Files[Index1].Clusters);
      SetLength(Files[Index1].Clusters,Ref+1);
      Files[Index1].Clusters[Ref]:=ReadByte(Ptr+Index+S)<<(8*S)
                                OR ReadByte(Ptr+Index);
      //Next entry
      inc(Index,S+1);
     end;
     if Length(Files[Index1].Clusters)>0 then
      Files[Index1].HeaderType:=GetDSKHeaderType(
                                         GetDSKOffset(Files[Index1].Clusters[0]
                                                     ,Files[Index1].Side));
     //Next file
     Inc(Ptr,$20);
     //End of sector?
     if Ptr>=FDSKImage.Tracks[DirTrack].Sectors[DirSector].Offset
            +FDSKImage.Tracks[DirTrack].Sectors[DirSector].Size then
     begin
      //Next sector
      inc(DirSector);
      inc(FDSKImage.Tracks[DirTrack].BootSize);
      //Which could be the next track
      if DirSector>Length(FDSKImage.Tracks[DirTrack].Sectors) then
      begin
       inc(DirTrack);
       DirSector:=0;
      end;
      //Get the offset for this sector
      Ptr:=FDSKImage.Tracks[DirTrack].Sectors[DirSector].Offset;
     end;
    end;
   end;
   //Check next track
   inc(DirTrack);
  end;
  //No boot blocks have been found, so let's create them, per side.
  for Index:=0 to FDSKImage.Sides-1 do
   if FDSKImage.Reserved[Index]=-1 then
   begin
    //Base it on the sector ID
    case FDSKImage.Tracks[0].Sectors[0].ID of
     $01: FDSKImage.Reserved[Index]:=1; //IBM
     $41: FDSKImage.Reserved[Index]:=2; //Vendor
     $C1: FDSKImage.Reserved[Index]:=0; //Data
     else FDSKImage.Reserved[Index]:=0; //Unknown/Unrecognised
    end;
    FDSKImage.Tracks[FDSKImage.Reserved[Index]].Boot:=True;
   end;
  Result:=True;
 end;
end;

{-------------------------------------------------------------------------------
Convert a cluster number and side to offset
-------------------------------------------------------------------------------}
function TMainForm.GetDSKOffset(Cluster: Word;Side: Byte;
                                                 First: Boolean=True): Cardinal;
var
 LTrack : Byte=0;
 LSector: Byte=0;
 T      : Word=0;
begin
 Side:=Side mod 2;
 T:=GetDSKTrackSector(Cluster,Side,First);
 LTrack :=T>>8;
 LSector:=T AND $FF;
 Result:=FDSKImage.Tracks[LTrack].Sectors[LSector].Offset
        +FDSKImage.Reserved[Side]*FDSKImage.Tracks[0].Size;
end;

{-------------------------------------------------------------------------------
Convert a cluster number and side to track and sector
-------------------------------------------------------------------------------}
function TMainForm.GetDSKTrackSector(Cluster: Word;Side: Byte;
                                                 First: Boolean=True): Word;
var
 LTrack : Byte=0;
 LSector: Byte=0;
 F      : Byte=0;
begin
 if First then F:=0 else F:=1;
 Side:=Side mod 2;
 LTrack :=((Cluster*2)+F)DIV Length(FDSKImage.Tracks[0].Sectors);
 LTrack :=LTrack+(FDSKImage.NumTracks*Side);
 LSector:=((Cluster*2)+F)MOD Length(FDSKImage.Tracks[0].Sectors);
 Result:=LTrack<<8+LSector;
end;

{-------------------------------------------------------------------------------
Check the offset for a boot block
-------------------------------------------------------------------------------}
function TMainForm.CheckForDSKBoot(Ptr: Cardinal): Boolean;
var
 LI: Integer=0;
begin
 Result:=((ReadByte(Ptr   )<$10)or(ReadByte(Ptr   )=$E5))
      and((ReadByte(Ptr+$C)<$05)or(ReadByte(Ptr+$C)=$E5));
 if Result then
  for LI:=$1 to $8 do
   Result:=(Result)and(ReadByte(Ptr+LI)>$1F)and(ReadByte(Ptr+LI)<$80);
end;

{-------------------------------------------------------------------------------
Identify file header type
-------------------------------------------------------------------------------}
function TMainForm.GetDSKHeaderType(Ptr: Cardinal): TDSKHeaderType;
var
 Index: Integer=0;
 Ctr  : Word=0;
begin
 Result:=diNone;
 Ctr:=0;
 for Index:=0 to $42 do
  inc(Ctr,ReadByte(Ptr+Index));
 if(Ctr=Read16b(Ptr+$43))and(Ctr<>0)then Result:=diSOFT968
 else
  if (ReadString(Ptr,-8)='PLUS3DOS')
  and(ReadByte(Ptr+8)=$1A)then
  begin
   Ctr:=0;
   for Index:=0 to $7E do
    inc(Ctr,ReadByte(Ptr+Index));
   if(Ctr AND $FF)=ReadByte(Ptr+$7F) then Result:=diPLUS3DOS
  end;
end;

{-------------------------------------------------------------------------------
Extract a file into a buffer
-------------------------------------------------------------------------------}
function TMainForm.ExtractSpectrumFile(FileDetails: TFile;
                                             var buffer: TDIByteArray): Boolean;
var
 ptr    : Cardinal=0;
 Index  : Cardinal=0;
 cnt    : Cardinal=0;
 offset : Cardinal=0;
 len    : Word=0;
 first  : Byte=0;
 T      : Word=0;
 secsize: Word=0;
begin
 //Default return result
 Result:=False;
 if(FileDetails.Length>0)and(Length(FileDetails.Clusters)>0)
 and((FileDetails.Side=0)or(FileDetails.Side=1))then
 begin
  Result:=True;
  //Setup the buffer
  SetLength(buffer,FileDetails.Length);
  //And the pointers
  ptr:=0;
  Index:=0;
  while(ptr<Length(buffer))and(Index<Length(FileDetails.Clusters))do
  begin
   //Two loops per cluster. Each cluster is two sectors.
   for first:=0 to 1 do
   begin
    //Get the offset
    offset:=GetDSKOffset(FileDetails.Clusters[Index]
                        ,FileDetails.Side,first=0);
    //We'll also get the track and sector
    T:=GetDSKTrackSector(FileDetails.Clusters[Index]
                        ,FileDetails.Side,first=0);
    //So we can get the sector size
    secsize:=FDSKImage.Tracks[T>>8].Sectors[T AND$FF].Size;
    //Set the amount of data to transfer
    if Length(buffer)-ptr>=secsize then len:=secsize
                                   else len:=Length(buffer)-ptr;
    //And transfer it.
    for cnt:=0 to len-1 do buffer[ptr+cnt]:=ReadByte(offset+cnt);
    //Next block
    inc(ptr,len);
   end;
   //Next cluster
   inc(Index);
  end;
  //Now we remove the header, if any
  if(FileDetails.HeaderType=diSOFT968)
  or(FileDetails.HeaderType=diPLUS3DOS)then
  begin
   //Get the length (not including header)
   if FileDetails.HeaderType=diSOFT968 then len:=buffer[$18]+buffer[$19]<<8;
   if FileDetails.HeaderType=diPLUS3DOS then
    len:=buffer[$B]+buffer[$C]<<8+buffer[$D]<<16+buffer[$E]<<24;
   //Copy the data downwards
   for ptr:=$80 to Length(buffer)-1 do buffer[ptr-$80]:=buffer[ptr];
   //Reduce the length
   SetLength(buffer,len);
  end;
 end;
end;

//Form functions

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string
  );
var
 F     : TFileStream=nil;
 Index : Integer=0;
 Index1: Integer=0;
 T     : String='';
 C     : Integer=0;
 buffer: TDIByteArray=();
begin
 FFormat:=diInvalidImg;
 Memo1.Clear;
 Memo1.Lines.Add('File information');
 Memo1.Lines.Add('================');
 Memo1.Lines.Add('Filename            : '+ExtractFileName(FileNames[0]));
 F:=TFileStream.Create(FileNames[0],fmOpenRead or fmShareDenyNone);
 SetLength(FData,F.Size);
 F.Read(FData[0],F.Size);
 F.Free;
 Memo1.Lines.Add('File size           : '+IntToStr(GetDataLength));
 if ID_Sinclair then ReadDSK;
 if FFormat<>diInvalidImg then
 begin
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Header Information');
  Memo1.Lines.Add('==================');
  case(FFormat AND$F) of
   0: T:='Standard';
   1: T:='Extended';
   else T:='Not recognised';
  end;
  Memo1.Lines.Add('Format              : '+T);
  Memo1.Lines.Add('Creator             : '+FDSKImage.Creator);
  Memo1.Lines.Add('Tracks per side     : '+IntToStr(FDSKImage.NumTracks));
  Memo1.Lines.Add('Sides               : '+IntToStr(FDSKImage.Sides));
  if FDSKImage.Sides=1 then
   Memo1.Lines.Add('Reserved tracks     : '+IntToStr(FDSKImage.Reserved[Index]))
  else
  begin
   Memo1.Lines.Add('Reserved tracks (1) : '+IntToStr(FDSKImage.Reserved[0]));
   Memo1.Lines.Add('Reserved tracks (2) : '+IntToStr(FDSKImage.Reserved[1]));
  end;
  Memo1.Lines.Add('Calculated:');
  Memo1.Lines.Add('Total Capacity      : '+IntToStr(FDSKImage.Capacity)+' bytes');
  Memo1.Lines.Add('Used space          : '+IntToStr(FDSKImage.Used)+' bytes');
  C:=FDSKImage.Capacity-(Length(FDSKImage.Tracks)*$100);
  for Index:=0 to Length(FDSKImage.Tracks) do
   if FDSKImage.Tracks[Index].Boot then
    dec(C,FDSKImage.Tracks[Index].BootSize*FDSKImage.Tracks[Index].Sectors[0].Size);
  if FDSKImage.Reserved[0]>=0 then dec(C,FDSKImage.Tracks[0].Size);
  if FDSKImage.Reserved[1]>=0 then dec(C,FDSKImage.Tracks[FDSKImage.NumTracks].Size);
  Memo1.Lines.Add('Total usable space  : '+IntToStr(C)+' bytes');
  Memo1.Lines.Add('Boot Blocks         : '+IntToStr(FDSKImage.DataAreas));
  Memo1.Lines.Add('Capacity per area   : '+IntToStr(FDSKImage.Capacity div FDSKImage.DataAreas)+' bytes');
  Memo1.Lines.Add('Blocks per area     : '+IntToStr(FDSKImage.NumBlocks));
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Track information');
  Memo1.Lines.Add('*****************');
  for Index:=0 to Length(FDSKImage.Tracks)-1 do
  begin
   Memo1.Lines.Add('Internal Reference  : '+IntToStr(Index));
   if FDSKImage.Tracks[Index].Valid then
   begin
    Memo1.Lines.Add('Track               : '+IntToStr(FDSKImage.Tracks[Index].Number));
    Memo1.Lines.Add('Side                : '+IntToStr(FDSKImage.Tracks[Index].Side));
    Memo1.Lines.Add('Size                : 0x'+IntToHex(FDSKImage.Tracks[Index].Size,4));
    Memo1.Lines.Add('Sector Size         : 0x'+IntToHex(FDSKImage.Tracks[Index].Sector,4));
    Memo1.Lines.Add('Offset              : 0x'+IntToHex(FDSKImage.Tracks[Index].Offset,8));
    Memo1.Lines.Add('Filler              : 0x'+IntToHex(FDSKImage.Tracks[Index].Filler,2));
    if FDSKImage.Tracks[Index].Boot then T:='Yes' else T:='No';
    Memo1.Lines.Add('Boot Block?         : '+T);
    Memo1.Lines.Add('Sectors             : '+IntToStr(Length(FDSKImage.Tracks[Index].Sectors)));
    for Index1:=0 to Length(FDSKImage.Tracks[Index].Sectors)-1 do
    begin
     Memo1.Lines.Add('   Sector '+IntToStr(Index1));
     Memo1.Lines.Add('      ID            : 0x'+IntToHex(FDSKImage.Tracks[Index].Sectors[Index1].ID,2));
     Memo1.Lines.Add('      Offset        : 0x'+IntToHex(FDSKImage.Tracks[Index].Sectors[Index1].Offset,8));
     Memo1.Lines.Add('      Data Length   : 0x'+IntToHex(FDSKImage.Tracks[Index].Sectors[Index1].Size,4));
    end;
   end else Memo1.Lines.Add('Invalid Track Info');
   if Index<Length(FDSKImage.Tracks)-1 then Memo1.Lines.Add(StringOfChar('-',32));
   Application.ProcessMessages;
  end;
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Boot Blocks');
  Memo1.Lines.Add('===========');
  for Index:=0 to Length(FDSKImage.Tracks)-1 do
   if FDSKImage.Tracks[Index].Boot then
   begin
    Memo1.Lines.Add('Boot Block Location :  Track '+IntToStr(FDSKImage.Tracks[Index].Number));
    Memo1.Lines.Add('                        Side '+IntToStr(FDSKImage.Tracks[Index].Side));
    Memo1.Lines.Add('                      Offset 0x'+IntToHex(FDSKImage.Tracks[Index].Offset,8));
    Memo1.Lines.Add('Number of sectors   : '+IntToStr(FDSKImage.Tracks[Index].BootSize));
   end;
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Files');
  Memo1.Lines.Add('=====');
  Memo1.Lines.Add('Side|User|Filename    |Attributes|Length|Header|Clusters');
  Memo1.Lines.Add('----|----|------------|----------|------|------|--------------------------------');
  for Index1:=0 to Length(Files)-1 do
  begin
   T:=Files[Index1].Filename;
   if Files[Index1].Extension<>'' then
    T:=T+'.'+Files[Index1].Extension;
   T:=LeftStr(T+'            ',12);
   T:=' '+IntToStr(Files[Index1].Side)+'  | '
         +IntToHex(Files[Index1].UserNumber,2)+' |'
         +T+'|   ';
   if Files[Index1].ReadOnly then T:=T+'R'else T:=T+' ';
   if Files[Index1].Hidden   then T:=T+'H'else T:=T+' ';
   if Files[Index1].Archive  then T:=T+'A'else T:=T+' ';
   if Files[Index1].Deleted  then T:=T+'D'else T:=T+' ';
   T:=T+'   |0x'+IntToHex(Files[Index1].Length,4)+'|';
   case Files[Index1].HeaderType of
    diNone    : T:=T+' None |';
    diSOFT968 : T:=T+'AMSDOS|';
    diPLUS3DOS: T:=T+'+3 DOS|';
    else T:=T+'??????';
   end;
   for Index:=0 to Length(Files[Index1].Clusters)-1 do
   begin
    T:=T+'0x'+IntToHex(Files[Index1].Clusters[Index],4)+' : '
        +'0x'+IntToHex(GetDSKOffset(Files[Index1].Clusters[Index]
                                   ,Files[Index1].Side),8)+' & '
        +'0x'+IntToHex(GetDSKOffset(Files[Index1].Clusters[Index]
                                   ,Files[Index1].Side,False),8);
    Memo1.Lines.Add(T);
    T:='    |    |            |          |      |      |';
   end;
   Application.ProcessMessages;
{   ExtractSpectrumFile(Files[Index1],buffer);
   F:=TFileStream.Create('Users/geraldholdsworth/Downloads/'
                        +Files[Index1].Filename+'.'
                        +Files[Index1].Extension,fmCreate or fmShareDenyNone);
   F.Write(buffer[0],Length(buffer));
   F.Free;}
  end;
 end else Memo1.Lines.Add('Invalid image');
end;

end.

