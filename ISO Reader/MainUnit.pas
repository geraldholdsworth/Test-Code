unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
 StdCtrls, DateUtils;

type

 TDirEntry = record
  Parent    : String;
  Sector    : Cardinal;
  Filename  : String;
  DirRef    : Integer;
  TimeStamp : TDateTime;
  Attributes: String;
  Length    : Cardinal;
  LoadAddr  : Cardinal;
  ExecAddr  : Cardinal;
 end;

 TDir = record
  Directory: String;
  Sector   : Cardinal;
  Parent   : Word;
  Length   : Cardinal;
  Entries  : array of TDirEntry;
 end;

 TISOVolDes = record
  Offset      : Cardinal;
  SystemID    : String;
  VolumeID    : String;
  Size        : Cardinal;
  Joilet      : Byte;
  NumDiscs    : Cardinal;
  DiscNum     : Cardinal;
  BlckSize    : Cardinal;
  PathSize    : Cardinal;
  PathTbl     : array[0..1] of Cardinal;
  oPathTbl    : array[0..1] of Cardinal;
  RootOffset  : Cardinal;
  RootLength  : Cardinal;
  VolSetID    : String;
  PublisID    : String;
  DataPrID    : String;
  AppID       : String;
  CopyID      : String;
  AbstID      : String;
  BibliID     : String;
  DateCre     : TDateTime;
  DateMod     : TDateTime;
  DateExp     : TDateTime;
  DateUse     : TDateTime;
 end;

 { TMainForm }

 TMainForm = class(TForm)
   DropBox: TPanel;
   InfoBox: TMemo;
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
   //Generic methods in DiscImage
   function ReadString(offset: Cardinal; length: Integer;control: Boolean=True): String;
   function Read32b(offset: Cardinal; bigendian: Boolean=False): Cardinal;
   function Read16b(offset: Cardinal; bigendian: Boolean=False): Cardinal;
   function ReadByte(offset: Cardinal): Byte;
   function GetDataLength: Cardinal;
   procedure SetDataLength(newlen: Cardinal);
   //ISO Methods
   function ISOID: Boolean;
   procedure ISOReadImage;
   function ISOGetPVDDateTime(offset: Cardinal): TDateTime;
   procedure ISOReadVolumeDescriptors;
   procedure ISOGetVDAndPathToUse(var ISOVD2Use: Cardinal;var ISOpath2use: Cardinal);
   function ISOGetDirDateTime(offset: Cardinal): TDateTime;
   function ISOAttributes(attr: Cardinal): String;
   function ISOROAttributes(attr: Cardinal): String;
   function ISOGetFullPath(dir: Integer): String;
   procedure ISOChangeDirName(dir,entry: Cardinal);
   procedure ISOReadPathTable(VDNum: Cardinal; pth2use: Cardinal=0);
   procedure ISOReadDirectories(VDNum: Cardinal);
 private
  Fbuffer   : array of Byte;
  FDisc     : array of TDir;
  ISOVolDes : array of TISOVolDes;
  secsize   : Cardinal;
  root      : Cardinal;
  root_size : Cardinal;
  root_name : String;
 public

 end;

var
 MainForm: TMainForm;
const
 FDateFormat = 'hh:nn:ss.zzz dd/mm/yyyy';

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
 Lfile       : TFileStream=nil;
 index       : Integer=0;
 nument      : Cardinal=0;
 line        : String='';
