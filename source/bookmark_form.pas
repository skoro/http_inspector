unit bookmark_form;

{$mode objfpc}{$H+}

interface

uses
  Forms, ButtonPanel,
  ExtCtrls, StdCtrls, ComCtrls, bookmarks, request_object, Controls, Buttons;

const
  mrAdded = mrLast + 1; // A new bookmark was added.
  mrDeleted = mrLast + 2; // Modal result for delete operation.

type

  { TBookmarkForm }

  TBookmarkForm = class(TForm)
    btnNewFolder: TBitBtn;
    ButtonPanel: TButtonPanel;
    cbLock: TCheckBox;
    cbCopy: TCheckBox;
    edUrl: TEdit;
    edName: TEdit;
    lUrl: TLabel;
    lFolder: TLabel;
    lName: TLabel;
    pInfo: TPanel;
    pOptions: TPanel;
    pFolders: TPanel;
    pFolderBtn: TPanel;
    pName: TPanel;
    tvFolders: TTreeView;
    procedure btnNewFolderClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure tvFoldersEditing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure tvFoldersEditingEnd(Sender: TObject; Node: TTreeNode;
      Cancel: Boolean);
  private
    FIsNewNode: Boolean; // A new folder was added.
    FBookmarkManager: TBookmarkManager;
    FPrevPath: string; // Keep an original node path before editing node.
    FPrevName: string; // Keep an source node name before editing node.
    FRequestObject: TRequestObject;
    FBookmark: TBookmark; // Edited bookmark.
    function GetBookmarkManager: TBookmarkManager;
    function GetBookmarkName: string;
    function GetDeleteEnabled: Boolean;
    function GetFolderPath: string;
    function GetIsNewBookmark: Boolean;
    function GetRequestObject: TRequestObject;
    procedure SetDeleteEnabled(AValue: Boolean);
    procedure SelectAndViewNode(aNode: TTreeNode);
    procedure SyncTreeNodes(Main, Local: TTreeNode);
  public
    function ShowModal: TModalResult; override;
    function ShowModal(BM: TBookmark; RO: TRequestObject): TModalResult; overload;
    procedure PrepareEditForm; virtual;
    procedure PrepareAddForm; virtual;
    procedure AddBookmark(RO: TRequestObject); virtual;
    procedure UpdateBookmark; virtual;
    procedure DeleteBookmark; virtual;

    property Bookmark: TBookmark read FBookmark write FBookmark;
    property BookmarkManager: TBookmarkManager read GetBookmarkManager write FBookmarkManager;
    property RequestObject: TRequestObject read GetRequestObject write FRequestObject;
    property DeleteEnabled: Boolean read GetDeleteEnabled write SetDeleteEnabled;
    property FolderPath: string read GetFolderPath;
    property BookmarkName: string read GetBookmarkName;
    property IsNewBookmark: Boolean read GetIsNewBookmark;
  end;

implementation

uses thread_http_client, app_helpers, sysutils;

{$R *.lfm}

{ TBookmarkForm }

procedure TBookmarkForm.OKButtonClick(Sender: TObject);
begin
  // Don't allow to close form without a bookmark name.
  if Trim(edName.Text) = '' then
  begin
    edName.SetFocus;
    Exit; //=>
  end;

  try
    if IsNewBookmark then
      AddBookmark(FRequestObject)
    else
      UpdateBookmark;
  except
    on E: Exception do begin
      ERRMsg('Error', E.Message);
      // Don't let close the modal.
      Exit; // =>
    end;
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
var
  Added: TTreeNode;
