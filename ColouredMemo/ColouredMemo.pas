unit ColouredMemo;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls;

{$M+}

const
 cmColBlack             = #$1B+'[30m';
 cmColRed               = #$1B+'[31m';
 cmColGreen             = #$1B+'[32m';
 cmColYellow            = #$1B+'[33m';
 cmColBlue              = #$1B+'[34m';
 cmColCyan              = #$1B+'[35m';
 cmColMagenta           = #$1B+'[36m';
 cmColWhite             = #$1B+'[37m';
 cmColDefault           = #$1B+'[39m';
 cmHighBlack            = #$1B+'[40m';
 cmHighRed              = #$1B+'[41m';
 cmHighGreen            = #$1B+'[42m';
 cmHighYellow           = #$1B+'[43m';
 cmHighBlue             = #$1B+'[44m';
 cmHighCyan             = #$1B+'[45m';
 cmHighMagenta          = #$1B+'[46m';
 cmHighWhite            = #$1B+'[47m';
 cmHighDefault          = #$1B+'[49m';
 cmBold                 = #$1B+'[1m';
 cmNoBold               = #$1B+'[21m';
 cmItalic               = #$1B+'[3m';
 cmNoItalic             = #$1B+'[23m';
 cmStrike               = #$1B+'[9m';
 cmNoStrike             = #$1B+'[29m';
 cmUnder                = #$1B+'[4m';
 cmNoUnder              = #$1B+'[24m';
 cmResetAll             = #$1B+'[0m';

type

 { TColouredLabel }

 TColouredLabel = class(TGraphicControl)
  private
   type TLineRec = record
    Style : String;
    Text  : String;
   end;
   type TLine = array of TLineRec;
  private
//    FCanvas: TCanvas;
   FCaption    : String;
   FLine       : TLine;
   FLineSpace  : Cardinal;
   FIndent     : Cardinal;
   FUpdate     : Boolean;
   FWordWrap   : Boolean;
   FTransparent: Boolean;
   procedure SetCaption(const AText: String);
   procedure SetLineSpace(const AValue: Integer);
   procedure SetIndent(const AValue: Integer);
   procedure SetWordWrap(const AValue: Boolean);
   procedure SetTransparent(const AValue: Boolean);
   function GetUpdating: Boolean;
   function ParseLine: TLine;
   function GetPlainText: String;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure Paint; override;
  published
   procedure BeginUpdate;
   procedure EndUpdate;
   property Caption    : String         read FCaption     write SetCaption;
   property Indent     : Cardinal       read FIndent      write FIndent;
   property LineSpace  : Cardinal       read FLineSpace   write FLineSpace;
   property PlainText  : String         read GetPlainText;
   property WordWrap   : Boolean        read FWordWrap    write SetWordWrap;
   property Transparent: Boolean        read FTransparent write SetTransparent;
   property IsUpdating : Boolean        read GetUpdating;
 end;

 { TColouredMemo }

 TColouredMemo = class(TScrollingWinControl)
 private
  type //Extended the TStringList so we can repaint the form when a line is added
   TExtStringList=class(TStringList)
    private
     FColouredMemo : TColouredMemo;
     procedure SyncWithParent;
    published
     function Add(const S: string): Integer; override;
     function AddObject(const S: string; AObject: TObject): Integer; override;
     function Add(const Fmt : string; const Args : Array of const): Integer; overload;
     function AddObject(const Fmt: string; Args : Array of const; AObject: TObject): Integer; overload;
     function AddPair(const AName, AValue: string): TStrings; overload;
     function AddPair(const AName, AValue: string; AObject: TObject): TStrings; overload;
     procedure AddStrings(TheStrings: TStrings); override;
     procedure AddStrings(TheStrings: TStrings; ClearFirst : Boolean); overload;
     procedure AddStrings(const TheStrings: array of string); overload; override;
     procedure AddStrings(const TheStrings: array of string; ClearFirst : Boolean); overload;
     procedure SetStrings(TheStrings: TStrings); override;
     procedure SetStrings(TheStrings: array of string); override; overload;
     Procedure AddText(Const S : String); override;
     procedure AddCommaText(const S: String);
     procedure AddDelimitedText(const S: String; ADelimiter: char; AStrictDelimiter: Boolean);
     procedure AddDelimitedtext(const S: String); overload;
     procedure Append(const S: string);
     procedure Assign(Source: TPersistent); override;
   end;
 var
  FLines    : TExtStringList;
  FLineSpace: Cardinal;
  FIndent   : Cardinal;
  FContent  : array of TColouredLabel;
  FTextWrap : Boolean;
  FUpdate   : Boolean;
 protected
  procedure SetLines(const AValue: TExtStringList);
  procedure SetTextWrap(const AValue: Boolean);
  function GetPlainText: TStringArray;
 public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  procedure Clear;
  procedure SyncLines;
 published
  procedure BeginUpdate;
  procedure EndUpdate;
  property AutoScroll;
  property Indent    : Cardinal       read FIndent      write FIndent;
  property Lines     : TExtStringList read FLines       write SetLines;
  property LineSpace : Cardinal       read FLineSpace   write FLineSpace;
  property PlainText : TStringArray   read GetPlainText;
  property TextWrap  : Boolean        read FTextWrap    write SetTextWrap;
 end;

