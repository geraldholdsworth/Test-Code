unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
   Button1: TButton;
    ImageList1: TImageList;
    ImageList2: TImageList;
    Panel1: TPanel;
    TreeView1: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  LCLIntf;

const
  ImgIndexChecked = 0;
  ImgIndexUnchecked = 1;
  ImgIndexInter = 2;

procedure CheckNode(Node: TTreeNode; Checked: Boolean);
var
  Child: TTreeNode;
  ParentStatus: Integer;
begin
  if Assigned(Node) then
  begin
    if Checked then
      Node.StateIndex := ImgIndexChecked;
    if not Checked then
      Node.StateIndex := ImgIndexUnchecked;
    Child := Node.GetFirstChild;
    while Child<>nil do
    begin
      CheckNode(Child,Checked);//Node.StateIndex = ImgIndexChecked);
      Child := Node.GetNextChild(Child);
    end;
    while Node.Parent<>nil do
    begin
      ParentStatus := Node.StateIndex;
      Child := Node.Parent.GetFirstChild;
      while Child<>nil do
      begin
        if Child.StateIndex<>ParentStatus then
          ParentStatus := ImgIndexInter;
        Child := Node.Parent.GetNextChild(Child);
      end;
      Node.Parent.StateIndex := ParentStatus;
      Node := Node.Parent;
    end;
  end;
end;

procedure ToggleTreeViewCheckBoxes(Node: TTreeNode);
begin
  if Assigned(Node) then
  begin
    if(Node.StateIndex = ImgIndexUnchecked)
    or(Node.StateIndex = ImgIndexInter)then
      CheckNode(Node,True)
    else
    if Node.StateIndex = ImgIndexChecked then
      CheckNode(Node,False);
  end;
end;

function NodeChecked(ANode:TTreeNode): Boolean;
begin
  result := (ANode.StateIndex = ImgIndexChecked);
end;

function GetFullPath(Node: TTreeNode): String;
begin
  Result:=Node.Text;
  while Node.Parent<>nil do
  begin
    Node:=Node.Parent;
    Result:=Node.Text+'->'+Result;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  pnode, node: TTreeNode;
begin
  with TreeView1.Items do begin
    node := Add(nil, 'Item1');
    node.ImageIndex := 0;
    node.SelectedIndex := 0;
    CheckNode(node, True);

    node := Add(nil, 'Item2');
    node.ImageIndex := 1;
    node.SelectedIndex := 1;
    CheckNode(node, False);

    pnode := Add(nil, 'Item3');
    pnode.ImageIndex := 2;
    pnode.SelectedIndex := 2;
    node := AddChild(pnode, 'Child1');
    node.ImageIndex := 5;
    node.SelectedIndex := 5;
    node := AddChild(pnode, 'Child2');
    node.ImageIndex := 4;
    node.SelectedIndex := 4;
    CheckNode(pnode, True);

    pnode := Add(nil, 'Item4');
    pnode.ImageIndex := 2;
    pnode.SelectedIndex := 2;
    node := AddChild(pnode, 'Child3');
    node.ImageIndex := 3;
    node.SelectedIndex := 3;
    node := AddChild(pnode, 'Child4');
    node.ImageIndex := 0;
    node.SelectedIndex := 0;
    node := AddChild(node, 'GrandChild1');
    node.ImageIndex := 2;
    node.SelectedIndex := 2;
    CheckNode(pnode, False);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  ctr,ind: Integer;
  ItemList: String;
begin
  ctr:=0;
  ItemList:='';
  for ind:=0 to TreeView1.Items.Count-1 do
    if NodeChecked(TreeView1.Items[ind]) then
    begin
      inc(ctr);
      ItemList:=ItemList+GetFullPath(TreeView1.Items[ind])+#10#13;
    end;
  ShowMessage('Number of items ticked: '+IntToStr(ctr)+#10#13+ItemList);
end;

procedure TForm1.TreeView1Click(Sender: TObject);
var
  P: TPoint;
  node: TTreeNode;
  ht: THitTests;
begin
  P.X:=0;
  GetCursorPos(P);
  P := TreeView1.ScreenToClient(P);
  ht := TreeView1.GetHitTestInfoAt(P.X, P.Y);
  if (htOnStateIcon in ht) then begin
    node := TreeView1.GetNodeAt(P.X, P.Y);
    ToggleTreeViewCheckBoxes(node);
  end;
  TreeView1.ClearSelection;
end;

end.

