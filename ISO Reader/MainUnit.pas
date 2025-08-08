unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
 StdCtrls;

type

 TEntry = record
  Parent  : Word;
  Block   : Cardinal;
  Name    : String;
  DirRef  : Integer;
  DateTime: String;
  Attr    : String;
  Length  : Cardinal;
  Load    : Cardinal;
  Exec    : Cardinal;
  ROAttr  : String;
 end;

 TDirectory = record
  Name   : String;
  Block  : Cardinal;
  Parent : Word;
  Entries: array of TEntry;
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
  VolSetID    : String;
  PublisID    : String;
  DataPrID    : String;
  AppID       : String;
  CopyID      : String;
  AbstID      : String;
  BibliID     : String;
  DateCre     : String;
  DateMod     : String;
  DateExp     : String;
  DateUse     : String;
 end;

 { TMainForm }

 TMainForm = class(TForm)
   DropBox: TPanel;
   InfoBox: TMemo;
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
 private
  Fbuffer: array of Byte;
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
 Lfile       : TFileStream=nil;
 index       : Integer=0;
 voldes      : array of TISOVolDes=();
 vdnum       : Cardinal=0;
 bvd         : Cardinal=0;
 vdst        : Cardinal=0;
 iso         : Boolean=False;
 ptr         : Cardinal=0;
 pth2use     : Byte=0;
 len         : Byte=0;
 entlen      : Byte=0;
 flags       : Byte=0;
 nument      : Cardinal=0;
 line        : String='';
 offset      : Cardinal=0;
 Directories : array of TDirectory=();
 function GetPVDDateTime(vd,offset: Cardinal): String;
 var
  timezone: Real=0;
  Lindex  : Byte=0;
  ok      : Byte=0;
 begin
  for Lindex:=0 to 15 do if Fbuffer[vd+offset+Lindex]=$30 then inc(ok);
  if ok<16 then
  begin
   Result:=chr(Fbuffer[vd+offset+ 8])//Hour
          +chr(Fbuffer[vd+offset+ 9])
          +':'
          +chr(Fbuffer[vd+offset+10])//Minute
          +chr(Fbuffer[vd+offset+11])
          +':'
          +chr(Fbuffer[vd+offset+12])//Second
          +chr(Fbuffer[vd+offset+13])
          {+'.'
          +chr(Fbuffer[vd+offset+14])//1/100ths second
          +chr(Fbuffer[vd+offset+15])}
          +' '
          +chr(Fbuffer[vd+offset+6])//Day
          +chr(Fbuffer[vd+offset+7])
          +'/'
          +chr(Fbuffer[vd+offset+4])//Month
          +chr(Fbuffer[vd+offset+5])
          +'/'
          +chr(Fbuffer[vd+offset  ])//Year
          +chr(Fbuffer[vd+offset+1])
          +chr(Fbuffer[vd+offset+2])
          +chr(Fbuffer[vd+offset+3])
          +' GMT';
   timezone:=((Fbuffer[vd+offset+16]-48)*15)/60;
   if timezone<0 then Result:=Result+FloatToStr(timezone)
   else Result:=Result+'+'+FloatToStr(timezone);
  end else Result:='** not specified **';
 end;
 function GetDirDateTime(vd,offset: Cardinal): String;
 var
  timezone: Real=0;
 begin
  Result:=RightStr('00'+IntToStr(Fbuffer[vd+offset+3]),2)//Hour
         +':'
         +RightStr('00'+IntToStr(Fbuffer[vd+offset+4]),2)//Minute
         +':'
         +RightStr('00'+IntToStr(Fbuffer[vd+offset+5]),2)//Second
         +' '
         +RightStr('00'+IntToStr(Fbuffer[vd+offset+2]),2)//Day
         +'/'
         +RightStr('00'+IntToStr(Fbuffer[vd+offset+1]),2)//Month
         +'/'
         +IntToStr(Fbuffer[vd+offset  ]+1900)//Year
         +' GMT';
  timezone:=((Fbuffer[vd+offset+6]-48)*15)/60;
  if timezone<0 then Result:=Result+FloatToStr(timezone)
  else Result:=Result+'+'+FloatToStr(timezone);
 end;
 function ReadString(vd,offset: Cardinal; length: Cardinal;
                                   blank: String='** not specified **'): String;
 var
  Lindex: Integer=0;
  LC    : Byte=0;
 begin
  Result:='';
  for Lindex:=0 to length-1 do
  begin
   LC:=Fbuffer[vd+offset+Lindex];
   if LC=$A0 then LC:=$20;
   if(LC>31)and(LC<127)then
    Result:=Result+chr(LC);
  end;
  Result:=Trim(Result);
  if Result='' then Result:=blank;
 end;
 function Read32bit(vd,offset: Cardinal; bigendian: Boolean=False): Cardinal;
 begin
  if bigendian then
   Result:=Fbuffer[vd+offset+3]
          +Fbuffer[vd+offset+2]<< 8
          +Fbuffer[vd+offset+1]<<16
          +Fbuffer[vd+offset  ]<<24
  else
   Result:=Fbuffer[vd+offset  ]
          +Fbuffer[vd+offset+1]<< 8
          +Fbuffer[vd+offset+2]<<16
          +Fbuffer[vd+offset+3]<<24;
 end;
 function Read16bit(vd,offset: Cardinal; bigendian: Boolean=False): Cardinal;
 begin
  if bigendian then
   Result:=Fbuffer[vd+offset+1]
          +Fbuffer[vd+offset  ]<< 8
  else
   Result:=Fbuffer[vd+offset  ]
          +Fbuffer[vd+offset+1]<< 8;
 end;
 function Attributes(attr: Cardinal): String;
 begin
  Result:='';
  if(attr AND 1)=1 then Result:=Result+'H' else Result:=Result+' ';//bit 0 : Hidden
  if(attr AND 2)=2 then Result:=Result+'D' else Result:=Result+' ';//bit 1 : Directory
  if(attr AND 4)=4 then Result:=Result+'A' else Result:=Result+' ';//bit 2 : Associated
  {bit 3 : Extended attribute contains information
   bit 4 : owner and group permissions in the extended attribute
   bit 7 : not the final directory record for this file}
 end;
 function ROAttributes(attr: Cardinal): String;
 begin
  Result:='';
  if attr AND $08=$08 then Result:=Result+'L' else Result:=Result+' ';
  if attr AND $02=$02 then Result:=Result+'W' else Result:=Result+' ';
  if attr AND $01=$01 then Result:=Result+'R' else Result:=Result+' ';
  if attr AND $04=$04 then Result:=Result+'E' else Result:=Result+' ';
  Result:=Result+'/';
  if attr AND $80=$80 then Result:=Result+'l' else Result:=Result+' ';
  if attr AND $20=$20 then Result:=Result+'w' else Result:=Result+' ';
  if attr AND $10=$10 then Result:=Result+'r' else Result:=Result+' ';
  if attr AND $40=$40 then Result:=Result+'e' else Result:=Result+' ';
 end;
 function GetFullPath(dir: Integer): String;
 begin
  Result:=Directories[dir].Name;
  while Directories[dir].Parent<>dir do
  begin
   dir:=Directories[dir].Parent;
   Result:=Directories[dir].Name+'/'+Result;
  end;
 end;