begin
// Cursor:=crHourglass;
 DropBox.Caption:='Please Wait...';
 InfoBox.Clear;
 Lfile:=TFileStream.Create(FileNames[0],fmOpenRead OR fmShareDenyNone);
 Lfile.Position:=0;
 SetDataLength(Lfile.Size);
 Lfile.Read(Fbuffer[0],Lfile.Size);
 Lfile.Free;
 if ISOID then
 begin
  ISOReadImage;
  //Display results
  if Length(FDisc)>0 then
   for index:=0 to Length(FDisc)-1 do
   begin
    DropBox.Caption:='Progress: '+IntToStr(Round((index/Length(FDisc))*100))+'%';
    InfoBox.Lines.Add('Directory listing for "'+ISOGetFullPath(index)+'"'
                     +' at 0x'+IntToHex(FDisc[index].Sector*secsize,8)
                     +' (0x'+IntToHex(FDisc[index].Length,8)+' bytes)');
    InfoBox.Lines.Add('|-----|----------|-----------------------|------------|----------|------------------------------|----------|----------|');
    InfoBox.Lines.Add('|     |          |                       |            |          |                              |       RISC OS       |');
    InfoBox.Lines.Add('|Index|  Length  |    Date/Time Stamp    | Attributes |  Offset  |           Filename           |Load Addr |Exec Addr |');
    InfoBox.Lines.Add('|-----|----------|-----------------------|------------|----------|------------------------------|----------|----------|');
    if Length(FDisc[index].Entries)>0 then
     for nument:=0 to Length(FDisc[index].Entries)-1 do
      InfoBox.Lines.Add('|'+RightStr('00000'+IntToStr(nument),5)
                       +'|0x'+IntToHex(FDisc[index].Entries[nument].Length,8)
                       +'|'+FormatDateTime(FDateFormat,FDisc[index].Entries[nument].TimeStamp)
                       +'|'+FDisc[index].Entries[nument].Attributes
                       +'|0x'+IntToHex(FDisc[index].Entries[nument].Sector*secsize,8)
                       +'|'+LeftStr(FDisc[index].Entries[nument].Filename+StringOfChar(' ',30),30)
                       +'|0x'+IntToHex(FDisc[index].Entries[nument].LoadAddr,8)
                       +'|0x'+IntToHex(FDisc[index].Entries[nument].ExecAddr,8)+'|');
    InfoBox.Lines.Add('|-----|----------|-----------------------|------------|----------|------------------------------|----------|----------|');
    InfoBox.Lines.Add('');
    Application.ProcessMessages;
   end;
  InfoBox.Lines.SaveToFile(FileNames[0]+'.txt');
 end else InfoBox.Lines.Add('Image is not an ISO');
 DropBox.Caption:='Drop ISO file here';
end;

{ Generic methods already included in TDiscImage                               }

function TMainForm.ReadString(offset: Cardinal; length: Integer;control: Boolean=True): String;
var
 Lindex: Integer=0;
 LC    : Byte=0;
 lcon  : Byte=32;
begin
 Result:='';
 length:=abs(length);
 for Lindex:=0 to length-1 do
 begin
  LC:=Fbuffer[offset+Lindex];
  if LC=$A0 then LC:=$20;
  if(LC>Lcon-1)and(LC<127)then
   Result:=Result+chr(LC);
 end;
 Result:=Trim(Result);
end;

function TMainForm.Read32b(offset: Cardinal; bigendian: Boolean=False): Cardinal;
begin
 if bigendian then
  Result:=Fbuffer[offset+3]
         +Fbuffer[offset+2]<< 8
         +Fbuffer[offset+1]<<16
         +Fbuffer[offset  ]<<24
 else
  Result:=Fbuffer[offset  ]
         +Fbuffer[offset+1]<< 8
         +Fbuffer[offset+2]<<16
         +Fbuffer[offset+3]<<24;
end;

function TMainForm.Read16b(offset: Cardinal; bigendian: Boolean=False): Cardinal;
begin
 if bigendian then
  Result:=Fbuffer[offset+1]
         +Fbuffer[offset  ]<< 8
 else
  Result:=Fbuffer[offset  ]
         +Fbuffer[offset+1]<< 8;
end;

function TMainForm.ReadByte(offset: Cardinal): Byte;
begin
 Result:=FBuffer[offset];
end;

function TMainForm.GetDataLength: Cardinal;
begin
 Result:=Length(FBuffer);
end;

procedure TMainForm.SetDataLength(newlen: Cardinal);
begin
 SetLength(FBuffer,newlen);
end;

{ ISO Methods                                                                  }

function TMainForm.ISOID: Boolean;
var
 bvd   : Cardinal=0;
 vdst  : Cardinal=0;
 vpd   : Cardinal=0;
 index : Integer=0;
begin
 Result:=False;
 if GetDataLength>$8800 then
 begin
  //Find the Volume Descriptors
  index:=$10*$800;
  bvd  :=$00;            //Boot volume
  vdst :=$00;            //Set Terminator
  vpd  :=$00;            //Volume Partition Descriptor
  SetLength(ISOVolDes,0);//Volume Descriptors
  while(index<GetDataLength-6)and((Length(ISOVolDes)=0)or(vdst=$00))do
  begin
   //Look for 'CD001'
   if ReadString(index+1,-5)='CD001'then
   begin
    //Boot Record
    if ReadByte(index)=$00 then bvd:=index;//Currently not interested
    //Primary and supplimentary Volume Descriptors
    if(ReadByte(index)=$01)or(ReadByte(index)=$02)then
    begin
     SetLength(ISOVolDes,Length(ISOVolDes)+1);
     ISOVolDes[Length(ISOVolDes)-1].Offset:=index;
    end;
    //Volume Partition Descriptor
    if ReadByte(index)=$03 then vpd:=index;//Currently, not interested
    //Volume Descripter Set Terminator
    if ReadByte(index)=$FF then vdst:=index;
   end;
   inc(index);
  end;
  Result:=(Length(ISOVolDes)>0)and(vdst<>$00);
 end;
