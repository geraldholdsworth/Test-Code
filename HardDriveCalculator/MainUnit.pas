unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,ComCtrls,ExtCtrls,StdCtrls,Spin,Dialogs,Math;

type

 { TMainForm }

 TMainForm = class(TForm)
  Button1: TButton;
  Edit1: TEdit;
  Edit2: TEdit;
  Edit3: TEdit;
  Label1: TLabel;
  Label2: TLabel;
  Label22: TLabel;
  Label23: TLabel;
  Label24: TLabel;
  Label25: TLabel;
  Label26: TLabel;
  Label27: TLabel;
  Label28: TLabel;
  Label29: TLabel;
  Label3: TLabel;
  Label30: TLabel;
  Label31: TLabel;
  Label32: TLabel;
  Label33: TLabel;
  Label34: TLabel;
  Label4: TLabel;
  lb_v2_id_per_zone: TLabel;
  lb_v2_min_obj_size: TLabel;
  lb_v2_root: TLabel;
  lb_v2_nzones: TLabel;
  lb_v2_discsize: TLabel;
  lb_v2_zone_spare: TLabel;
  lb_v2_secsize: TLabel;
  lb_v2_idlen: TLabel;
  lb_v2_log2bpmb: TLabel;
  lb_v2_lfau: TLabel;
  PageControl1: TPageControl;
  se_v2_heads: TSpinEdit;
  se_v2_sectors: TSpinEdit;
  se_v2_cylinders: TSpinEdit;
  ts_version2: TTabSheet;
  tb_version1: TTabSheet;
  procedure Button1Click(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure se_v2_sectorsChange(Sender: TObject);
  function GetHardDriveParams(discsize:Cardinal;bigmap:Boolean;
                   var idlen,zone_spare,nzones,log2bpmb,root: Cardinal):Boolean;
 private

 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormShow(Sender: TObject);
begin
 se_v2_sectorsChange(Sender);
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
 nzones,
 zone_spare,
 bpmb,
 bootmap : Cardinal;
const
 secsize = 512;
 dr = 60*8;
begin
 nzones:=StrToIntDef(Edit1.Text,1);
 zone_spare:=StrToIntDef(Edit2.Text,32);
 bpmb:=1<<StrToIntDef(Edit3.Text,8);
 bootmap:=((nzones div 2)*(8*secsize-zone_spare)-dr)*bpmb;
 Label1.Caption:='Bootmap: 0x'+IntToHex(bootmap,8);
end;

procedure TMainForm.se_v2_sectorsChange(Sender: TObject);
var
 sector,
 head,
 cylinder,
 disc_size,
 id_per_zone,
 min_obj_size,
 nzones,
 idlen,
 root,
 zone_spare,
 log2bpmb,
 log2secsize: Cardinal;
 ok: Boolean;
begin
 sector:=se_v2_sectors.Value;
 head  :=se_v2_heads.Value;
 cylinder:=se_v2_cylinders.Value;
 log2secsize:=9;
 disc_size:=sector*head*cylinder*(1<<log2secsize);
{ if disc_size> 1007*1024*1024 then log2bpmb:=12;
 if disc_size<=1007*1024*1024 then log2bpmb:=11;
 if disc_size<= 503*1024*1024 then log2bpmb:=10;
 if disc_size<= 249*1024*1024 then log2bpmb:= 9;
 if disc_size<= 124*1024*1024 then log2bpmb:= 8;
 if log2bpmb<log2secsize then log2bpmb:=log2secsize;}
 idlen:=0;
 zone_spare:=0;
 nzones:=0;
 log2bpmb:=0;
 root:=0;
 ok:=GetHardDriveParams(disc_size,False,idlen,zone_spare,nzones,log2bpmb,root);
 if not ok then ShowMessage('No values found');
 min_obj_size:=(idlen+1)*(1 shl log2bpmb);
 id_per_zone:=((1 shl (log2secsize+3))-zone_spare)div(idlen+1);
 //
 lb_v2_discsize.Caption:=IntToStr(disc_size)+' bytes';
 if disc_size>=1024*1024*1024 then
  lb_v2_discsize.Caption:=lb_v2_discsize.Caption+' ('+IntToStr(Ceil(disc_size/(1024*1024*1024)))+'GB)';
 if disc_size<1024*1024*1024 then
  lb_v2_discsize.Caption:=lb_v2_discsize.Caption+' ('+IntToStr(Ceil(disc_size/(1024*1024)))+'MB)';
 if disc_size<1024*1024 then
  lb_v2_discsize.Caption:=lb_v2_discsize.Caption+' ('+IntToStr(Ceil(disc_size/1024))+'KB)';
 lb_v2_secsize.Caption:=IntToStr(log2secsize);
 lb_v2_log2bpmb.Caption:=IntToStr(log2bpmb);
 lb_v2_idlen.Caption:=IntToStr(idlen);
 lb_v2_nzones.Caption:=IntToStr(nzones);
 lb_v2_min_obj_size.Caption:=IntToStr(min_obj_size);
 lb_v2_id_per_zone.Caption:=IntToStr(id_per_zone);
 lb_v2_lfau.Caption:=IntToStr(1<<log2bpmb);
 lb_v2_zone_spare.Caption:=IntToStr(zone_spare);
 lb_v2_root.Caption:=IntToHex(root,8);
end;

function TMainForm.GetHardDriveParams(discsize:Cardinal;bigmap:Boolean;
                           var idlen,zone_spare,nzones,log2bpmb,root: Cardinal):Boolean;
 //Adapted from the RISC OS RamFS ARM code procedure InitDiscRec in RamFS50
var
 r0,r1,r2,r3,r4,r6,r7,r8,r9,r10,r11,
 lr,minidlen: Integer;
label //Don't like using labels and GOTO, but it was easier to adapt from the ARM code
 FT01,FT02,FT10,FT20,FT30,FT35,FT40,FT45,FT50,FT60,FT70,FT80,FT90;
const
 maxidlen=21;			//Maximum possible
 minlog2bpmb=8;
 maxlog2bpmb=12;
 minzonespare=32;
 maxzonespare=128;              //RamFS limit is 64
 minzones=1;
 maxzones=127;			//RamFS limit is 127
 zone0bits=8*60;
 bigdirminsize=2048;
 newdirsize=$500;
 log2secsize=9;                 //Min is 8, max is 12
begin
 Result:=False;
  minidlen:=log2secsize+3;       //idlen MUST be at least log2secsize+3
  r0:=minlog2bpmb;		//Initialise log2bpmb
 FT10:
  r4:=discsize>>r0;		//Map bits for disc
  r1:=minzonespare;		//Initialise zone_spare
 FT20:
  r6:=(8<<log2secsize)-r1;	//Bits in a zone Minus sparebits
  r2:=minzones;			//Minimum of one zone
  r7:=r6-zone0bits;		//Minus bits in zone 0
 FT30:
  IF r7>r4 THEN GOTO FT35;	//Do we have enough allocation bits yet? then accept
  inc(r7,r6);			//More map bits
  inc(r2,1);			//and another zone
  IF r2<=maxzones THEN GOTO FT30;//Still OK?
  GOTO FT80;			//Here when too many zones, try a higher log2bpmb
 FT35:
				 //Now we have to choose idlen. We want idlen to be
				 //the smallest it can be for the disc.
  r3:=minidlen;			//Minimum value of idlen
 FT40:
  r8:=r6 DIV (r3+1);		//ids per zone
  r9:=1<<r3;			//work out 1<<idlen
  lr:=r8*r2;			//total ids needed
  IF lr>r9 THEN GOTO FT60;	//idlen too small?
				 //We're nearly there. Now to work out if the last zone
				 //can be handled correctly.
  lr:=r7-r4;
  IF lr=0 THEN GOTO FT50;
  IF lr<r3 THEN GOTO FT60;	//Must be at least idlen+1 bits
				 //Check also that we're not too close to the start of the zone
  lr:=r7-r6;			//Get the start of the zone
  lr:=r4-lr;			//lr = bits available in last zone
  IF lr<r3 THEN GOTO FT60;
				 //If the last zone is the map zone (ie nzones<=2), check it's
				 //big enough to hold 2 copies of he map+the root directory
  IF r2>2 THEN GOTO FT50;
  r10:=r2*(2<<log2secsize);	//r10 = 2*map size (in disc bytes)
  r11:=(1<<r0)-1;		//r11 = LFAU-1 (in disc bytes), for rounding up
  IF not bigmap THEN
  begin
   inc(r10,newdirsize);		//Short filename: add dir size to map
   GOTO FT45;
  end;
				 //Long filename case - root is separate object in map zone
  r9:=(r11+bigdirminsize)>>r0;   //r9=directory size (in map bits)
  IF r9<=r3 THEN r9:=r3+1;	//Ensure at least idlen+1
  dec(lr,r9);
  IF lr<0 THEN GOTO FT60;
 FT45:
  inc(r10,r11);
  r10:=r10>>r0;			//r10=map (+dir) size (in map bits)
  IF r10<=r3 THEN r10:=r3+1;	//Ensure at least idlen+1
  IF lr<r10 THEN GOTO FT60;
 FT50:				//We've found a result - fill in the disc record
  idlen:=r3;
  zone_spare:=r1;
  nzones:=r2;
  log2bpmb:=r0;
  Result:=True; //Mark as result found
  IF not bigmap THEN GOTO FT01;      //Do we have long filenames?
				 //The root dir's ID is the first available ID in the middle
				 //zone of the map
  r2:=r2>>1;			//zones/2
  IF r2<>0 THEN lr:=r2*r8	// * ids per zone
           ELSE lr:=3;		//If zones/2=0 then only one zone so ID is 3
  lr:=(lr<<8)OR 1;		//Construct full indirect disc address with sharing offset of 1
  GOTO FT02;
 FT01:				//not long filenames. root dir is &2nn where nn is ((zones<<1)+1)
  lr:=(r2<<1)+$201;
 FT02:
  root:=lr;
  GOTO FT90;
 FT60:                           //Increase idlen
  inc(r3);
  IF r3<=maxidlen THEN GOTO FT40;
 FT70:                           //Increase zone_spare
  inc(r1);
  IF r1<=maxzonespare THEN GOTO FT20;
 FT80:                           //Increase log2bpmb
  inc(r0);
  IF r0<=maxlog2bpmb THEN GOTO FT10;
 FT90:
  //Won't bother with the big map flags here - we can deal with this elsewhere
  {r4:=bigmapflags;
  IF discsize>512<<20 THEN r4:=r4 OR bigmapflags
                      ELSE r4:=r4 AND ($FF EOR bigmapflags);
  bigmapflags:=r4;}
end;

end.
