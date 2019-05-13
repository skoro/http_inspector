unit bookmark_form;

{$mode objfpc}{$H+}

interface

uses
  Forms, ButtonPanel,
  ExtCtrls, StdCtrls, ComCtrls, bookmarks, request_object, Controls;

type

  { TBookmarkForm }

  TBookmarkForm = class(TForm)
    btnNewFolder: TButton;
    ButtonPanel: TButtonPanel;
    chkSaveResponse: TCheckBox;
    chkSyncResp: TCheckBox;
    edName: TEdit;
    lFolder: TLabel;
    lName: TLabel;
    pOptions: TPanel;
    pFolders: TPanel;
    pFolderBtn: TPanel;
    pName: TPanel;
    tvFolders: TTreeView;
    procedure btnNewFolderClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure tvFoldersEditing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure tvFoldersEditingEnd(Sender: TObject; Node: TTreeNode;
      Cancel: Boolean);
  private
    FIsNewNode: Boolean;
    FOnNewFolder: TOnNewFolderNode;
    FOnRenameFolder: TOnRenameFolderNode;
    FPrevPath: string; // Keep an original node path before editing node.
    FPrevName: string; // Keep an source node name before editing node.
    function GetBookmarkFolder: string;
    function GetBookmarkName: string;
    function GetFolderNode: TTreeNode;
  public
    property TreeView: TTreeView read tvFolders;
    property FolderNode: TTreeNode read GetFolderNode;
    function CreateBookmarkModal(RO: TRequestObject): TBookmark;
    function EditBookmarkModal(BM: TBookmark): TModalResult;
    property OnNewFolder: TOnNewFolderNode read FOnNewFolder write FOnNewFolder;
    property OnRenameFolder: TOnRenameFolderNode read FOnRenameFolder write FOnRenameFolder;
    property BookmarkName: string read GetBookmarkName;
    property BookmarkFolder: string read GetBookmarkFolder;
  end;

var
  BookmarkForm: TBookmarkForm;

implementation

uses thread_http_client, sysutils;

{$R *.lfm}

{ TBookmarkForm }

procedure TBookmarkForm.OKButtonClick(Sender: TObject);
begin
  if Trim(edName.Text) = '' then
  begin
    edName.SetFocus;
    Exit; //=>
  end;
  ModalResult := mrOK;
end;

procedure TBookmarkForm.tvFoldersEditing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
  // Don't allow to edit the root node.
  if Node.Parent = NIL then begin
    AllowEdit := False;
    Exit; // =>
  end;
  // Start editing the existing node.
  FPrevName := Node.Text;
  FPrevPath := Node.GetTextPath;
  FIsNewNode := False;
end;

procedure TBookmarkForm.tvFoldersEditingEnd(Sender: TObject; Node: TTreeNode;
  Cancel: Boolean);
begin
  // A new node is edited.
  if FIsNewNode then begin
    // Don't add a cancelled node or node without name.
    if Cancel or (Trim(Node.Text) = '') then
      Node.Delete
    else begin
      Node.Selected := True;
      if Assigned(FOnNewFolder) then
        FOnNewFolder(Self, Node.GetTextPath);
      FIsNewNode := False;
    end;
  end
  // An existing node is edited.
  else
    if FPrevPath <> '' then begin
      if Cancel or (Trim(Node.Text) = '') then
        Node.Text := FPrevName
      else begin
        if Assigned(FOnRenameFolder) then
          FOnRenameFolder(Self, FPrevPath, Node.Text);
      end;
      FPrevName := '';
      FPrevPath := '';
    end;
end;

function TBookmarkForm.GetFolderNode: TTreeNode;
begin
  Result := tvFolders.Selected;
  if Result = NIL then
    Result := tvFolders.Items.GetFirstNode;
end;

function TBookmarkForm.GetBookmarkFolder: string;
var
  fNode: TTreeNode;
begin
  fNode := tvFolders.Selected;
  if not Assigned(fNode) then
    fNode := tvFolders.Items.GetFirstNode;
  if not Assigned(fNode) then
    raise Exception.Create('Cannot get a folder node.');
  Result := fNode.GetTextPath;
end;

function TBookmarkForm.GetBookmarkName: string;
begin
  Result := edName.Text;
end;

function TBookmarkForm.CreateBookmarkModal(RO: TRequestObject): TBookmark;
begin
  ButtonPanel.CloseButton.Visible := False;
  edName.Text := GetRequestFilename(RO.Url);
  if ShowModal <> mrOK then
    Exit(NIL); //=>
  Result := TBookmark.Create(edName.Text);
  Result.Request := RO;
end;

function TBookmarkForm.EditBookmarkModal(BM: TBookmark): TModalResult;
begin
  edName.Text := BM.Name;
  Result := ShowModal;
end;

procedure TBookmarkForm.FormCreate(Sender: TObject);
begin
  ButtonPanel.OKButton.ModalResult := mrNone;
  ButtonPanel.CloseButton.ModalResult := mrNone;
  FIsNewNode := False;
end;

procedure TBookmarkForm.btnNewFolderClick(Sender: TObject);
var
  root: TTreeNode;
begin
  root := tvFolders.Selected;
  if root = NIL then
    root := tvFolders.Items.GetFirstNode;
  with tvFolders.Items.AddChild(root, '') do begin
    MakeVisible;
    EditText;
  end;
  FIsNewNode := True;
end;

end.