end;

procedure TMainForm.ISOReadImage;
var
 Lvdnum  : Cardinal=0;
 pth2use : Cardinal=0;
begin
 ISOReadVolumeDescriptors;
 ISOGetVDAndPathToUse(Lvdnum,pth2use);
 secsize  :=ISOVolDes[Lvdnum].BlckSize;
 root     :=ISOVolDes[Lvdnum].RootOffset;
 root_size:=ISOVolDes[Lvdnum].RootLength;
 root_name:='D:';
 ISOReadPathTable(Lvdnum,pth2use);
 ISOReadDirectories(Lvdnum);
end;

function TMainForm.ISOGetPVDDateTime(offset: Cardinal): TDateTime;
begin
 //Try to encode the date time
 //We're ignoring the timezone field as this usually gets ignored anyway
 if not TryEncodeDateTime(StrToIntDef(chr(ReadByte(offset   ))//Year
                                     +chr(ReadByte(offset+ 1))
                                     +chr(ReadByte(offset+ 2))
                                     +chr(ReadByte(offset+ 3)),1900)
                         ,StrToIntDef(chr(ReadByte(offset+ 4))//Month
                                     +chr(ReadByte(offset+ 5)),01)
                         ,StrToIntDef(chr(ReadByte(offset+ 6))//Day
                                     +chr(ReadByte(offset+ 7)),01)
                         ,StrToIntDef(chr(ReadByte(offset+ 8))//Hour
                                     +chr(ReadByte(offset+ 9)),00)
                         ,StrToIntDef(chr(ReadByte(offset+10))//Minute
                                     +chr(ReadByte(offset+11)),00)
                         ,StrToIntDef(chr(ReadByte(offset+12))//Second
                                     +chr(ReadByte(offset+13)),00)
                         ,StrToIntDef(chr(ReadByte(offset+14))//1/100ths second
                                     +chr(ReadByte(offset+15))+'0',000)
                         ,Result) then
  //Default return value, in case we don't get a valid date time
  Result:=EncodeDateTime(1900,01,01,00,00,00,000);
end;

procedure TMainForm.ISOReadVolumeDescriptors;
var
 vdnum : Integer=0;