implementation

{-------------------------------------------------------------------------------
Constructor method for the coloured label
-------------------------------------------------------------------------------}
constructor TColouredLabel.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
//  FCanvas := TControlCanvas.Create;
//  TControlCanvas(FCanvas).Control := Self;
 FUpdate     :=False;
 //AutoSize    :=True;
 //Align       :=alNone;
 FLineSpace  :=0;
 FIndent     :=0;
 FWordWrap   :=False;
 FTransparent:=True;
 //Color       :=clDefault;
 FCaption    :='';
 FUpdate     :=True;
 Height      :=16;
end;

{-------------------------------------------------------------------------------
Destructor method for the coloured label
-------------------------------------------------------------------------------}
destructor TColouredLabel.Destroy;
begin
//  FreeAndNil(FCanvas);
 inherited Destroy;
end;

{-------------------------------------------------------------------------------
Cancel any painting until re-enabled
-------------------------------------------------------------------------------}
procedure TColouredLabel.BeginUpdate;
begin
 if FUpdate then FUpdate:=False;
end;

{-------------------------------------------------------------------------------
Re-enable painting of the control
-------------------------------------------------------------------------------}
procedure TColouredLabel.EndUpdate;
begin
 if not FUpdate then
 begin
  FUpdate:=True;
  Paint;
 end;
end;

{-------------------------------------------------------------------------------
Get the state of the updating
-------------------------------------------------------------------------------}
function TColouredLabel.GetUpdating: Boolean;
begin
 Result:=not FUpdate;
end;

{-------------------------------------------------------------------------------
Parse the caption for control codes
-------------------------------------------------------------------------------}
function TColouredLabel.ParseLine: TLine;
var
 Words: TStringArray;
 Tmp,
 LCode : String;
 I,J   : Integer;
const
 esc = #$1B;
 procedure AddToArray(LStyle,LText: String);
 begin
  SetLength(Result,Length(Result)+1);
  Result[Length(Result)-1].Style:=LStyle;
  Result[Length(Result)-1].Text :=LText;
 end;
begin
 SetLength(Result,0);
 //Split the original text into an array
 Words:=FCaption.Split(esc);
 //Only need to do something if there is something to do it with
 if Length(Words)>0 then
 begin
  //Look at each element
  for I:=0 to Length(Words)-1 do
  begin
   J:=0;
   Tmp:='';
   LCode:='';
   //Will only work if the element has something in it
   if Length(Words[I])>0 then
   begin
    //Is it an ANSI escape sequence?
    if((Words[I][1]='[')and(I>0))
    or((Words[I][1]='[')and(I=0)and(FCaption[1]=esc))then
    begin
     //Get the code
     J:=3;
     while(Words[I][J]<>'m')and(J<Length(Words[I]))do inc(J);
     if J<=Length(Words[I]) then dec(J,2) else J:=0;
    end;
    if J>0 then
    begin
     //Get the code
     LCode:=Copy(Words[I],2,J);
     //Get the text to print without control characters
     Tmp:=Copy(Words[I],J+3);
    end;
    if J=0 then Tmp:=Words[I];
   end;
   //If there is anything to print
   AddToArray(LCode,Tmp);
  end;
 end;