begin
  btnNewFolder.Enabled := True;
  // A new node has been added.
  if FIsNewNode then begin
    // Don't add a cancelled node or node without name.
    if Cancel or (Trim(Node.Text) = '') then
      Node.Delete
    else begin
      Node.Selected := True;
      Added := BookmarkManager.AddFolder(Node.GetTextPath);
      if Added = NIL then begin
        ERRMsg('Error', 'Cannot add folder: ' + Node.Text);
        Node.Delete;
      end
      else
        SyncTreeNodes(Added, Node);
      FIsNewNode := False;
    end;
  end
  // An existing node has been edited.
  else
    if FPrevPath <> '' then begin
      // Revert the previous name on cancel or empty name.
      if Cancel or (Trim(Node.Text) = '') or (FPrevName = Node.Text) then
        Node.Text := FPrevName
      else
        if not BookmarkManager.RenameFolder(FPrevPath, Node.Text) then begin
          ERRMsg('Error', 'Cannot rename folder to: ' + Node.Text);
          Node.Text := FPrevName;
        end;
      FPrevName := '';
      FPrevPath := '';
    end;
end;

function TBookmarkForm.GetFolderPath: string;
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

function TBookmarkForm.GetIsNewBookmark: Boolean;
begin
  Result := (not Assigned(FBookmark)) and Assigned(FRequestObject);
end;

function TBookmarkForm.GetRequestObject: TRequestObject;
begin
  if not Assigned(FRequestObject) then
    raise Exception.Create('Request object is required.');
  Result := FRequestObject;
end;

procedure TBookmarkForm.SetDeleteEnabled(AValue: Boolean);
begin
  ButtonPanel.CloseButton.Visible := AValue;
end;

procedure TBookmarkForm.SelectAndViewNode(aNode: TTreeNode);
begin
  if Assigned(aNode) then
    with aNode do begin
      Selected := True;
      MakeVisible;
    end;
end;

procedure TBookmarkForm.SyncTreeNodes(Main, Local: TTreeNode);
var
  p: SizeInt;
  Cur, Path: string;
  NextNode, Find, StartSort: TTreeNode;
begin
  // Don't synchronize for node without the path splitter.
  if System.Pos('/', Local.Text) = 0 then
    Exit;
  Local.Delete; // It will be recreated later with a new name.
  NextNode := NIL;
  StartSort := NIL;
  Path := Main.GetTextPath;
  repeat
    p := System.Pos('/', Path);
    if p > 0 then begin
      Cur := LeftStr(Path, p - 1);
      System.Delete(Path, 1, p);
    end
    else begin
      Cur := Path;
      Path := '';
    end;
    if NextNode = NIL then
      NextNode := tvFolders.Items.GetFirstNode
    else begin
      Find := NextNode.FindNode(Cur);
      if Find = NIL then begin
        if StartSort = NIL then
          StartSort := NextNode;
        NextNode := tvFolders.Items.AddChild(NextNode, Cur)
      end
      else
        NextNode := Find;
    end;
  until Path = '';
  if Assigned(StartSort) then
    StartSort.CustomSort(@StartSort.DefaultTreeViewSort);
  NextNode.Selected := True;
end;

function TBookmarkForm.ShowModal: TModalResult;
begin
  if (not Assigned(FBookmark)) or (not Assigned(FRequestObject)) then
    raise Exception.Create('Bookmark or request object is required.');
  Result := inherited ShowModal;
end;

function TBookmarkForm.GetBookmarkManager: TBookmarkManager;
begin
  if not Assigned(FBookmarkManager) then
    raise Exception.Create('Bookmark manager is required.');
  Result := FBookmarkManager;
end;

function TBookmarkForm.GetBookmarkName: string;
begin
  Result := edName.Text;
end;

function TBookmarkForm.GetDeleteEnabled: Boolean;
begin
  Result := ButtonPanel.CloseButton.Visible;
end;

function TBookmarkForm.ShowModal(BM: TBookmark; RO: TRequestObject
  ): TModalResult;
begin
  FBookmark := BM;
  FRequestObject := RO;

  BookmarkManager.AttachFolderNodes(tvFolders);

  if IsNewBookmark then
    PrepareAddForm
  else
    PrepareEditForm;

  Result := inherited ShowModal;
  if IsNewBookmark and (Result = mrOK) then
    Result := mrAdded;
end;

procedure TBookmarkForm.PrepareEditForm;
var
  srcNode, dstNode: TTreeNode;
  path: string;