begin
 if Length(ISOVolDes)>0 then
  for vdnum:=0 to Length(ISOVolDes)-1 do
  begin
   //System ID at $08
   ISOVolDes[vdnum].SystemID:=ReadString(ISOVolDes[vdnum].Offset+$08,-32);
   //Volume ID at $28
   ISOVolDes[vdnum].VolumeID:=ReadString(ISOVolDes[vdnum].Offset+$28,-32);
   //Logical blocks at $50
   ISOVolDes[vdnum].Size:=Read32b(ISOVolDes[vdnum].Offset+$50);
   //Joilet spec at $58:
   if (ReadByte(ISOVolDes[vdnum].Offset+$58)=$25)
   and(ReadByte(ISOVolDes[vdnum].Offset+$59)=$2F)
   and(ReadByte(ISOVolDes[vdnum].Offset+$5A)>>4=$4)then
    ISOVolDes[vdnum].Joilet:=((ReadByte(ISOVolDes[vdnum].Offset+$5A)AND$F)div 2)+1;
   //Volume size at $78
   ISOVolDes[vdnum].NumDiscs:=Read16b(ISOVolDes[vdnum].Offset+$78);
   //Volume number at $7C
   ISOVolDes[vdnum].DiscNum:=Read16b(ISOVolDes[vdnum].Offset+$7C);
   //Block size at $80
   ISOVolDes[vdnum].BlckSize:=Read16b(ISOVolDes[vdnum].Offset+$80);
   //Path size at $84
   ISOVolDes[vdnum].PathSize:=Read32b(ISOVolDes[vdnum].Offset+$84);
   //Path table at $8C
   ISOVolDes[vdnum].PathTbl[0]:=Read32b(ISOVolDes[vdnum].Offset+$8C);
   //Optional path table at $90
   ISOVolDes[vdnum].oPathTbl[0]:=Read32b(ISOVolDes[vdnum].Offset+$90);
   //M-Path table at $94
   ISOVolDes[vdnum].PathTbl[1]:=Read32b(ISOVolDes[vdnum].Offset+$94,True);
   //Optional m-path table at $98
   ISOVolDes[vdnum].oPathTbl[1]:=Read32b(ISOVolDes[vdnum].Offset+$98,True);
   //Root directory entry at $9C
   ISOVolDes[vdnum].RootOffset:=Read32b(ISOVolDes[vdnum].Offset+$9C+$2);
   ISOVolDes[vdnum].RootLength:=Read32b(ISOVolDes[vdnum].Offset+$9C+$A);
   //Volume Set Identifier at $BE
   ISOVolDes[vdnum].VolSetID:=ReadString(ISOVolDes[vdnum].Offset+$BE,-128);
   //Publisher Identifier at $13E
   ISOVolDes[vdnum].PublisID:=ReadString(ISOVolDes[vdnum].Offset+$13E,-128);
   //Data Preparer Identifier at $1BE
   ISOVolDes[vdnum].DataPrID:=ReadString(ISOVolDes[vdnum].Offset+$1BE,-128);
   //Application Identifier at $23E
   ISOVolDes[vdnum].AppID:=ReadString(ISOVolDes[vdnum].Offset+$23E,-128);
   //Copyright File Identifier at $2BE
   ISOVolDes[vdnum].CopyID:=ReadString(ISOVolDes[vdnum].Offset+$2BE,-37);
   //Abstract File Identifier at $2E3
   ISOVolDes[vdnum].AbstID:=ReadString(ISOVolDes[vdnum].Offset+$2E3,-37);
   //Bibliographic File Identifier at $308
   ISOVolDes[vdnum].BibliID:=ReadString(ISOVolDes[vdnum].Offset+$308,-37);
   //Volume Creation date at $32D
   ISOVolDes[vdnum].DateCre:=ISOGetPVDDateTime(ISOVolDes[vdnum].Offset+$32D);
   //Volume Modification date at $33E
   ISOVolDes[vdnum].DateMod:=ISOGetPVDDateTime(ISOVolDes[vdnum].Offset+$33E);
   //Volume Expiration date at $34F
   ISOVolDes[vdnum].DateExp:=ISOGetPVDDateTime(ISOVolDes[vdnum].Offset+$34F);
   //Volume Use after date at $360
   ISOVolDes[vdnum].DateUse:=ISOGetPVDDateTime(ISOVolDes[vdnum].Offset+$360);
  end;
end;

procedure TMainForm.ISOGetVDAndPathToUse(var ISOVD2Use: Cardinal;var ISOpath2use: Cardinal);
var
 index : Cardinal=0;
begin
 if Length(ISOVolDes)>0 then
 begin
  //Find the Joilet volume descriptor, or just default to the primary
  ISOVD2Use:=0;
  for index:=0 to Length(ISOVolDes)-1 do
   if ISOVolDes[index].Joilet>0 then ISOVD2Use:=index;
  //Now get the directories from the path table for the chosen volume descriptor
  ISOpath2use:=0; //Path table to use (0 or 1)
  while(ISOVolDes[ISOVD2Use].PathTbl[ISOpath2use]=0)and(ISOpath2use<2)do
   inc(ISOpath2use);
 end
 else
 begin
  ISOVD2Use  :=0;
  ISOpath2use:=0;
 end;
end;

function TMainForm.ISOGetDirDateTime(offset: Cardinal): TDateTime;
begin
 //Try to encode the date time
 //We're ignoring the timezone field as this usually gets ignored anyway
 if not TryEncodeDateTime(ReadByte(offset  )+1900//Year
                         ,ReadByte(offset+1)     //Month
                         ,ReadByte(offset+2)     //Day
                         ,ReadByte(offset+3)     //Hour
                         ,ReadByte(offset+4)     //Minute
                         ,ReadByte(offset+5)     //Second
                         ,000                    //Millisecond
                         ,Result) then
  //Default return value, in case we don't get a valid date time
  Result:=EncodeDateTime(1900,01,01,00,00,00,000);
end;