end;

{-------------------------------------------------------------------------------
Get the plain text
-------------------------------------------------------------------------------}
function TColouredLabel.GetPlainText: String;
var
 Index: Integer;
begin
 Result:='';
 if Length(FLine)>0 then
  for Index:=0 to Length(FLine)-1 do
   Result:=Result+FLine[Index].Text;
end;

{-------------------------------------------------------------------------------
Caption has been changed, so we will need to repaint
-------------------------------------------------------------------------------}
procedure TColouredLabel.SetCaption(const AText: String);
begin
 if FCaption<>AText then
 begin
  FCaption:=AText; //Update the caption
  FLine:=ParseLine;//Parse the text
  if FUpdate then Paint; //Repaint if necessary
 end;
end;

{-------------------------------------------------------------------------------
Line Space has been changed, so we will need to repaint
-------------------------------------------------------------------------------}
procedure TColouredLabel.SetLineSpace(const AValue: Integer);
begin
 if FLineSpace<>AValue then
 begin
  FLineSpace:=AValue;
  if FUpdate then Paint;
 end;
end;

{-------------------------------------------------------------------------------
Indent has been changed, so we will need to repaint
-------------------------------------------------------------------------------}
procedure TColouredLabel.SetIndent(const AValue: Integer);
begin
 if FIndent<>AValue then
 begin
  FIndent:=AValue;
  if FUpdate then Paint;
 end;
end;

{-------------------------------------------------------------------------------
WordWrap has been changed, so we will need to repaint
-------------------------------------------------------------------------------}
procedure TColouredLabel.SetWordWrap(const AValue: Boolean);
begin
 if FWordWrap<>AValue then
 begin
  FWordWrap:=AValue;
  if (AutoSize)
  and(Align<>alNone)
  and(Align<>alTop)
  and(Align<>alBottom)
  and(Align<>alClient)then FWordWrap:=False;
  if FUpdate then Paint;
 end;
end;

{-------------------------------------------------------------------------------
Transparent has been changed, so we will need to repaint
-------------------------------------------------------------------------------}
procedure TColouredLabel.SetTransparent(const AValue: Boolean);
begin
 if FTransparent<>AValue then
 begin
  FTransparent:=AValue;
  if FUpdate then Paint;
 end;
end;

