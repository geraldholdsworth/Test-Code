unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 ComCtrls, Math;

type

 { TMainForm }

 TMainForm = class(TForm)
  Calculate: TButton;
  BytsPerSec: TLabeledEdit;
  DiscSize: TLabeledEdit;
  DiscSizeLabel: TLabel;
  CalcConstant: TLabeledEdit;
  SecPerClus: TLabel;
  FATSize: TLabel;
  TotBlocks: TLabel;
  SecPerClusLabel: TLabel;
  ResvdSecCnt: TLabeledEdit;
  NumFATs: TLabeledEdit;
  RootEntCnt: TLabeledEdit;
  SecPerClusLabel1: TLabel;
  TotBlocksLabel: TLabel;
  UpDown1: TUpDown;
  procedure CalculateClick(Sender: TObject);
 private

 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.CalculateClick(Sender: TObject);
var
 BPB_RootEntCnt,
 BPB_ResvdSecCnt,
 BPB_SecPerClus,
 BPB_NumFATs     : Byte;
 BPB_BytsPerSec,
 FATSz,
 Constant        : Word;
 RootDirSectors,
 TmpVal1,
 TmpVal2,
 DskSize         : Cardinal;
 ImageSize       : Int64;
begin
 ImageSize:=StrToInt64('0x'+DiscSize.Text);
 BPB_RootEntCnt:=StrToInt('0x'+RootEntCnt.Text);
 BPB_ResvdSecCnt:=StrToInt('0x'+ResvdSecCnt.Text);
 BPB_BytsPerSec:=StrToInt('0x'+BytsPerSec.Text);
 BPB_NumFATs:=StrToInt('0x'+NumFATs.Text);
 Constant:=UpDown1.Position;
 BPB_SecPerClus:=$01; //34MB to 260MB
 if ImageSize>$010400000 then BPB_SecPerClus:=$08; //261MB to 8GB
 if ImageSize>$200000000 then BPB_SecPerClus:=$10; //8GB to 16GB
 if ImageSize>$400000000 then BPB_SecPerClus:=$20; //16GB to 32GB
 if ImageSize>$800000000 then BPB_SecPerClus:=$40; //32GB to 2TB
 DskSize:=ImageSize div BPB_BytsPerSec;
 TotBlocks.Caption:=IntToHex(DskSize,6);
 DiscSizeLabel.Caption:=IntToStr((ImageSize div 1024)div 1024)+'MB';
 RootDirSectors:=Ceil((BPB_RootEntCnt*32)/BPB_BytsPerSec);
 TmpVal1:=DskSize-(BPB_ResvdSecCnt+RootDirSectors);
 TmpVal2:=(Constant*BPB_SecPerClus)+BPB_NumFATs;
 TmpVal2:=TmpVal2 div 2;
 FATSz:=Ceil(TMPVal1/TmpVal2);
 SecPerClus.Caption:=IntToHex(BPB_SecPerClus,2);
 FATSize.Caption:=IntToHex(FATSz,4);
end;

end.

