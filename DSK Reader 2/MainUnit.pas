unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type
 TSector = record
  ID        : Byte;
  Size      : Word;
  Offset    : Cardinal;
 end;
 TTrack = record
  Sectors   : array of TSector;
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
 TFiles = record
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
 end;

  { TMainForm }

  TMainForm = class(TForm)
   Panel1: TPanel;
   Memo1: TMemo;
   function GetDSKOffset(Cluster: Word;Side: Byte;First: Boolean=True): Cardinal;
   function CheckForBoot(Ptr: Cardinal; LData: array of Byte): Boolean;
   function ReadFile(LData: array of Byte): Boolean;
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
   FData      : array of Byte;
   DSKForm    : String;
   Creator    : String;
   NumTracks  : Word;
   Sides      : Byte;
   Tracks     : array of TTrack;
   Files      : array of TFiles;
   Capacity   : Cardinal;
   Used       : Cardinal;
   DataAreas  : Byte;
   NumBlocks  : Word;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

function TMainForm.GetDSKOffset(Cluster: Word;Side: Byte;First: Boolean=True): Cardinal;
var
 LTrack : Byte=0;
 LSector: Byte=0;
 F      : Byte=0;
begin
 if First then F:=0 else F:=1;
 Side:=Side mod 2;
 LTrack :=((Cluster*2)+F)DIV Length(Tracks[0].Sectors);
 LTrack :=LTrack+(NumTracks*Side);
 LSector:=((Cluster*2)+F)MOD Length(Tracks[0].Sectors);
 Result:=Tracks[LTrack].Sectors[LSector].Offset;
end;

function TMainForm.CheckForBoot(Ptr: Cardinal; LData: array of Byte): Boolean;
var
 LI: Integer=0;
begin
 Result:=((LData[Ptr   ]<$10)or(LData[Ptr   ]=$E5))
      and((LData[Ptr+$C]<$05)or(LData[Ptr+$C]=$E5));
 if Result then
  for LI:=$1 to $8 do
   Result:=(Result)and(LData[Ptr+LI]>$1F)and(LData[Ptr+LI]<$80);
end;

function TMainForm.ReadFile(LData: array of Byte): Boolean;
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
 Temp     : TFiles=();