{-------------------------------------------------------------------------------
Paint the control
-------------------------------------------------------------------------------}
procedure TColouredLabel.Paint;
var
 I,
 XPos,
 YPos  : Integer;
 //Procedure to print the text
 procedure PrintText(const ptText: String);
 var
  W: Integer;
 begin
  W:=Canvas.TextWidth(ptText);
  //Plot the background, if any
  if Canvas.Brush.Style<>bsClear then
   Canvas.FillRect(XPos,YPos,XPos+W,
                   YPos+Canvas.TextHeight(ptText)+FLineSpace);
  Canvas.TextOut(XPos,YPos,ptText);   //Print the text
  inc(XPos,W); //Move the 'cursor' along
  //Autosize the control
  if AutoSize then if Width<XPos then Width:=XPos;
 end;
 //Procedure to print a new line
 procedure NewLine;
 begin
  //Move the Y pointer downwards
  inc(YPos,Canvas.TextHeight('X')+FLineSpace);
  //Reset X pointer
  XPos:=FLineSpace;
 end;
 //Procedure to wrap the text
 procedure WrapText(const wtInput: String);
 var
  LCount,
  LStart,
  LLength: Integer;
  wtLines: TStringArray;
  wtText : String;
 begin
  wtLines:=wtInput.Split(#$0A);//Split the text at CR
  LCount:=0; //Count the elements as we go through them
  for wtText in wtLines do
  begin
   //Only wrap if it is longer than the available width
   if(FWordWrap)and(Canvas.TextWidth(wtText)+XPos>Width)then
   begin
    //Start at the beginning
    LStart:=1;
    //And continue until we are out of characters
    while LStart<Length(wtText) do
    begin
     //Length of remaining string (if LStart+LLength are bigger than the string
     //length, then it'll just go to the end of the string)
     LLength:=Length(wtText);
     //Reduce the length until it'll fit
     while(Canvas.TextWidth(Copy(wtText,LStart,LLength))+XPos>Width)
       and(LLength>1)do dec(LLength);
     //Then print what we can
     PrintText(Copy(wtText,LStart,LLength));
     //And move the starting position along
     inc(LStart,LLength);
     //If there are more characters left, then do a CR and LF
     if LStart<=Length(wtText) then NewLine;
    end;
    //The string is only a single character, but still won't fit, so CR LF
    if Length(wtText)=1 then NewLine;
    //The starting point is the last character, so print and move along
    if LStart=Length(wtText) then PrintText(Copy(wtText,LStart));
   end
   else PrintText(wtText);//No text wrapping
   if LCount<Length(wtLines)-1 then NewLine; //New line required?
   inc(LCount); //Next element
  end;
 end;
begin
 inherited;
 if FUpdate then //Only continue if this flag is set
 begin
  //Ensure that the AutoSize and WordWrap settings do not conflict
  if (AutoSize)
  and(Align<>alNone)
  and(Align<>alTop)
  and(Align<>alBottom)
  and(Align<>alClient)then FWordWrap:=False;
  //Set up the canvas area
  if not FTransparent then
  begin
   Canvas.Brush.Color:=Color;
   Canvas.Brush.Style:=bsSolid;
   Canvas.FillRect(0,0,Canvas.Width,Canvas.Height);
  end;
  //Reset the default brush style
  Canvas.Brush.Style:=bsClear;
  //Initialise the variables
  XPos:=FIndent; //X position of the text
  YPos:=0; //Y position of the text
  if Length(FLine)>0 then
   for I:=0 to Length(FLine)-1 do
   begin
    //Decode the codes
    if (FLine[I].Style>='40')
    and(FLine[I].Style<='47')then Canvas.Brush.Style:=bsSolid;
    case FLine[I].Style of
      '0': //Reset everything
      begin
       Canvas.Font.Style :=Font.Style;
       Canvas.Font.Color :=Font.Color;
       Canvas.Brush.Style:=bsClear;
      end;
      '1': Canvas.Font.Style :=Canvas.Font.Style+[fsBold];     //Bold
      '3': Canvas.Font.Style :=Canvas.Font.Style+[fsItalic];   //Italic
      '4': Canvas.Font.Style :=Canvas.Font.Style+[fsUnderline];//Underline
      '9': Canvas.Font.Style :=Canvas.Font.Style+[fsStrikeOut];//Strikeout
     '21': Canvas.Font.Style :=Canvas.Font.Style-[fsBold];     //No Bold
     '23': Canvas.Font.Style :=Canvas.Font.Style-[fsItalic];   //No Italic
     '24': Canvas.Font.Style :=Canvas.Font.Style-[fsUnderline];//No Underline
     '29': Canvas.Font.Style :=Canvas.Font.Style-[fsStrikeOut];//No Strikeout
     '30': Canvas.Font.Color :=clBlack;                        //Black f/g
     '31': Canvas.Font.Color :=clRed;                          //Red f/g
     '32': Canvas.Font.Color :=clGreen;                        //Green f/g
     '33': Canvas.Font.Color :=clYellow;                       //Yellow f/g
     '34': Canvas.Font.Color :=clBlue;                         //Blue f/g
     '35': Canvas.Font.Color :=clAqua;                         //Cyan f/g
     '36': Canvas.Font.Color :=clPurple;                       //Magenta f/g
     '37': Canvas.Font.Color :=clWhite;                        //White f/g
     '39': Canvas.Font.Color :=Font.Color;                     //Reset f/g
     '40': Canvas.Brush.Color:=clBlack;                        //Black b/g
     '41': Canvas.Brush.Color:=clRed;                          //Red b/g
     '42': Canvas.Brush.Color:=clGreen;                        //Green b/g
     '43': Canvas.Brush.Color:=clYellow;                       //Yellow b/g
     '44': Canvas.Brush.Color:=clBlue;                         //Blue b/g
     '45': Canvas.Brush.Color:=clAqua;                         //Cyan b/g
     '46': Canvas.Brush.Color:=clPurple;                       //Magenta b/g
     '47': Canvas.Brush.Color:=clWhite;                        //White b/g
     '49': Canvas.Brush.Style:=bsClear;                        //Reset b/g
    end;
    //If there is anything to print
    if Length(FLine[I].Text)>0 then WrapText(FLine[I].Text);
   end;
   NewLine;
  //Adjust the height of the control
  if AutoSize then
   if YPos>0 then Height:=YPos else Height:=Canvas.TextHeight('X')+FLineSpace;
 end;
end;

{-------------------------------------------------------------------------------
Sync the two arrays in the parent control and repaint the control
-------------------------------------------------------------------------------}
procedure TColouredMemo.TExtStringList.SyncWithParent;
begin
 if Assigned(FColouredMemo) then FColouredMemo.SyncLines;
end;

{-------------------------------------------------------------------------------
These bunch of functions and procedures are just inherited from the base class.
They are so that the main component gets repainted when the list is updated.
-------------------------------------------------------------------------------}
function TColouredMemo.TExtStringList.Add(const S: string): Integer;
begin
 Result:=inherited Add(S);
 SyncWithParent;
end;

function TColouredMemo.TExtStringList.AddObject(const S: string; AObject: TObject): Integer;
begin
 Result:=inherited AddObject(S,AObject);
 SyncWithParent;
end;

function TColouredMemo.TExtStringList.Add(const Fmt : string; const Args : Array of const): Integer;
begin
 Result:=inherited Add(Fmt,Args);
 SyncWithParent;
end;

function TColouredMemo.TExtStringList.AddObject(const Fmt: string; Args : Array of const; AObject: TObject): Integer;
begin
 Result:=inherited AddObject(Fmt,Args,AObject);
 SyncWithParent;
end;

function TColouredMemo.TExtStringList.AddPair(const AName, AValue: string): TStrings;
begin
 Result:=inherited AddPair(AName,AValue);
 SyncWithParent;
end;

function TColouredMemo.TExtStringList.AddPair(const AName, AValue: string; AObject: TObject): TStrings;
begin
 Result:=inherited AddPair(AName,AValue,AObject);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddStrings(TheStrings: TStrings);
begin
 inherited AddStrings(TheStrings);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddStrings(TheStrings: TStrings; ClearFirst : Boolean);
begin
 inherited AddStrings(TheStrings,ClearFirst);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddStrings(const TheStrings: array of string);
begin
 inherited AddStrings(TheStrings);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddStrings(const TheStrings: array of string; ClearFirst : Boolean);
begin
 inherited AddStrings(TheStrings,ClearFirst);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.SetStrings(TheStrings: TStrings);
begin
 inherited SetStrings(TheStrings);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.SetStrings(TheStrings: array of string);
begin
 inherited SetStrings(TheStrings);
 SyncWithParent;
end;

Procedure TColouredMemo.TExtStringList.AddText(Const S : String);
begin
 inherited AddText(S);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddCommaText(const S: String);
begin
 inherited AddCommaText(S);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddDelimitedText(const S: String; ADelimiter: char; AStrictDelimiter: Boolean);
begin
 inherited AddDelimitedText(S,ADelimiter,AStrictDelimiter);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.AddDelimitedtext(const S: String);
begin
 inherited AddDelimitedText(S);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.Append(const S: string);
begin
 inherited Append(S);
 SyncWithParent;
end;

procedure TColouredMemo.TExtStringList.Assign(Source: TPersistent);
begin
 inherited Assign(Source);
 SyncWithParent;
end;

{-------------------------------------------------------------------------------
Constructor method for the coloured memo
-------------------------------------------------------------------------------}
constructor TColouredMemo.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 //Create the line container
 FLines:=TExtStringList.Create;
 FLines.FColouredMemo:=Self;
 //Defaults
 FLineSpace:=0;      //Space between lines, in pixels
 FIndent   :=0;      //Indent in from the left, in pixels
 Color     :=$FFFFFF;//Default background colour
 TextWrap  :=False;  //Whether to wrap a line to the next
 FUpdate   :=True;
end;

{-------------------------------------------------------------------------------
Destructor method for the coloured memo
-------------------------------------------------------------------------------}
destructor TColouredMemo.Destroy;
var
 Index: Integer;
begin
 FLines.Free;
 if Length(FContent)>0 then
  for Index:=0 to Length(FContent)-1 do FContent[Index].Free;
 inherited Destroy;
end;

{-------------------------------------------------------------------------------
Cancel any painting until re-enabled
-------------------------------------------------------------------------------}
procedure TColouredMemo.BeginUpdate;
begin
 if FUpdate then FUpdate:=False;
end;

{-------------------------------------------------------------------------------
Re-enable painting of the control
-------------------------------------------------------------------------------}
procedure TColouredMemo.EndUpdate;
begin
 if not FUpdate then
 begin
  FUpdate:=True;
  SyncLines;
 end;
end;

{-------------------------------------------------------------------------------
Sync the string array with the label array
-------------------------------------------------------------------------------}
procedure TColouredMemo.SyncLines;
var
 LLen,
 LLCo,
 Index: Integer;
begin
 if FUpdate then
 begin
  LLen:=Length(FContent);
  LLCo:=FLines.Count;
  //Increase the label array to account for new lines
  if LLen<LLCo then
  begin
   //Adjust length
   SetLength(FContent,LLCo);
   for Index:=LLen to LLCo-1 do //Create the new controls
   begin
    FContent[Index]:=TColouredLabel.Create(Self);
    //Populate the labels
    FContent[Index].BeginUpdate; //Don't do any painting of the control just yet
    FContent[Index].AutoSize :=True;
    FContent[Index].Indent   :=FIndent;
    FContent[Index].LineSpace:=FLineSpace;
    FContent[Index].WordWrap :=FTextWrap;
    FContent[Index].Align    :=alTop;
    //Adjust the Y position
    if Index>0 then
     FContent[Index].Top:=FContent[Index-1].Top+FContent[Index-1].Height;
    FContent[Index].Parent:=Self;
   end;
  end;
  //Decrease the label array to account for lines removed
  if LLen>LLCo then
  begin
   //Destroy any unused controls first
   for Index:=LLCo to LLen-1 do FContent[Index].Free;
   //Adjust length
   SetLength(FContent,LLCo);
  end;
  //Ensure that the captions are all up to date
  for Index:=0 to LLCo-1 do
  begin
   //Update the caption, if necessary
   if FContent[Index].Caption<>FLines[Index] then
    FContent[Index].Caption:=FLines[Index];
   //And repaint the control, if needed
   FContent[Index].EndUpdate;
  end;
  //Repaint
  //Invalidate;
 end;
end;

{-------------------------------------------------------------------------------
Gets the plain text of the content
-------------------------------------------------------------------------------}
function TColouredMemo.GetPlainText: TStringArray;
var
 Index: Integer;
begin
 Result:=nil;
 SetLength(Result,Length(FContent));
 if Length(FContent)>0 then
  for Index:=0 to Length(FContent)-1 do
   Result[Index]:=FContent[Index].PlainText;
end;

{-------------------------------------------------------------------------------
Clears the text
-------------------------------------------------------------------------------}
procedure TColouredMemo.Clear;
begin
 FLines.Clear;
 SyncLines;
end;

{-------------------------------------------------------------------------------
Inherits from the base class - unlikely this ever gets called
-------------------------------------------------------------------------------}
procedure TColouredMemo.SetLines(const AValue: TExtStringList);
begin
 if AValue<>nil then FLines.Assign(AValue);
 Invalidate;
end;

{-------------------------------------------------------------------------------
Sets the text wrap flag, and fires off the repaint
-------------------------------------------------------------------------------}
procedure TColouredMemo.SetTextWrap(const AValue: Boolean);
begin
 if FTextWrap<>AValue then
 begin
  FTextWrap:=AValue;
  Invalidate;
 end;
end;

end.