begin
// Cursor:=crHourglass;
 DropBox.Caption:='Please Wait...';
 InfoBox.Clear;
 Lfile:=TFileStream.Create(FileNames[0],fmOpenRead OR fmShareDenyNone);
 Lfile.Position:=0;
 SetLength(Fbuffer,Lfile.Size);
 Lfile.Read(Fbuffer[0],Lfile.Size);
 Lfile.Free;
 if Length(Fbuffer)>$8800 then
 begin
  //Find the Volume Descriptors
  index:=$10*$800;
  bvd  :=$00;      //Boot volume
  vdst :=$00;      //Set Terminator
  SetLength(voldes,0);//Volume Descriptors
  while(index<Length(Fbuffer)-6)and((Length(voldes)=0)or(vdst=$00))do
  begin
   //Look for 'CD001'
   if (Fbuffer[index+1]=$43)
   and(Fbuffer[index+2]=$44)
   and(Fbuffer[index+3]=$30)
   and(Fbuffer[index+4]=$30)
   and(Fbuffer[index+5]=$31)then
   begin
    //Boot Record
    if Fbuffer[index]=$00 then bvd:=index;
    //Primary and supplimentary Volume Descriptors
    if(Fbuffer[index]=$01)or(Fbuffer[index]=$02)then
    begin
     SetLength(voldes,Length(voldes)+1);
     voldes[Length(voldes)-1].Offset:=index;
    end;
    //Volume Partition Descriptor
    if Fbuffer[index]=$03 then;//Currently, not interested
    //Volume Descripter Set Terminator
    if Fbuffer[index]=$FF then vdst:=index;
   end;
   inc(index);
  end;
  iso:=(Length(voldes)>0)and(vdst<>$00);
  //Read the Volume Descriptors
  if iso then
  begin
   for vdnum:=0 to Length(voldes)-1 do
   begin
    //System ID at $08
    voldes[vdnum].SystemID:=ReadString(voldes[vdnum].Offset,$08,32);
    //Volume ID at $28
    voldes[vdnum].VolumeID:=ReadString(voldes[vdnum].Offset,$28,32);
    //Logical blocks at $50
    voldes[vdnum].Size:=Read32bit(voldes[vdnum].Offset,$50);
    //Joilet spec at $58:
    if (Fbuffer[voldes[vdnum].Offset+$58]=$25)
    and(Fbuffer[voldes[vdnum].Offset+$59]=$2F)
    and(Fbuffer[voldes[vdnum].Offset+$5A]>>4=$4)then
     voldes[vdnum].Joilet:=((Fbuffer[voldes[vdnum].Offset+$5A]AND$F)div 2)+1;
    //Volume size at $78
    voldes[vdnum].NumDiscs:=Read16bit(voldes[vdnum].Offset,$78);
    //Volume number at $7C
    voldes[vdnum].DiscNum:=Read16bit(voldes[vdnum].Offset,$7C);
    //Block size at $80
    voldes[vdnum].BlckSize:=Read16bit(voldes[vdnum].Offset,$80);
    //Path size at $84
    voldes[vdnum].PathSize:=Read32bit(voldes[vdnum].Offset,$84);
    //Path table at $8C
    voldes[vdnum].PathTbl[0]:=Read32bit(voldes[vdnum].Offset,$8C);
    //Optional path table at $90
    voldes[vdnum].oPathTbl[0]:=Read32bit(voldes[vdnum].Offset,$90);
    //M-Path table at $94
    voldes[vdnum].PathTbl[1]:=Read32bit(voldes[vdnum].Offset,$94,True);
    //Optional m-path table at $98
    voldes[vdnum].oPathTbl[1]:=Read32bit(voldes[vdnum].Offset,$98,True);
    //Volume Set Identifier at $BE
    voldes[vdnum].VolSetID:=ReadString(voldes[vdnum].Offset,$BE,128);
    //Publisher Identifier at $13E
    voldes[vdnum].PublisID:=ReadString(voldes[vdnum].Offset,$13E,128);
    //Data Preparer Identifier at $1BE
    voldes[vdnum].DataPrID:=ReadString(voldes[vdnum].Offset,$1BE,128);
    //Application Identifier at $23E
    voldes[vdnum].AppID:=ReadString(voldes[vdnum].Offset,$23E,128);
    //Copyright File Identifier at $2BE
    voldes[vdnum].CopyID:=ReadString(voldes[vdnum].Offset,$2BE,37);
    //Abstract File Identifier at $2E3
    voldes[vdnum].AbstID:=ReadString(voldes[vdnum].Offset,$2E3,37);
    //Bibliographic File Identifier at $308
    voldes[vdnum].BibliID:=ReadString(voldes[vdnum].Offset,$308,37);
    //Volume Creation date at $32D
    voldes[vdnum].DateCre:=GetPVDDateTime(voldes[vdnum].Offset,$32D);
    //Volume Modification date at $33E
    voldes[vdnum].DateMod:=GetPVDDateTime(voldes[vdnum].Offset,$33E);
    //Volume Expiration date at $34F
    voldes[vdnum].DateExp:=GetPVDDateTime(voldes[vdnum].Offset,$34F);
    //Volume Use after date at $360
    voldes[vdnum].DateUse:=GetPVDDateTime(voldes[vdnum].Offset,$360);
   end;
   //Find the Joilet volume descriptor, or just default to the primary
   vdnum:=0;
   for index:=0 to Length(voldes)-1 do if voldes[index].Joilet>0 then vdnum:=index;
   //Now get the directories from the path table (but only for one of the volume descriptors)
   pth2use:=0; //Path table to use (0 or 1)
   while(voldes[vdnum].PathTbl[pth2use]=0)and(pth2use<2)do inc(pth2use);
   //If 2, then no path table available
   if pth2use<2 then
   begin
    ptr:=0;     //Pointer into the path table
    while ptr<voldes[vdnum].PathSize do
    begin
     offset:=voldes[vdnum].PathTbl[pth2use]*voldes[vdnum].BlckSize;
     index:=Length(Directories);
     SetLength(Directories,index+1);
     //Directory reference
     //Length of directory name at offset $00
     len:=Fbuffer[offset+ptr];
     //Block (where the directroy data is) at offset $02
     Directories[index].Block:=Read32bit(offset+ptr,2,pth2use=1);
     //Parent at offset $06
     Directories[index].Parent:=Read16bit(offset+ptr,6,pth2use=1)-1;
     //Name at offset $08
     Directories[index].Name:=ReadString(offset+ptr,8,len,'D:');
     if Directories[index].Parent<>index then
     begin
      offset:=Directories[index].Parent;
      bvd:=Length(Directories[offset].Entries);
      SetLength(Directories[offset].Entries,bvd+1);
      Directories[offset].Entries[bvd].Parent  :=Directories[index].Parent;
      Directories[offset].Entries[bvd].Block   :=Directories[index].Block;
      Directories[offset].Entries[bvd].Name    :=Directories[index].Name;
      Directories[offset].Entries[bvd].DirRef  :=index;
      Directories[offset].Entries[bvd].DateTime:=voldes[vdnum].DateCre;
      Directories[offset].Entries[bvd].Attr    :=' D ';
      Directories[offset].Entries[bvd].Length  :=voldes[vdnum].BlckSize;
     end;
     //Move to the next
     inc(ptr,8+len+(len mod 2));
    end;
    //Find all the directory entries
    for index:=0 to Length(Directories)-1 do
    begin
     offset:=Directories[index].Block*voldes[vdnum].BlckSize;
     ptr:=0;
     entlen:=$FF;
     while entlen<>$0 do
     begin
      //Entry size at $00
      entlen:=Fbuffer[offset+ptr];
      if entlen<>$0 then
      begin
       //Flags at $19
       flags:=Fbuffer[offset+ptr+$19];
       //Length of filename at $20
       len:=Fbuffer[offset+ptr+$20];
       //Filename at $21 (padded if even length, none if odd length)
       line:=ReadString(offset+ptr,$21,len,'.');
       if line<>'.' then
       begin
        //Is a directory, so find the entry
        if(flags AND $2)=2 then
        begin
         nument:=0;
         while(nument<Length(Directories[index].Entries))
           and(Directories[index].Entries[nument].Name<>line)do inc(nument);
        end
        //Not a directory, so add an entry
        else
        begin
         nument:=Length(Directories[index].Entries);
         SetLength(Directories[index].Entries,nument+1);
         //Do an insertion sort to keep them in alphabetical order
         while(nument>0)and(line<Directories[index].Entries[nument-1].Name)do
         begin
          Directories[index].Entries[nument]:=Directories[index].Entries[nument-1];
          dec(nument);
         end;
         //Fill in the blanks
         Directories[index].Entries[nument].Parent:=index;
         Directories[index].Entries[nument].DirRef:=-1; //Not a directory
        end;
        //Length of data at $0A
        Directories[index].Entries[nument].Length:=Read32bit(offset+ptr,$0A
                                                            ,False);
        //DateTime Stamp at $12
        Directories[index].Entries[nument].DateTime:=GetDirDateTime(offset+ptr
                                                                   ,$12);
        //File Flags at $19 (already read above)
        Directories[index].Entries[nument].Attr:=Attributes(flags);
        //Only change the next entries if not a directory
        if(flags AND $2)=0 then
        begin
         //Location of data at $02
         Directories[index].Entries[nument].Block:=Read32bit(offset+ptr
                                                            ,$02
                                                            ,False);
         //Filename at $21 (padded if even length, none if odd length)
         Directories[index].Entries[nument].Name:=ReadString(offset+ptr,$21,len);
        end;
        //Attributes in the OS area ($21+filename length)
        if len mod 2=0 then inc(len);
        if (len+$21+$20=entlen)
        and(ReadString(offset+ptr,$21+len,10)='ARCHIMEDES')then
        begin
         Directories[index].Entries[nument].Load  :=Read32bit(offset+ptr,$2B+len);
         Directories[index].Entries[nument].Exec  :=Read32bit(offset+ptr,$2F+len);
         Directories[index].Entries[nument].ROAttr:=ROAttributes(Read32bit(offset+ptr,$33+len));
        end
        else
        begin
         Directories[index].Entries[nument].Load  :=0;
         Directories[index].Entries[nument].Exec  :=0;
         Directories[index].Entries[nument].ROAttr:='';
        end;
       end;
      end;
      //Next entry
      inc(ptr,entlen);
     end;
    end;
   end;
  end;
  if Length(Directories)>0 then
   {for }index:=0{ to Length(Directories)-1 do};
   begin
    InfoBox.Lines.Add('Files at 0x'+IntToHex(offset,8)+' for directory '+GetFullPath(index));
    InfoBox.Lines.Add(StringOfChar('-',160));
    if Length(Directories[index].Entries)>0 then
     for nument:=0 to Length(Directories[index].Entries)-1 do
      InfoBox.Lines.Add(RightStr('000'+IntToStr(nument),3)+':'
                       +' 0x'+IntToHex(Directories[index].Entries[nument].Length,8)
                       +' '+Directories[index].Entries[nument].DateTime
                       +' '+Directories[index].Entries[nument].Attr
                       +' 0x'+IntToHex(Directories[index].Entries[nument].Block*voldes[vdnum].BlckSize,8)
                       +' '+LeftStr(Directories[index].Entries[nument].Name+StringOfChar(' ',30),30)
                       +' 0x'+IntToHex(Directories[index].Entries[nument].Load,8)
                       +' 0x'+IntToHex(Directories[index].Entries[nument].Exec,8)
                       +' '+Directories[index].Entries[nument].ROAttr);
    InfoBox.Lines.Add('');
    Application.ProcessMessages;
   end;
 end;
 if not iso then InfoBox.Lines.Add('Image is not an ISO');
 DropBox.Caption:='Drop ISO file here';
// Cursor:=crDefault;
end;

end.