begin
 Result:=False;
 //Check that the image is actually big enough for the header and first track info
 if Length(LData)>512 then
 begin
  DSKForm:='';
  Index:=0;
  //Get the signature from the top
  while(Index<$21)and(DSKForm<>'EXTENDED CPC DSK')and(DSKForm<>'MV - CPCEMU')do
  begin
   if(LData[Index]>31)and(LData[Index]<127)then
    DSKForm:=DSKForm+Chr(LData[Index]);
   inc(Index);
  end;
  //Is it a valid one (that we recognise)?
  if(DSKForm='EXTENDED CPC DSK')or(DSKForm='MV - CPCEMU')then
  begin
   //Get the creator
   Creator:='';
   for Index:=$22 to $2F do
    if(LData[Index]>31)and(LData[Index]<127)then
     Creator:=Creator+Chr(LData[Index]);
   NumTracks:=LData[$30]; //Number of tracks per side
   Sides    :=LData[$31]; //Number of tracks
   //Valid number of tracks?
   if(Sides>0)and(Sides<3)then
   begin
    //Reset some counters
    Capacity :=0;
    DataAreas:=0;
    //Set up the container for the track information
    SetLength(Tracks,NumTracks*Sides);
    Ptr:=$100;
    //Get the track information
    for Ref:=0 to Length(Tracks)-1 do
    begin
     //Tracks are stored interleaved, but we'll have them linear
     Index:=(Ref MOD Sides)*NumTracks+(Ref DIV Sides);
     //Track size
     if DSKForm='MV - CPCEMU' then Tracks[Index].Size:=LData[$33]<<8+LData[$32]
                              else Tracks[Index].Size:=LData[$34+Index]<<8;
     //Add this to the total capacity
     inc(Capacity,Tracks[Index].Size);
     //Make a note of the offset for this track
     Tracks[Index].Offset:=Ptr;
     //Make sure the track info signature is valid
     TrackID:='';
     for Index1:=$00 to $0B do TrackID:=TrackID+Chr(LData[Ptr+Index1]);
     if TrackID='Track-Info'#$0D#$0A then
     begin
      Tracks[Index].Boot  :=CheckForBoot(Ptr+$100,LData);//Boot block?
      if Tracks[Index].Boot then inc(DataAreas);         //Add this to our counter
      Tracks[Index].Number:=LData[Ptr+$10];              //Track number
      Tracks[Index].Side  :=LData[Ptr+$11];              //Side it is on
      Tracks[Index].Sector:=LData[Ptr+$14]<<8;           //Size of each sector
      Tracks[Index].Filler:=LData[Ptr+$17];              //Filler byte
      Tracks[Index].Valid :=True;                        //It is a valid track
      //Set up the container for the sectors
      SetLength(Tracks[Index].Sectors,LData[Ptr+$15]);
      //Get the Sector ID Base
      IDBase:=LData[Ptr+$18+$2];
      //Now read the sector information for this track
      for Index1:=0 to Length(Tracks[Index].Sectors)-1 do
      begin
       //Valid sector?
       if (LData[Ptr+$18+Index1*$8+$3]=LData[Ptr+$14])     //Sector size match
       and(LData[Ptr+$18+Index1*$8+$0]=LData[Ptr+$10])     //Track number match
       and(LData[Ptr+$18+Index1*$8+$1]=LData[Ptr+$11])then //Side number match
       begin
        //Sector ID
        S:=LData[Ptr+$18+Index1*$8+$2];
        //We need to make sure it is not a duplicate
        if Tracks[Index].Sectors[S-IDBase].ID<>S then
         Tracks[Index].Sectors[S-IDBase].ID:=S
        else
        begin //Otherwise, we'll need to add it to the end
         Tracks[Index].Sectors[Index1].ID:=S;
         S:=Index1+IDBase;
        end;
        //Each sector information contains it's own size
        Tracks[Index].Sectors[S-IDBase].Size:=LData[Ptr+$18+Index1*$8+$7]<<8
                                             +LData[Ptr+$18+Index1*$8+$6];
        //Work out the offset - this is based on the track information
        Tracks[Index].Sectors[S-IDBase].Offset:=Tracks[Index].Offset+$100
                                               +Index1*Tracks[Index].Sector;
       end;
      end;
      //Move the offset along
      inc(Ptr,Tracks[Index].Size);
     end else Tracks[Index].Valid:=False; //Invalid track
    end;
    NumBlocks:=(Capacity div DataAreas)div$400; //Calculate the total number of blocks
    //Read in the boot blocks
    DirTrack:=0;
    Used:=0;
    //So we go through the tracks and find the ones with boot blocks
    while DirTrack<Length(Tracks) do
    begin
     if Tracks[DirTrack].Boot then
     begin
      //Where are we?
      Ptr:=Tracks[DirTrack].Sectors[DirSector].Offset;
      DirSector:=0; //Sector counter
      Tracks[DirTrack].BootSize:=1;
      //Read in the data (which could span multiple sectors)
      while(CheckForBoot(Ptr,LData))and(Ptr<Length(FData))do
      begin
       //Get the filename, ignoring all spaces
       Temp.Filename:='';
       for Index:=1 to $8 do
        if(LData[Ptr+Index]>32)and(LData[Ptr+Index]<127)then
         Temp.Filename:=Temp.Filename+Chr(LData[Ptr+Index]);
       //Now get the extension, removing the top bit and ignoring spaces
       Temp.Extension:='';
       for Index:=$9 to $B do
        if LData[Ptr+Index]AND$7F>32 then
         Temp.Extension:=Temp.Extension+Chr(LData[Ptr+Index]AND$7F);
       //Check the extent is zero (user number of 0xE5 means a deleted file)
       if(LData[Ptr+$C]=$00)or(LData[Ptr]=$E5)then
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
       Files[Index1].UserNumber:=LData[Ptr];               //User number (<16)
       Files[Index1].Filename  :=Temp.Filename;            //Filename
       Files[Index1].ReadOnly  :=(LData[Ptr+$9]AND$80)=$80;//Read only flag
       Files[Index1].Hidden    :=(LData[Ptr+$A]AND$80)=$80;//Hidden flag
       Files[Index1].Archive   :=(LData[Ptr+$B]AND$80)=$80;//Archived flag
       Files[Index1].Deleted   :=(LData[Ptr   ]       =$E5)
                               or(LData[Ptr+$C]       =$E5);//Deleted?
       Files[Index1].Extension :=Temp.Extension;            //Extension
       Files[Index1].Length    :=Files[Index1].Length+LData[Ptr+$F]*$80;//Reported length
       Files[Index1].Side      :=Tracks[DirTrack].Side;     //Which side is it on?
       //Calculate the used space
       if not Files[Index1].Deleted then inc(Used,LData[Ptr+$F]*$80);
       //Read in the clusters
       Index:=$10;
       //Are we reading them as 8-bit or 16-bit values?
       if NumBlocks<256 then S:=0 else S:=1;
       //So, read them until we reach the end or find a 'hole'
       while(Index<$20)and((LData[Ptr+Index+S]<<(8*S)OR LData[Ptr+Index])<>$00)do
       begin
        //Add new entry
        Ref:=Length(Files[Index1].Clusters);
        SetLength(Files[Index1].Clusters,Ref+1);
        Files[Index1].Clusters[Ref]:=LData[Ptr+Index+S]<<(8*S)
                                  OR LData[Ptr+Index];
        //Next entry
        inc(Index,S+1);
       end;
       //Next file
       Inc(Ptr,$20);
       //End of sector?
       if Ptr>=Tracks[DirTrack].Sectors[DirSector].Offset
              +Tracks[DirTrack].Sectors[DirSector].Size then
       begin
        //Next sector
        inc(DirSector);
        inc(Tracks[DirTrack].BootSize);
        //Which could be the next track
        if DirSector>Length(Tracks[DirTrack].Sectors) then
        begin
         inc(DirTrack);
         DirSector:=0;
        end;
        //Get the offset for this sector
        Ptr:=Tracks[DirTrack].Sectors[DirSector].Offset;
       end;
      end;
     end;
     //Check next track
     inc(DirTrack);
    end;
    Result:=True; //Valid signature and valid number of sides
   end;
  end;
 end;
