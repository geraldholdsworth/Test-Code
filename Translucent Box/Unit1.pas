unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Math;

type

 TByteArray = array of Byte;

 { TGhostbusters }

 TGhostbusters = class(TForm)
  Image1: TImage;
  Image2: TImage;
  function CreateBox(LWidth, LHeight, LThickness: Integer; Opacity: Byte): TMemoryStream;
  function BMPHeader(sizex,sizey,bpp,cols: Integer; var bmp: TByteArray): Integer;
  procedure FormShow(Sender: TObject);
 private

 public

 end;

var
 Ghostbusters: TGhostbusters;

implementation

{$R *.lfm}

{ TGhostbusters }

procedure TGhostbusters.FormShow(Sender: TObject);
var
 ms: TMemoryStream;
begin
 ms:=CreateBox(256,256,2,$3F);
 Image1.Picture.Bitmap.LoadFromStream(ms);
 ms.Free;
end;

function TGhostbusters.CreateBox(LWidth, LHeight, LThickness: Integer; Opacity: Byte): TMemoryStream;
var
 bmp : TByteArray=();
 size: Integer=0;
 I   : Integer=0;
 X   : Integer=0;
 Y   : Integer=0;
begin
 Result:=nil;
 if(LThickness<LWidth div 2)and(LThickness<LHeight div 2)then
 begin
  //Set the basic length for the header
  SetLength(bmp,$36);
  //Now create the header
  size:=BMPHeader(LWidth,LHeight,32,0,bmp);
  //Increase the size to match the calculated size
  SetLength(bmp,size);
  //Pointer into the raw data
  I:=$36;
  //To keep a track of where we are (pixels co-ordinates)
  X:=0;
  Y:=LHeight-1;
  while I<size do
  begin
   //Background
   bmp[I]  :=$00;     //Blue
   bmp[I+1]:=$FF;     //Green
   bmp[I+2]:=$FF;     //Red
   bmp[I+3]:=Opacity; //Alpha
   //Outline
   if LThickness>0 then
    if(X<LThickness)or(X>LWidth-LThickness-1)
    or(Y<LThickness)or(Y>LHeight-LThickness-1)then
    begin
     bmp[I]  :=$00; //Blue
     bmp[I+1]:=$00; //Green
     bmp[I+2]:=$FF; //Red
     bmp[I+3]:=$FF; //Alpha
    end;
   //Next pointer in the raw data
   inc(I,4);
   //Next pixel
   inc(X);
   //End of row, goto next row
   if X=LWidth then
   begin
    X:=0;
    dec(Y);
   end;
  end;
  //Create the output container
  Result:=TMemoryStream.Create;
  Result.Position:=0;
  Result.Write(bmp[0],size);
  Result.Position:=0;
 end;
end;

{-------------------------------------------------------------------------------
Create a bitmap header - returns size of bitmap
-------------------------------------------------------------------------------}
function TGhostbusters.BMPHeader(sizex,sizey,bpp,cols: Integer; var bmp: TByteArray): Integer;
var
 rowwidth : Integer=0;
 pal      : Integer=0;
 pxd      : Integer=0;
 amt      : Integer=0;
begin
 //If BPP is not supported in bitmap, change to the next highest that is
 while(bpp<>1)and(bpp<>4)and(bpp<>8)and(bpp<>16)and(bpp<>24)and(bpp<>32)do
  inc(bpp);
 //Work out number of colours, under 16bpp
 if(bpp<16)and(cols=0)then cols:=1<<bpp;
 {Work out the row width, with padding to 4 bytes}
 rowwidth:=Ceil((sizex*bpp)/32)*4;
 if bpp<16 then pal:=cols*4 {Size of palette - colours * 4}
 else pal:=0; {BPP of 16,24 and 32 do not have a palette}
 pxd:=rowwidth*sizey; {Size of pixel data}
 amt:=pxd+$36+pal;{Size of file}
 {File header}
 //0x00	2 bytes	'BM' Identifies it as a BMP
 bmp[$00]:=ord('B');
 bmp[$01]:=ord('M');
 //0x02	4 bytes	Size of the file in bytes
 bmp[$02]:= amt     AND$FF;
 bmp[$03]:=(amt>> 8)AND$FF;
 bmp[$04]:=(amt>>16)AND$FF;
 bmp[$05]:=(amt>>24)AND$FF;
 //0x06 4 bytes Reserved
 bmp[$06]:=$00;
 bmp[$07]:=$00;
 bmp[$08]:=$00;
 bmp[$09]:=$00;
 //0x0A	4 bytes	Offset to pixel data
 bmp[$0A]:= ($36+pal)     AND$FF;
 bmp[$0B]:=(($36+pal)>> 8)AND$FF;
 bmp[$0C]:=(($36+pal)>>16)AND$FF;
 bmp[$0D]:=(($36+pal)>>24)AND$FF;
 {DIB Header}
 //0x0E	4 bytes	Size of DIB header (0x00000028, or 40 bytes)
 bmp[$0E]:=$28;
 bmp[$0F]:=$00;
 bmp[$10]:=$00;
 bmp[$11]:=$00;
 //0x12 4 bytes Bitmap width
 bmp[$12]:= sizex     AND$FF;
 bmp[$13]:=(sizex>> 8)AND$FF;
 bmp[$14]:=(sizex>>16)AND$FF;
 bmp[$15]:=(sizex>>24)AND$FF;
 //0x16	4 bytes	Bitmap height
 bmp[$16]:= sizey     AND$FF;
 bmp[$17]:=(sizey>> 8)AND$FF;
 bmp[$18]:=(sizey>>16)AND$FF;
 bmp[$19]:=(sizey>>24)AND$FF;
 //0x1A	2 bytes	Colour planes (should be 0x01)
 bmp[$1A]:=$01;
 bmp[$1B]:=$00;
 //0x1C	2 bytes	Colour depth/bits per pixel
 bmp[$1C]:= bpp    AND$FF;
 bmp[$1D]:=(bpp>>8)AND$FF;
 //0x1E 4 bytes Compression Method
 bmp[$1E]:=$00;
 bmp[$1F]:=$00;
 bmp[$20]:=$00;
 bmp[$21]:=$00;
 //0x22	4 bytes	Size of the raw bitmap data (i.e. [0x02]-[0x0A])
 bmp[$22]:= pxd     AND$FF;
 bmp[$23]:=(pxd>> 8)AND$FF;
 bmp[$24]:=(pxd>>16)AND$FF;
 bmp[$25]:=(pxd>>24)AND$FF;
 //0x26	4 bytes	Horizontal resolution (pixel per metre)
 bmp[$26]:=$12;
 bmp[$27]:=$0B;
 bmp[$28]:=$00;
 bmp[$29]:=$00;
 //0x2A	4 bytes	Vertical resolution (pixel per metre)
 bmp[$2A]:=$12;
 bmp[$2B]:=$0B;
 bmp[$2C]:=$00;
 bmp[$2D]:=$00;
 //0x2E	4 bytes	Number of colours in the palette (0=2^[0x1C])
 bmp[$2E]:= cols     AND$FF;
 bmp[$2F]:=(cols>> 8)AND$FF;
 bmp[$30]:=(cols>>16)AND$FF;
 bmp[$31]:=(cols>>24)AND$FF;
 //0x32 4 bytes Number of important colours
 bmp[$32]:=$00;
 bmp[$33]:=$00;
 bmp[$34]:=$00;
 bmp[$35]:=$00;
 //0x36 Palette data (if any)
 //Then follows raw pixel data
 Result:=amt;
end;

end.