begin
  pInfo.Visible := True;
  DeleteEnabled := True;
  edName.Text := FBookmark.Name;
  edUrl.Text := FBookmark.Request.UrlPath;
  cbLock.Checked := FBookmark.Locked;
  cbCopy.Visible := True;
  // Select the bookmark node by default.
  srcNode := FBookmarkManager.FindNode(FBookmark);
  if not Assigned(srcNode) then
    { TODO : should be logged ? }
    Exit; // =>
  path := FBookmarkManager.GetNodeFolderPath(srcNode);
  dstNode := tvFolders.Items.FindNodeWithTextPath(path);
  SelectAndViewNode(dstNode);
  { TODO : path not found. Should be logged ? }
end;

procedure TBookmarkForm.PrepareAddForm;
var
  SelSrc, SelDst: TTreeNode;
begin
  pInfo.Visible := False;
  DeleteEnabled := False;
  edName.Text := GetRequestFilename(RequestObject.Url);
  cbCopy.Visible := False;

  // Set folder default selection.
  SelDst := NIL;
  // We must use TreeView instead CurrentNode because the CurrentNode
  // can be NILed.
  SelSrc := FBookmarkManager.TreeView.Selected;
  if Assigned(SelSrc) then begin
    if not IsFolderNode(SelSrc) then
      SelSrc := SelSrc.Parent; // Bookmark selected, move up.
    if Assigned(SelSrc) then
      SelDst := FindNodePath(tvFolders.Items, GetNodePath(SelSrc));
    SelectAndViewNode(SelDst);
  end;
end;

procedure TBookmarkForm.AddBookmark(RO: TRequestObject);
var
  BM: TBookmark;
  NewNode: TTreeNode;
begin
  try
    BM := TBookmark.Create(BookmarkName);
    BM.Request := RO;
    BM.Locked := cbLock.Checked;
    NewNode := BookmarkManager.AddBookmark(BM, FolderPath);
    if not Assigned(BookmarkManager.CurrentBookmark) then
      BookmarkManager.CurrentNode := NewNode;
  except
    on E: Exception do begin
      BM.Request := NIL; // Don't let free the RequestObject !
      BM.Free;
      raise; // rethrow
    end;
  end;
end;

procedure TBookmarkForm.UpdateBookmark;
var
  RO: TRequestObject;
begin
  if Length(Trim(edUrl.Text)) <> 0 then
    FBookmark.Request.Url := edUrl.Text;
  FBookmark.Locked := cbLock.Checked;
  if cbCopy.Checked then
  begin
    RO := TRequestObject.Create;
    // Copying the current bookmark.
    if BookmarkManager.CurrentBookmark = FBookmark then
      // RequestObject will be deleted in main.pas (BookmarkEditorShow)
      // so we must copying the original one when adding a new node.
      RO.CopyFrom(RequestObject)
    else
      RO.CopyFrom(FBookmark.Request);
    AddBookmark(RO);
  end
  else
    BookmarkManager.UpdateBookmark(FBookmark, BookmarkName, FolderPath);
end;

procedure TBookmarkForm.DeleteBookmark;
begin
  BookmarkManager.DeleteBookmark(FBookmark);
end;

procedure TBookmarkForm.FormCreate(Sender: TObject);
begin
  ButtonPanel.OKButton.ModalResult := mrNone;
  FIsNewNode := False;
end;

procedure TBookmarkForm.FormShow(Sender: TObject);
begin
  edName.SetFocus;
end;

procedure TBookmarkForm.btnNewFolderClick(Sender: TObject);
var
  root: TTreeNode;
begin
  btnNewFolder.Enabled := False;
  root := tvFolders.Selected;
  if root = NIL then
    root := tvFolders.Items.GetFirstNode;
  with tvFolders.Items.AddChild(root, '') do begin
    MakeVisible;
    EditText;
  end;
  FIsNewNode := True;
end;

procedure TBookmarkForm.CloseButtonClick(Sender: TObject);
begin
  ModalResult := mrNone;
  if not BookmarkManager.Popup.ConfirmDeleteBookmark(FBookmark) then
    Exit; // =>
  DeleteBookmark;
  ModalResult := mrDeleted;
end;

end.