function TMainForm.ISOAttributes(attr: Cardinal): String;
begin
 Result:='';
 //bit 0 : Hidden
 if(attr AND 1)=1 then Result:=Result+'H' else Result:=Result+' ';
 //bit 1 : Directory
 if(attr AND 2)=2 then Result:=Result+'D' else Result:=Result+' ';
 //bit 2 : Associated
 if(attr AND 4)=4 then Result:=Result+'A' else Result:=Result+' ';
 //bit 3 : Extended attribute contains information
 //bit 4 : owner and group permissions in the extended attribute
 //bit 7 : not the final directory record for this file}
end;

function TMainForm.ISOROAttributes(attr: Cardinal): String;
begin
 Result:='';
 //bit 3 : Object is locked against deletion
 if attr AND $08=$08 then Result:=Result+'L' else Result:=Result+' ';
 //bit 1 : Object has write access ( owner )
 if attr AND $02=$02 then Result:=Result+'W' else Result:=Result+' ';
 //bit 0 : Object has read access  ( owner )
 if attr AND $01=$01 then Result:=Result+'R' else Result:=Result+' ';
 //bit 2 : Undefined
 if attr AND $04=$04 then Result:=Result+'E' else Result:=Result+' ';
 Result:=Result+'/';
 //bit 7 : Undefined
 if attr AND $80=$80 then Result:=Result+'l' else Result:=Result+' ';
 //bit 5 : Object has write access ( public )
 if attr AND $20=$20 then Result:=Result+'w' else Result:=Result+' ';
 //bit 4 : Object has read access  ( public )
 if attr AND $10=$10 then Result:=Result+'r' else Result:=Result+' ';
 //bit 6 : Undefined
 if attr AND $40=$40 then Result:=Result+'e' else Result:=Result+' ';
 //bit 8 : used by Leonardo to represent the ! in a name (not valid in ISO)}
end;

function TMainForm.ISOGetFullPath(dir: Integer): String;
begin
 Result:=FDisc[dir].Directory;
 while FDisc[dir].Parent<>dir do
 begin
  dir:=FDisc[dir].Parent;
  Result:=FDisc[dir].Directory+'/'+Result;
 end;
end;

procedure TMainForm.ISOChangeDirName(dir,entry: Cardinal);
begin
 if FDisc[dir].Entries[entry].DirRef>0 then
  FDisc[FDisc[dir].Entries[entry].DirRef].Directory:=
                                             FDisc[dir].Entries[entry].Filename;
end;

procedure TMainForm.ISOReadPathTable(VDNum: Cardinal; pth2use: Cardinal=0);
var
 ptr   : Cardinal=0;
 offset: Cardinal=0;
 index : Cardinal=0;
 nument: Cardinal=0;
 len   : Cardinal=0;
begin
 if pth2use<2 then
 begin
  ptr:=0;     //Pointer into the path table
  while ptr<ISOVolDes[VDNum].PathSize do
  begin
   offset:=ISOVolDes[VDNum].PathTbl[pth2use]*secsize;
   index:=Length(FDisc);
   SetLength(FDisc,index+1);
   //Directory reference
   //Length of directory name at offset $00
   len:=ReadByte(offset+ptr);
   //Block (where the directroy data is) at offset $02
   FDisc[index].Sector:=Read32b(offset+ptr+2,pth2use=1);
   //Parent at offset $06
   FDisc[index].Parent:=Read16b(offset+ptr+6,pth2use=1)-1;
   //Name at offset $08
   FDisc[index].Directory:=ReadString(offset+ptr+8,-len);
   if FDisc[index].Directory='' then FDisc[index].Directory:=root_name;
   //Length of root is in the volume descriptor
   if index=0 then FDisc[index].Length:=root_size;
   if FDisc[index].Parent<>index then
   begin
    offset:=FDisc[index].Parent;
    nument:=Length(FDisc[offset].Entries);
    SetLength(FDisc[offset].Entries,nument+1);
    FDisc[offset].Entries[nument].Parent  :=ISOGetFullPath(FDisc[index].Parent);
    FDisc[offset].Entries[nument].Sector  :=FDisc[index].Sector;
    FDisc[offset].Entries[nument].Filename:=FDisc[index].Directory;
    FDisc[offset].Entries[nument].DirRef  :=index;
   end;
   //Move to the next
   inc(ptr,8+len+(len mod 2));
  end;
 end;
end;

procedure TMainForm.ISOReadDirectories(VDNum: Cardinal);
var
 index  : Integer=0;
 ptr    : Cardinal=0;
 len    : Byte=0;
 entlen : Byte=0;
 flags  : Byte=0;
 nument : Cardinal=0;
 line   : String='';
 offset : Cardinal=0;
 roattr : Cardinal=0;