end;

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string
  );
var
 F     : TFileStream=nil;
 Index : Integer=0;
 Index1: Integer=0;
 T     : String='';
 C     : Integer=0;
begin
 Memo1.Clear;
 Memo1.Lines.Add('File information');
 Memo1.Lines.Add('================');
 Memo1.Lines.Add('Filename            : '+ExtractFileName(FileNames[0]));
 F:=TFileStream.Create(FileNames[0],fmOpenRead or fmShareDenyNone);
 SetLength(FData,F.Size);
 F.Read(FData[0],F.Size);
 F.Free;
 Memo1.Lines.Add('File size           : '+IntToStr(Length(FData)));
 if ReadFile(FData) then
 begin
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Header Information');
  Memo1.Lines.Add('==================');
  Memo1.Lines.Add('Format              : '+DSKForm);
  Memo1.Lines.Add('Creator             : '+Creator);
  Memo1.Lines.Add('Tracks per side     : '+IntToStr(NumTracks));
  Memo1.Lines.Add('Sides               : '+IntToStr(Sides));
  Memo1.Lines.Add('Calculated:');
  Memo1.Lines.Add('Total Capacity      : '+IntToStr(Capacity)+' bytes');
  Memo1.Lines.Add('Used space          : '+IntToStr(Used)+' bytes');
  C:=Capacity-(Length(Tracks)*$100);
  for Index:=0 to Length(Tracks) do
   if Tracks[Index].Boot then dec(C,Tracks[Index].BootSize*Tracks[Index].Size);
  Memo1.Lines.Add('Total usable space  : '+IntToStr(C)+' bytes');
  Memo1.Lines.Add('Boot Blocks         : '+IntToStr(DataAreas));
  Memo1.Lines.Add('Capacity per area   : '+IntToStr(Capacity div DataAreas)+' bytes');
  Memo1.Lines.Add('Blocks per area     : '+IntToStr(NumBlocks));
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Track information');
  Memo1.Lines.Add('*****************');
  for Index:=0 to Length(Tracks)-1 do
  begin
   Memo1.Lines.Add('Internal Reference  : '+IntToStr(Index));
   if Tracks[Index].Valid then
   begin
    Memo1.Lines.Add('Track               : '+IntToStr(Tracks[Index].Number));
    Memo1.Lines.Add('Side                : '+IntToStr(Tracks[Index].Side));
    Memo1.Lines.Add('Size                : 0x'+IntToHex(Tracks[Index].Size,4));
    Memo1.Lines.Add('Sector Size         : 0x'+IntToHex(Tracks[Index].Sector,4));
    Memo1.Lines.Add('Offset              : 0x'+IntToHex(Tracks[Index].Offset,8));
    Memo1.Lines.Add('Filler              : 0x'+IntToHex(Tracks[Index].Filler,2));
    if Tracks[Index].Boot then T:='Yes' else T:='No';
    Memo1.Lines.Add('Boot Block?         : '+T);
    Memo1.Lines.Add('Sectors             : '+IntToStr(Length(Tracks[Index].Sectors)));
    for Index1:=0 to Length(Tracks[Index].Sectors)-1 do
    begin
     Memo1.Lines.Add('   Sector '+IntToStr(Index1));
     Memo1.Lines.Add('      ID            : 0x'+IntToHex(Tracks[Index].Sectors[Index1].ID,2));
     Memo1.Lines.Add('      Offset        : 0x'+IntToHex(Tracks[Index].Sectors[Index1].Offset,8));
     Memo1.Lines.Add('      Data Length   : 0x'+IntToHex(Tracks[Index].Sectors[Index1].Size,4));
    end;
   end else Memo1.Lines.Add('Invalid Track Info');
   if Index<Length(Tracks)-1 then Memo1.Lines.Add(StringOfChar('-',32));
   Application.ProcessMessages;
  end;
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Boot Blocks');
  Memo1.Lines.Add('===========');
  for Index:=0 to Length(Tracks)-1 do
   if Tracks[Index].Boot then
   begin
    Memo1.Lines.Add('Boot Block Location :  Track '+IntToStr(Tracks[Index].Number));
    Memo1.Lines.Add('                        Side '+IntToStr(Tracks[Index].Side));
    Memo1.Lines.Add('                      Offset 0x'+IntToHex(Tracks[Index].Offset,8));
    Memo1.Lines.Add('Number of sectors   : '+IntToStr(Tracks[Index].BootSize));
   end;
  Memo1.Lines.Add(StringOfChar('*',40));
  Memo1.Lines.Add('Files');
  Memo1.Lines.Add('=====');
  Memo1.Lines.Add('Side|User|Filename    |Attributes|Length|Clusters');
  Memo1.Lines.Add('----|----|------------|----------|------|--------------------------------');
  for Index1:=0 to Length(Files)-1 do
  begin
   T:=Files[Index1].Filename;
   if Files[Index1].Extension<>'' then
    T:=T+'.'+Files[Index1].Extension;
   T:=LeftStr(T+'            ',12);
   T:=IntToStr(Files[Index1].Side)+'   |'
     +IntToHex(Files[Index1].UserNumber,2)+'  |'+T+'|';
   if Files[Index1].ReadOnly then T:=T+'R'else T:=T+' ';
   if Files[Index1].Hidden   then T:=T+'H'else T:=T+' ';
   if Files[Index1].Archive  then T:=T+'A'else T:=T+' ';
   if Files[Index1].Deleted  then T:=T+'D'else T:=T+' ';
   T:=T+'      |0x'+IntToHex(Files[Index1].Length,4)+'|';
   for Index:=0 to Length(Files[Index1].Clusters)-1 do
   begin
    T:=T+'0x'+IntToHex(Files[Index1].Clusters[Index],4)+' : '
        +'0x'+IntToHex(GetDSKOffset(Files[Index1].Clusters[Index]
                                   ,Files[Index1].Side),8)+' & '
        +'0x'+IntToHex(GetDSKOffset(Files[Index1].Clusters[Index]
                                   ,Files[Index1].Side,False),8);
    Memo1.Lines.Add(T);
    T:='    |    |            |          |      |';
   end;
   Application.ProcessMessages;
  end;
 end else Memo1.Lines.Add('Invalid image');
end;

end.

