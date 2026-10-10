program AmigaDisc;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,
 SysUtils
 { you can add units after this };

type
 TAmigaPartition = record
  Block     : Cardinal;
  Offset    : Cardinal;
  DriveName : String;
  DataStart : Cardinal;
  DataEnd   : Cardinal;
  DataOffset: Cardinal;
  DataLength: Cardinal;
  RootBlock : Cardinal;
 end;
 TAmigaDisc = record
  Valid     : Boolean;
  Filename  : String;
  Filesize  : Cardinal;
  BlockSize : Cardinal; //$0010
  BadBlocks : array of Cardinal; //$0018
  Partitions: array of TAmigaPartition; //$001C
  FileSysHdr: array of Cardinal; //$0020
  Cylinders : Cardinal; //$0040
  Sectors   : Cardinal; //$0044
  Heads     : Cardinal; //$0048
  Vendor    : String;   //$00A0
  Product   : String;   //$00A8
  Revision  : String;   //$00B8
end;

function AnalyseImage(thisfile: String): TAmigaDisc;
var
 S       : String;
 part    : Integer;
 partptr : Cardinal;
 badptr  : Cardinal;
 fshptr  : Cardinal;
 t       : Integer;
 F       : TFileStream;
const
 path = '/Users/geraldholdsworth/Library/Mobile Documents/com~apple~CloudDocs/'
      + 'Programming/Lazarus/Old and Test Projects/Amiga RDSK/Discs/';
 function ReadString(len: Integer): String;
 var
  I: Integer;
  B: Byte;
 begin
  Result:='';
  for i:=0 to len-1 do
  begin
   B:=F.ReadByte;
   if(B>31)and(B<127)then Result:=Result+chr(B);
  end;
 end;
 function Read32bits: Cardinal;
 begin
  Result:=F.ReadByte<<24+F.ReadByte<<16+F.ReadByte<<8+F.ReadByte;
 end;
begin
 //Reset the arrays
 SetLength(Result.Partitions,0);
 SetLength(Result.BadBlocks ,0);
 SetLength(Result.FileSysHdr,0);
 //And the reset of the fields
 Result.Valid     :=False;
 Result.Filename  :='';
 Result.Filesize  :=0;
 Result.BlockSize :=0;
 Result.Cylinders :=0;
 Result.Sectors   :=0;
 Result.Heads     :=0;
 Result.Vendor    :='';
 Result.Product   :='';
 Result.Revision  :='';
 //Make sure the file exists
 if not FileExists(path+thisfile) then exit;
 //Open to read
 F:=TFileStream.Create(path+thisfile,fmOpenRead or fmShareDenyNone);
 //Make a note of the filename and filesize
 Result.Filename:=thisfile;
 Result.Filesize:=F.Size;
 //Find the RDSK block, within the first 16 blocks
 S:='';
 part:=0;
 while(S<>'RDSK')and(part<16)do
 begin
  F.Position:=part*512;
  S         :=ReadString(4);
  inc(part);
 end;
 //Found?
 if S='RDSK' then
 begin
  Result.Valid    :=True;
  //Blocksize
  F.Position      :=$10;
  Result.BlockSize:=Read32bits;
  //Start of bad blocks pointer list
  F.Position      :=$18;
  badptr          :=Read32bits;
  //Start of partition pointer list
  partptr         :=Read32bits;
  //Start of file system header pointer list
  fshptr          :=Read32bits;
  //Number of cylinders
  F.Position      :=$40;
  Result.Cylinders:=Read32bits;
  //Number of sectors per cylinder
  Result.Sectors  :=Read32bits;
  //Number of heads
  Result.Heads    :=Read32bits;
  //Vendor
  F.Position      :=$A0;
  Result.Vendor   :=ReadString(8);
  //Product
  Result.Product  :=ReadString(16);
  //Revision
  Result.Revision :=ReadString(4);
  //Follow the Bad Block chain to find all of them
  while badptr<>$FFFFFFFF do
  begin
   F.Position:=badptr*Result.BlockSize;
   if ReadString(4)='BADB' then //Confirm it is a Bad Block
   begin
    //Make a note of this one
    part               :=Length(Result.BadBlocks);
    SetLength(Result.BadBlocks,part+1);
    //Note the block
    Result.BadBlocks[0]:=badptr;
    //Get the next one
    F.Position         :=badptr*Result.BlockSize+$10;
    badptr             :=Read32bits;
   end;
  end;
  //Follow the Partition chain to find all of them
  while partptr<>$FFFFFFFF do
  begin
   F.Position:=partptr*Result.BlockSize;
   if ReadString(4)='PART' then //Confirm it is a partition
   begin
    //Make a note of this one
    part                              :=Length(Result.Partitions);
    SetLength(Result.Partitions,part+1);
    //Note the block
    Result.Partitions[part].Block     :=partptr;
    //Calculate the offset
    Result.Partitions[part].Offset    :=partptr*Result.BlockSize;
    //Get the next one
    F.Position                        :=Result.Partitions[part].Offset+$10;
    partptr                           :=Read32bits;
    //Read the drive name (length followed by name)
    F.Position                        :=Result.Partitions[part].Offset+$24;
    t                                 :=F.ReadByte;
    Result.Partitions[part].DriveName :=ReadString(t);
    //Cylinder where the data starts
    F.Position                        :=Result.Partitions[part].Offset+$A4;
    Result.Partitions[part].DataStart :=Read32bits;
    //Cylinder where the data ends
    Result.Partitions[part].DataEnd   :=Read32bits;
    //Calculate the offset
    Result.Partitions[part].DataOffset:=Result.Partitions[part].DataStart
                                       *Result.Sectors
                                       *Result.Heads
                                       *Result.BlockSize;
    //Calculate the length
    Result.Partitions[part].DataLength:=(Result.Partitions[part].DataEnd
                                        *Result.Sectors
                                        *Result.Heads
                                        *Result.BlockSize)
                                       -Result.Partitions[part].DataOffset;
    //Calculate where the root block is
    Result.Partitions[part].RootBlock :=((Result.Partitions[part].DataEnd
                                         -Result.Partitions[part].DataStart)div 2
                                        +Result.Partitions[part].DataStart)
                                       *Result.Sectors
                                       *Result.Heads
                                       *Result.BlockSize;
   end else partptr:=$FFFFFFFF;
  end;
  //Follow the File System Header chain to find them all
  while fshptr<>$FFFFFFFF do
  begin
   F.Position:=fshptr*Result.BlockSize;
   if ReadString(4)='FSHD' then //Confirm it is a File System Header
   begin
    //Make a note of this one
    part                :=Length(Result.FileSysHdr);
    SetLength(Result.FileSysHdr,part+1);
    //Note the block
    Result.FileSysHdr[0]:=fshptr;
    //Get the next one
    F.Position          :=fshptr*Result.BlockSize+$10;
    fshptr              :=Read32bits;
   end;
  end;
 end;
 //Free up the file stream
 F.Free;