begin
 //Find all the directory entries
 for index:=0 to Length(FDisc)-1 do
 begin
  offset:=FDisc[index].Sector*secsize;
  ptr:=0;
  entlen:=$FF;
  while ptr<FDisc[index].Length do
  begin
   //Entry size at $00
   entlen:=ReadByte(offset+ptr);
   if entlen<>$0 then
   begin
    //Flags at $19
    flags:=ReadByte(offset+ptr+$19);
    //Length of filename at $20
    len:=ReadByte(offset+ptr+$20);
    //Filename at $21 (padded if even length, none if odd length)
    line:=ReadString(offset+ptr+$21,-len);
    if line<>'' then
    begin
     //Sometimes, filename is terminated with ';<file ID>'
     if line[Length(line)-1]=';' then SetLength(line,Length(line)-2);
     //Is a directory, so find the entry
     if(flags AND $2)=2 then
     begin
      nument:=0;
      while(nument<Length(FDisc[index].Entries))
        and(FDisc[index].Entries[nument].Filename<>line)do inc(nument);
     end
     //Not a directory, so add an entry
     else
     begin
      nument:=Length(FDisc[index].Entries);
      SetLength(FDisc[index].Entries,nument+1);
      //Do an insertion sort to keep them in alphabetical order
      while(nument>0)and(line<FDisc[index].Entries[nument-1].Filename)do
      begin
       FDisc[index].Entries[nument]:=FDisc[index].Entries[nument-1];
       dec(nument);
      end;
      //Fill in the blanks
      FDisc[index].Entries[nument].Parent:=ISOGetFullPath(index);
      FDisc[index].Entries[nument].DirRef:=-1; //Not a directory
     end;
     //Length of data at $0A
     FDisc[index].Entries[nument].Length:=Read32b(offset+ptr+$0A);
     if FDisc[index].Entries[nument].DirRef<>-1 then
      FDisc[FDisc[index].Entries[nument].DirRef].Length:=
                                   FDisc[index].Entries[nument].Length;
     //DateTime Stamp at $12
     FDisc[index].Entries[nument].TimeStamp:=
                                            ISOGetDirDateTime(offset+ptr+$12);
     //File Flags at $19 (already read above)
     FDisc[index].Entries[nument].Attributes:=ISOAttributes(flags);
     //Only change the next entries if not a directory
     if(flags AND $2)=0 then
     begin
      //Location of data at $02
      FDisc[index].Entries[nument].Sector:=Read32b(offset+ptr+$02);
      //Filename at $21 (padded if even length, none if odd length)
      FDisc[index].Entries[nument].Filename:=line; //Already read above
     end;
     //Attributes in the OS area ($21+filename length)
     if len mod 2=0 then inc(len);
     if (len+$21+$20=entlen)
     and(ReadString(offset+ptr+$21+len,-10)='ARCHIMEDES')then
     begin
      FDisc[index].Entries[nument].LoadAddr  :=Read32b(offset+ptr+$2B+len);
      FDisc[index].Entries[nument].ExecAddr  :=Read32b(offset+ptr+$2F+len);
      roattr                                 :=Read32b(offset+ptr+$33+len);
      FDisc[index].Entries[nument].Attributes:=
                                         FDisc[index].Entries[nument].Attributes
                                        +ISOROAttributes(roattr);
      //Bit 8 of the flags indicate filename should start with a '!'
      if(roattr AND $100)=$100 then
      begin
       FDisc[index].Entries[nument].Filename[1]:='!';
       //If a directory, we'll need to change the directory name too
       ISOChangeDirName(index,nument);
      end;
     end
     else
     begin
      FDisc[index].Entries[nument].LoadAddr:=0;
      FDisc[index].Entries[nument].ExecAddr:=0;
     end;
     //Is there a '.' as the last character of the filename?
     if RightStr(FDisc[index].Entries[nument].Filename,1)='.' then
     begin
      SetLength(FDisc[index].Entries[nument].Filename
               ,Length(FDisc[index].Entries[nument].Filename)-1);
      //If a directory, we'll need to change the directory name too
      ISOChangeDirName(index,nument);
     end;
    end;
   end;
   //Next entry
   inc(ptr,entlen);
   while(ReadByte(offset+ptr)=0)and(ptr<FDisc[index].Length)do inc(ptr);
  end;
 end;
end;

end.

