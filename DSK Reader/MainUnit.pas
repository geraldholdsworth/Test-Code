unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
 DskImage, filesystem;

type

 { TMainForm }

 TMainForm = class(TForm)
   Panel1: TPanel;
   Memo1: TMemo;
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
 private

 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string
 );
var
 Image : TDSKImage=nil;
 FS    : TDSKFileSystem=nil;
 I     : Integer=0;
 Side  : Integer=0;
 Track : Integer=0;
 Sector: Integer=0;
 attr  : String='';
 Used  : Cardinal=0;
 BM1   : Byte=0;
{ data : TDiskByteArray=();
 T    : TFileStream;}
begin
 Memo1.Lines.Add(StringOfChar('*',80));
 Memo1.Lines.Add('File                : '+ExtractFileName(FileNames[0]));
 Image:=TDSKImage.CreateFromFile(FileNames[0]);
 if Image.Corrupt then Memo1.Lines.Add('Corrupt Image/Not a DSK image')
 else
 begin
  Memo1.Lines.Add('Filesize            : '+IntToStr(Image.Filesize)+' bytes');
  Memo1.Lines.Add('Creator             : '+Image.Creator);
  Memo1.Lines.Add('Sides               : '+IntToStr(Image.Disk.Sides));
  if Image.Disk.Sides>0 then
  begin
   Memo1.Lines.Add('Format              : '+Image.Disk.DetectFormat);
   Memo1.Lines.Add('Copy Protection     : '+Image.Disk.DetectCopyProtection);
   Memo1.Lines.Add('Formatted Capacity  : '+IntToStr(Image.Disk.FormattedCapacity)+' bytes');
   Memo1.Lines.Add('Track Total         : '+IntToStr(Image.Disk.TrackTotal));
   Image.Disk.Specification.Identify;
   Memo1.Lines.Add('Block Shift         : '+IntToStr(Image.Disk.Specification.BlockShift));
   Memo1.Lines.Add('Directory Blocks    : '+IntToStr(Image.Disk.Specification.DirectoryBlocks));
   Memo1.Lines.Add('FDC Sector Size     : '+IntToStr(Image.Disk.Specification.FDCSectorSize)+' bytes');
   Memo1.Lines.Add('Reserved Tracks     : '+IntToStr(Image.Disk.Specification.ReservedTracks));
   Memo1.Lines.Add('Sectors per Track   : '+IntToStr(Image.Disk.Specification.SectorsPerTrack));
   Memo1.Lines.Add('Sector Size         : '+IntToStr(Image.Disk.Specification.SectorSize)+' bytes');
   Memo1.Lines.Add('Tracks per Side     : '+IntToStr(Image.Disk.Specification.TracksPerSide));
   Memo1.Lines.Add('Block Size          : '+IntToStr(Image.Disk.Specification.GetBlockSize)+' bytes');
   Memo1.Lines.Add('Block Count         : '+IntToStr(Image.Disk.Specification.GetBlockCount));
   Memo1.Lines.Add('Usable Capacity     : '+IntToStr(Image.Disk.Specification.GetUsableCapacity)+' bytes');
   BM1:=Memo1.Lines.Count;
   Memo1.Lines.Add('Records per Track   : '+IntToStr(Image.Disk.Specification.GetRecordsPerTrack));
   FS:=TDSKFileSystem.Create(Image.Disk);
   Memo1.Lines.Add('Disc Title          : '+FS.DiskLabel);
   Memo1.Lines.Add('Number of files     : '+IntToStr(FS.Directory.Count));
   Used:=0;
   for I:=0 to FS.Directory.Count-1 do
   begin
    Memo1.Lines.Add(StringOfChar('-',30));
    Memo1.Lines.Add('Entry Index         : '+IntToStr(FS.Directory[I].EntryIndex));
    Memo1.Lines.Add('Filename            : '+FS.Directory[I].FileName);
    attr:='';
    if FS.Directory[I].ReadOnly then attr:=attr+'R';
    if FS.Directory[I].System   then attr:=attr+'S';
    if FS.Directory[I].Archived then attr:=attr+'A';
    Memo1.Lines.Add('Attributes          : '+attr);
    Memo1.Lines.Add('Side                : '+IntToStr(FS.Directory[I].FirstSector.Side));
    Memo1.Lines.Add('Track               : '+IntToStr(FS.Directory[I].FirstSector.Track));
    Memo1.Lines.Add('Sector              : '+IntToStr(FS.Directory[I].FirstSector.Sector));
    Memo1.Lines.Add('Extent              : '+IntToStr(FS.Directory[I].Extent));
    Memo1.Lines.Add('Size                : '+IntToStr(FS.Directory[I].Size)+' bytes');
    Memo1.Lines.Add('Size on disc        : '+IntToStr(FS.Directory[I].SizeOnDisk)+' bytes');
    inc(Used,FS.Directory[I].SizeOnDisk);
    Memo1.Lines.Add('Blocks              : '+IntToStr(FS.Directory[I].Blocks.Count));
    Memo1.Lines.Add('User                : '+IntToStr(FS.Directory[I].User));
    Memo1.Lines.Add('Header Type         : '+FS.Directory[I].HeaderType);
    Memo1.Lines.Add('Header Size         : '+IntToStr(FS.Directory[I].HeaderSize)+' bytes');
    Memo1.Lines.Add('Meta data           : '+FS.Directory[I].Meta);
    {data:=FS.Directory[I].GetData(False);
    T:=TFileStream.Create(FileNames[0]+' - '+FS.Directory[I].FileName, fmCreate);
    T.Write(data[0],Length(data));
    T.Free;}
   end;
   Memo1.Lines.Insert(BM1,'Used Space (files)  : '+IntToStr(Used)+' bytes');
   inc(BM1);
   Used:=0;
   Memo1.Lines.Add(StringOfChar('=',40));
   for Side:=0 to Image.Disk.Sides-1 do
   begin
    Memo1.Lines.Add('Map Side '+IntToStr(Side));
    Memo1.Lines.Add('----------');
    for Track:=0 to Image.Disk.Side[Side].Tracks-1 do
    begin
     attr:='';
     for Sector:=0 to Image.Disk.Side[Side].Track[Track].Sectors-1 do
     begin
      case Image.Disk.Side[Side].Track[Track].Sector[Sector].Status of
       ssUnformatted    : attr:=attr+'-';
       ssFormattedBlank : attr:=attr+'=';
       ssFormattedFilled: //Can also be considered 'Blank'
       begin
        attr:=attr+'*';
        inc(Used,Image.Disk.Specification.SectorSize);
       end;
       ssFormattedInUse :
       begin
        attr:=attr+'X';
        inc(Used,Image.Disk.Specification.SectorSize);
       end;
      end;
     end;
     Memo1.Lines.Add(IntToHex(Track,2)+': '+attr);
    end;
   end;
   Memo1.Lines.Insert(BM1,'Used Space (sectors): '+IntToStr(Used)+' bytes');
   FS.Free;
  end;
 end;
 Image.Free;
end;

end.