end;

procedure DisplayResults(Disc: TAmigaDisc);
var
 part: Integer;
begin
 if Disc.Filesize>0 then
 begin
  WriteLn(#$1B'[92m'+StringOfChar('*',40)+#$1B'[0m');
  WriteLn(#$1B'[1mFile              : '#$1B'[0m',Disc.Filename);
  WriteLn(#$1B'[1mFile Size         : '#$1B'[0m',Disc.Filesize,' bytes');
  WriteLn();
  if Disc.Valid then
  begin
   WriteLn(#$1B'[95mRigid Disc Block'#$1B'[0m');
   WriteLn(#$1B'[1mBlock Size        : '#$1B'[0m',Disc.BlockSize,' bytes');
   WriteLn(#$1B'[1mBad Blocks        : '#$1B'[0m',Length(Disc.BadBlocks));
   WriteLn(#$1B'[1mPartitions        : '#$1B'[0m',Length(Disc.Partitions));
   WriteLn(#$1B'[1mFile System Header: '#$1B'[0m',Length(Disc.FileSysHdr));
   WriteLn(#$1B'[1mCylinders         : '#$1B'[0m',Disc.Cylinders);
   WriteLn(#$1B'[1mSectors           : '#$1B'[0m',Disc.Sectors);
   WriteLn(#$1B'[1mHeads             : '#$1B'[0m',Disc.Heads);
   WriteLn(#$1B'[1mVendor            : '#$1B'[0m',Disc.Vendor);
   WriteLn(#$1B'[1mProduct           : '#$1B'[0m',Disc.Product);
   WriteLn(#$1B'[1mRevision          : '#$1B'[0m',Disc.Revision);
   WriteLn(#$1B'[1mDisc Size         : '#$1B'[0m',Disc.Cylinders*Disc.Sectors*Disc.Heads*Disc.BlockSize,' bytes');
   WriteLn();
   if Length(Disc.Partitions)>0 then
    WriteLn(#$1B'[95mPartitions'#$1B'[0m');
   for part:=0 to Length(Disc.Partitions)-1 do
   begin
    WriteLn(#$1B'[1mPartition ',part+1,#$1B'[0m');
    WriteLn(#$1B'[1mBlock             : '#$1B'[0m',Disc.Partitions[part].Block);
    WriteLn(#$1B'[1mOffset            : '#$1B'[0m0x',IntToHex(Disc.Partitions[part].Offset));
    WriteLn(#$1B'[1mDrive Name        : '#$1B'[0m',Disc.Partitions[part].DriveName);
    WriteLn(#$1B'[1mData              : '#$1B'[0m',Disc.Partitions[part].DataStart);
    WriteLn(#$1B'[1mEnd of Data       : '#$1B'[0m',Disc.Partitions[part].DataEnd);
    WriteLn(#$1B'[1mData Offset       : '#$1B'[0m0x',IntToHex(Disc.Partitions[part].DataOffset));
    WriteLn(#$1B'[1mData Length       : '#$1B'[0m',Disc.Partitions[part].DataLength,' bytes');
    WriteLn(#$1B'[1mRoot Block Offset : '#$1B'[0m0x',IntToHex(Disc.Partitions[part].RootBlock));
    WriteLn();
   end;
  end else WriteLn(#$1B'[95mNot a Rigid Disc'#$1B'[0m');
 end;
end;

begin
 WriteLn(#$1B'[94m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
 WriteLn(#$1B'[93mAmiga HDF Rigid Disc Analyser');
 WriteLn('written by Gerald J Holdsworth'#$1B'[0m');
 WriteLn();
 DisplayResults(AnalyseImage('RDB.hdf'));
 DisplayResults(AnalyseImage('hdisk.hdf'));
 DisplayResults(AnalyseImage('New Disk.hdf'));
 DisplayResults(AnalyseImage('RDISK (SFS).hdf'));
 DisplayResults(AnalyseImage('workbench-210.hdf'));
 DisplayResults(AnalyseImage('workbench-310.hdf'));
 DisplayResults(AnalyseImage('AshesOfEmpire_v1.0.hdf'));
 WriteLn(#$1B'[94m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
end.

