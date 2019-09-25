unit bookmarks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, ComCtrls, ExtCtrls, Controls, Menus,
  request_object;

type
  // Forward declarations.
  TBookmark = class;
  TBookmarkPopup = class;

  // When bookmark is changed (opened).
  TOnChangeBookmark = procedure (Previous, Selected: TBookmark) of object;
  // When the bookmark menu item was selected in the popup menu.
  TOnBookmarkClick = procedure (Sender: TObject; BM: TBookmark) of object;

  { ENodeException }

  ENodeException = class(Exception)
  private
    FNode: TTreeNode;
  public
    constructor CreateNode(ANode: TTreeNode; const msg: string);
    property Node: TTreeNode read FNode write FNode;
  end;

  { ENodePathNotFound }

  ENodePathNotFound = class(Exception)
  private
    FPath: string;
  public
    constructor CreatePath(APath: string);
    property Path: string read FPath write FPath;
  end;

  { TBookmark }

  TBookmark = class
  private
    FName: string;
    FRequest: TRequestObject;
    FTreeNode: TTreeNode;
    FLocked: Boolean;
    procedure SetName(AValue: string);
    procedure SetTreeNode(AValue: TTreeNode);
  public
    constructor Create(aName: string); virtual;
    destructor Destroy; override;
    procedure UpdateRequest(ANewRequest: TRequestObject);
    property Request: TRequestObject read FRequest write FRequest;
    property TreeNode: TTreeNode read FTreeNode write SetTreeNode;
    property Name: string read FName write SetName;
    property Locked: Boolean read FLocked write FLocked;
  end;

  { TNodeView }

  TBookmarkNodeStyle = (bnsNone, bnsText, bnsIcon);

  { TBookmarkManager }

  TBookmarkManager = class(TPanel)
  private
    FTreeView: TTreeView;
    FRootNode: TTreeNode;
    FCurrentNode: TTreeNode;
    FOnChangeBookmark: TOnChangeBookmark;
    FImgIdxFolder: Integer;
    FImgIdxSelected: Integer;
    FImgIdxRoot: Integer;
    FBookmarkNodeStyle: TBookmarkNodeStyle;

    function GetBookmarkPopup: TBookmarkPopup;
    function GetCurrentBookmark: TBookmark;
    function GetRootName: string;
    procedure SetBookmarkPopup(AValue: TBookmarkPopup);
    procedure SetCurrentNode(AValue: TTreeNode);
    procedure SetBookmarkNodeStyle(AValue: TBookmarkNodeStyle);
    procedure SetImgIdxRoot(AValue: Integer);
    procedure SetRootName(AValue: string);

  protected
    function CreateTree: TTreeView; virtual;
    procedure CreateRootNode; virtual;
    function InternalAddFolder(ParentNode: TTreeNode; FolderName: string): TTreeNode; virtual;
    // TreeView double click event handler.
    procedure InternalTreeOnDblClick(Sender: TObject); virtual;
    // Walk around the TreeView and save its content to the xml document.
    procedure InternalSaveToXml(Doc: TXMLDocument; XmlRoot: TDOMNode; aNode: TTreeNode); virtual;
    // Populate the tree view from the XML.
    procedure InternalLoadFromXml(XmlNode: TDOMNode; aNode: TTreeNode); virtual;
    // Set or reset the selected image on the node.
    procedure SetNodeSelectedImage(aNode: TTreeNode; NeedReset: Boolean = False); virtual;
    // Sort nodes by specific criteria.
    procedure SortNodes(ParentNode: TTreeNode); virtual;
    // Sort comparator.
    function SortNodeCompare(Node1, Node2: TTreeNode): integer; virtual;
    // Apply node styles (TBookmarkNodeStyle).
    procedure UpdateBookmarkNodeStyle; virtual;

  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    // Add a bookmark to the tree.
    // BM - the bookmark instance.
    // FolderPath - the bookmark folder path separated by /
    function AddBookmark(BM: TBookmark; FolderPath: string): TTreeNode;
    // Creates the folder tree items and attaches these items to a custom tree.
    procedure AttachFolderNodes(CustomTree: TCustomTreeView);
    // Adds a new folder by its path to the tree.
    function AddFolder(FolderPath: string): TTreeNode;
    // Renames a folder.
    function RenameFolder(FolderPath, NewName: string): Boolean;
    // Reset current bookmark and node.
    procedure ResetCurrent;
    // Update current bookmark: set a new name or/and move to another folder.
    // ANewName - a bookmark new name
    // FolderPath - move the bookmark to another folder (optional).
    function UpdateBookmark(BM: TBookmark; ANewName, FolderPath: string): Boolean;
    // Check that the request object is matched with the current bookmark.
    function IsCurrentRequest(RO: TRequestObject): Boolean;
    // Finds the folder node by path.
    function FindFolder(FolderPath: string): TTreeNode;
    // Deletes the bookmark from the tree.
    function DeleteBookmark(BM: TBookmark): Boolean;
    // Deletes the folder and all its children (folders, bookmarks).
    function DeleteFolder(FolderPath: string): Boolean;
    function DeleteFolderNode(FolderNode: TTreeNode): Boolean;
    // Finds a tree node by bookmark instance.
    function FindNode(BM: TBookmark): TTreeNode;
    // Select bookmark.
    procedure OpenBookmark(BM: TBookmark = NIL);
    // Select bookmark by its node path.
    function OpenBookmarkPath(Path: string): TBookmark;
    // Get the node folder path (this is like dirname for files).
    function GetNodeFolderPath(aNode: TTreeNode): string;
    // Save the bookmarks content to a string buffer.
    procedure SaveXmlToStream(S: TStream); virtual;
    // Load bookmarks from the stream.
    procedure LoadXmlFromStream(S: TStream); virtual;
    // Returns a bookmark tree path.
    function GetBookmarkPath(BM: TBookmark): string; virtual;
    // Set a node style: icon or text presentation.
    procedure SetNodeStyle(aNode: TTreeNode); virtual;

    property TreeView: TTreeView read FTreeView;
    property RootName: string read GetRootName write SetRootName;
    property CurrentNode: TTreeNode read FCurrentNode write SetCurrentNode;
    property CurrentBookmark: TBookmark read GetCurrentBookmark;
    property OnChangeBookmark: TOnChangeBookmark read FOnChangeBookmark write FOnChangeBookmark;
    property Popup: TBookmarkPopup read GetBookmarkPopup write SetBookmarkPopup;
    property ImageIndexFolder: Integer read FImgIdxFolder write FImgIdxFolder;
    property ImageIndexSelected: Integer read FImgIdxSelected write FImgIdxSelected;
    property ImageIndexRoot: Integer read FImgIdxRoot write SetImgIdxRoot;
    property BookmarkNodeStyle: TBookmarkNodeStyle read FBookmarkNodeStyle write SetBookmarkNodeStyle;
  end;

  { TBookmarkPopup }

  TBookmarkPopup = class(TPopupMenu)
  private
    FBookmarkManager: TBookmarkManager;
    FOnEditClick: TOnBookmarkClick;
    FOnDeleteClick: TOnBookmarkClick;
    function GetBookmarkManager: TBookmarkManager;
    function GetSelectedNode: TTreeNode;
  protected
    function CreateItem(const caption: string): TMenuItem; virtual;
    procedure CreateDefaultItems; virtual;
    procedure InternalOnClickOpen(Sender: TObject); virtual;
    procedure InternalOnClickEdit(Sender: TObject); virtual;
    procedure InternalOnClickDelete(Sender: TObject); virtual;
    procedure InternalOnClickNewFolder(Sender: TObject); virtual;
    procedure RenameFolder(FolderNode: TTreeNode); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    function ConfirmDeleteFolder(FolderName: string): Boolean;
    function ConfirmDeleteBookmark(BM: TBookmark): Boolean;

    property BookmarkManager: TBookmarkManager read GetBookmarkManager write FBookmarkManager;
    property SelectedNode: TTreeNode read GetSelectedNode;
    property OnEditClick: TOnBookmarkClick read FOnEditClick write FOnEditClick;
    property OnDeleteClick: TOnBookmarkClick read FOnDeleteClick write FOnDeleteClick;
  end;

  // Globals section.
  // ===================================
const
  // Application bookmarks filename.
  BOOKMARK_FILENAME = 'Bookmarks.xml';

  function IsFolderNode(Node: TTreeNode): Boolean;
  function NodeToBookmark(Node: TTreeNode): TBookmark;

  // Save the application bookmarks.
  procedure SaveAppBookmarks(BM: TBookmarkManager; Filename: string = BOOKMARK_FILENAME);
  // Load the application bookmarks.
  function LoadAppBookmarks(BM: TBookmarkManager; Filename: string = BOOKMARK_FILENAME): Boolean;
  // Get the full path name of the application bookmarks.
  function GetAppBookmarksFilename(Basename: string = BOOKMARK_FILENAME): string;

  // These functions must be used instead of Node.GetTextPath and
  // Tree.Items.FindNodeWithTextPath. This is because a forward slash can be
  // inside Node.Text which is used as a path separator between tree nodes
  // in the above functions.
  // Returns a safe node path (must be used instead of Node.GetTextPath).
  function GetNodePath(aNode: TTreeNode): string;
  // Returns a node by the path (must be used instead of Tree.Items.FindNodeWithTextPath).
  function FindNodePath(Nodes: TTreeNodes; TextPath: string): TTreeNode;

implementation

uses StdCtrls, Dialogs, app_helpers, strutils, XMLWrite, XMLRead;

const
  // What symbol to use as forward slash in the node text.
  // See GetNodePath, FindNodePath.
  NODE_TEXT_SLASH = #9;

function IsFolderNode(Node: TTreeNode): Boolean;
begin
  if not Assigned(Node) then
    raise Exception.Create('A node instance is required.');
  Result := Node.Data = NIL;
end;

function NodeToBookmark(Node: TTreeNode): TBookmark;
begin
  if IsFolderNode(Node) then
    raise ENodeException.CreateNode(Node, 'The node is a folder node but expected bookmark node.');
  Result := TBookmark(Node.Data);
end;

procedure SaveAppBookmarks(BM: TBookmarkManager; Filename: string);
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(GetAppBookmarksFilename(Filename), fmCreate);
    BM.SaveXmlToStream(FS);
  finally
    FS.Free;
  end;
end;

function LoadAppBookmarks(BM: TBookmarkManager; Filename: string): Boolean;
var
  FS: TFileStream;
  Path: string;
begin
  Path := GetAppBookmarksFilename(Filename);
  if not FileExists(Path) then
    Exit(False); // =>
  try
    FS := TFileStream.Create(Path, fmOpenRead);
    BM.LoadXmlFromStream(FS);
    Result := True;
  finally
    FS.Free;
  end;
end;

function GetAppBookmarksFilename(Basename: string): string;
begin
  Result := GetAppConfigDir(False) + Basename;
end;

function GetNodePath(aNode: TTreeNode): string;
var
  Node: TTreeNode;
  Name: string;
begin
  Result := '';
  Node := aNode;
  while Assigned(Node) do
  begin
    if Result <> '' then
      Result := '/' + Result;
    // When finding a node we must treat the node name without a request method.
    // Folder node name is untouched.
    if IsFolderNode(Node) then
      Name := Node.Text
    else
      Name := NodeToBookmark(Node).Name;
    Result := ReplaceStr(Name, '/', NODE_TEXT_SLASH) + Result;
    Node := Node.Parent;
  end;
end;

function FindNodePath(Nodes: TTreeNodes; TextPath: string): TTreeNode;
var
  p: SizeInt;
  CurText: String;
  function FindNode(Root: TTreeNode; Find: string): TTreeNode;
  var
    NodeName: string;
  begin
    Result := Root;
    while Assigned(Result) do begin
      if IsFolderNode(Result) then
        NodeName := Result.Text
      else
        NodeName := NodeToBookmark(Result).Name;
      if Find = NodeName then
        Exit; //=>
      Result := Result.GetNextSibling;
    end;
  end;
begin
  Result := NIL;
  repeat
    p := System.Pos('/', TextPath);
    if p > 0 then begin
      CurText := LeftStr(TextPath, p-1);
      System.Delete(TextPath, 1, p);
    end else begin
      CurText := TextPath;
      TextPath := '';
    end;
    CurText := ReplaceStr(CurText, NODE_TEXT_SLASH, '/');
    if Result = NIL then
      Result := FindNode(Nodes.GetFirstNode, CurText)
    else
      Result := FindNode(Result.GetFirstChild, CurText);
  until (Result = NIL) or (TextPath = '');
end;

{ TBookmarkPopup }

function TBookmarkPopup.GetBookmarkManager: TBookmarkManager;
begin
  if not Assigned(FBookmarkManager) then
    raise Exception.Create('Bookmark manager is required for popup menu.');
  Result := FBookmarkManager;
end;

function TBookmarkPopup.GetSelectedNode: TTreeNode;
begin
  Result := FBookmarkManager.TreeView.Selected;
end;

function TBookmarkPopup.CreateItem(const caption: string): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := caption;
  Items.Add(Result);
end;

procedure TBookmarkPopup.CreateDefaultItems;
begin
  with CreateItem('Open') do
    OnClick := @InternalOnClickOpen;
  with CreateItem('New folder') do
    OnClick := @InternalOnClickNewFolder;
  with CreateItem('Edit') do
    OnClick := @InternalOnClickEdit;
  with CreateItem('Delete') do
    OnClick := @InternalOnClickDelete;
end;

procedure TBookmarkPopup.InternalOnClickOpen(Sender: TObject);
var
  sNode: TTreeNode;
begin
  sNode := SelectedNode;
  if not Assigned(sNode) then
    Exit; // =>
  if IsFolderNode(sNode) then begin
    if sNode.Expanded then sNode.Collapse(True) else sNode.Expand(True);
  end
  else
    FBookmarkManager.OpenBookmark;
end;

procedure TBookmarkPopup.InternalOnClickEdit(Sender: TObject);
var
  sNode: TTreeNode;
begin
  sNode := SelectedNode;
  if not Assigned(sNode) then
    Exit; // =>
  if IsFolderNode(sNode) then begin
    RenameFolder(sNode);
  end
  else begin
    if Assigned(FOnEditClick) then
      FOnEditClick(Sender, NodeToBookmark(sNode));
  end;
end;

procedure TBookmarkPopup.InternalOnClickDelete(Sender: TObject);
var
  sNode: TTreeNode;
  BM: TBookmark;
begin
  sNode := SelectedNode;
  if not Assigned(sNode) then
    Exit; // =>
  if IsFolderNode(sNode) then begin
    // Don't allow to delete root node.
    if (sNode.Parent <> NIL) and ConfirmDeleteFolder(sNode.Text) then begin
      BookmarkManager.DeleteFolderNode(sNode);
      if Assigned(FOnDeleteClick) then
        FOnDeleteClick(Self, NIL);
    end;
  end
  else begin
    BM := NodeToBookmark(sNode);
    if ConfirmDeleteBookmark(BM) then begin
      if Assigned(FOnDeleteClick) then
        FOnDeleteClick(Self, BM);
      BookmarkManager.DeleteBookmark(BM);
    end;
  end;
end;

procedure TBookmarkPopup.InternalOnClickNewFolder(Sender: TObject);
var
  fName: string;
  sNode: TTreeNode;
begin
  fName := InputBox('New folder', 'Folder name (or folder path separated by /):', '');
  if Trim(fName) = '' then
    Exit; // =>
  sNode := SelectedNode;
  if not Assigned(sNode) then // No selected - attach to the root node.
    sNode := FBookmarkManager.TreeView.Items.GetFirstNode;
  if not IsFolderNode(sNode) then
    sNode := sNode.Parent;
  if (not Assigned(sNode)) or (not IsFolderNode(sNode)) then
    Exit; // =>
  FBookmarkManager.AddFolder(GetNodePath(sNode) + '/' + fName);
end;

procedure TBookmarkPopup.RenameFolder(FolderNode: TTreeNode);
var
  NewName: string;
begin
  NewName := InputBox('Edit folder', 'A new folder name:', FolderNode.Text);
  if (NewName = FolderNode.Text) or (Trim(NewName) = '') then
    Exit; // =>
  if not FBookmarkManager.RenameFolder(GetNodePath(FolderNode), NewName) then
    ERRMsg('Error', 'Cannot rename folder. Folder is already exist ?');
end;

function TBookmarkPopup.ConfirmDeleteFolder(FolderName: string): Boolean;
begin
  Result := ConfirmDlg('Delete folder ?', Format('Are you sure you want to delete folder "%s" and ALL its children ?', [FolderName])) = mrOK;
end;

function TBookmarkPopup.ConfirmDeleteBookmark(BM: TBookmark): Boolean;
begin
  Result := ConfirmDlg('Delete bookmark ?', Format('Are you sure you want to delete "%s" ?', [BM.Name])) = mrOK;
end;

constructor TBookmarkPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CreateDefaultItems;
  if AOwner is TBookmarkManager then
    FBookmarkManager := TBookmarkManager(AOwner);
end;

{ ENodePathNotFound }

constructor ENodePathNotFound.CreatePath(APath: string);
begin
  inherited CreateFmt('Folder path %s not found.', [APath]);
  FPath := APath;
end;

{ ENodeException }

constructor ENodeException.CreateNode(ANode: TTreeNode; const msg: string);
begin
  inherited Create(msg);
  FNode := ANode;
end;

{ TBookmark }

procedure TBookmark.SetName(AValue: string);
begin
  if FName = AValue then
    Exit; // =>
  if Trim(FName) = '' then
    raise Exception.Create('Bookmark Name is required.');
  FName := AValue;
end;

procedure TBookmark.SetTreeNode(AValue: TTreeNode);
begin
  if FTreeNode = AValue then
    Exit; // =>
  if not Assigned(avalue) then
    raise Exception.Create('Bookmark must be assigned to tree node.');
  if IsFolderNode(AValue) then
    raise ENodeException.CreateNode(AValue, 'The node is a folder node.');
  FTreeNode := AValue;
end;

constructor TBookmark.Create(aName: string);
begin
  { TODO : Check that name is not empty. }
  FName := aName;
  FRequest := nil;
  FLocked := False;
end;

destructor TBookmark.Destroy;
begin
  if FRequest <> Nil then
    FreeAndNil(FRequest);
  inherited Destroy;
end;

procedure TBookmark.UpdateRequest(ANewRequest: TRequestObject);
begin
  if not FLocked then
    FRequest := ANewRequest;
end;

{ TBookmarkManager }

function TBookmarkManager.GetRootName: string;
begin
  Result := FRootNode.Text;
end;

procedure TBookmarkManager.SetBookmarkPopup(AValue: TBookmarkPopup);
begin
  if FTreeView.PopupMenu = AValue then
    Exit; // =>
  FTreeView.PopupMenu := TPopupMenu(AValue);
end;

procedure TBookmarkManager.SetCurrentNode(AValue: TTreeNode);
begin
  if FCurrentNode = AValue then
    Exit; // =>
  if AValue = NIL then
    ResetCurrent
  else begin
    if IsFolderNode(AValue) then
      raise ENodeException.CreateNode(AValue, 'Current node cannot be a folder node.');
    // Reset the selected image on the previous node.
    if Assigned(FCurrentNode) then
      SetNodeSelectedImage(FCurrentNode, True);
    FCurrentNode := AValue;
    FCurrentNode.Selected := True;
    SetNodeSelectedImage(FCurrentNode);
    FCurrentNode.MakeVisible;
  end;
end;

procedure TBookmarkManager.SetBookmarkNodeStyle(AValue: TBookmarkNodeStyle);
begin
  if FBookmarkNodeStyle = AValue then
    Exit; //=>
  FBookmarkNodeStyle := AValue;
  UpdateBookmarkNodeStyle;
end;

procedure TBookmarkManager.SetImgIdxRoot(AValue: Integer);
begin
  if FImgIdxRoot = AValue then
    Exit; // =>
  FImgIdxRoot := AValue;
  FRootNode.StateIndex := AValue;
end;

function TBookmarkManager.GetCurrentBookmark: TBookmark;
begin
  Result := NIL;
  if Assigned(FCurrentNode) then begin
    if FCurrentNode.Data = NIL then
      raise ENodeException.CreateNode(FCurrentNode, 'Runtime error: node data is not bookmark.');
    Result := TBookmark(FCurrentNode.Data);
  end;
end;

function TBookmarkManager.GetBookmarkPopup: TBookmarkPopup;
begin
  Result := TBookmarkPopup(FTreeView.PopupMenu);
end;

procedure TBookmarkManager.SetRootName(AValue: string);
begin
  if RootName = AValue then
    Exit; // =>
  FRootNode.Text := AValue;
end;

function TBookmarkManager.CreateTree: TTreeView;
begin
  Result := TTreeView.Create(Self);
  Result.Parent := Self;
  Result.Align := alClient;
  Result.ScrollBars := ssAutoBoth;
  Result.Options := [tvoReadOnly, tvoShowRoot, tvoShowLines, tvoShowButtons,
                 tvoAutoItemHeight, tvoKeepCollapsedNodes, tvoRightClickSelect];
  Result.ToolTips := True;
  // Event handlers.
  Result.OnDblClick := @InternalTreeOnDblClick;
end;

procedure TBookmarkManager.CreateRootNode;
begin
  with FTreeView.Items do begin
    Clear;
    FRootNode := Add(NIL, 'My bookmarks');
    FRootNode.Data := NIL;
    FRootNode.StateIndex := FImgIdxRoot;
    FRootNode.MakeVisible;
  end;
end;

function TBookmarkManager.InternalAddFolder(ParentNode: TTreeNode;
  FolderName: string): TTreeNode;
begin
  Result := FTreeView.Items.AddChild(ParentNode, FolderName);
  Result.Data := NIL;
  Result.MakeVisible;
  Result.StateIndex := FImgIdxFolder;
  SortNodes(ParentNode);
end;

procedure TBookmarkManager.InternalTreeOnDblClick(Sender: TObject);
begin
  OpenBookmark;
end;

procedure TBookmarkManager.InternalSaveToXml(Doc: TXMLDocument; XmlRoot: TDOMNode; aNode: TTreeNode);
var
  Child: TTreeNode;
  BM: TBookmark;
  XmlNode: TDOMNode;
begin
  if not Assigned(aNode) then
    Exit; // =>
  Child := aNode.GetFirstChild;
  while Child <> NIL do begin
    if IsFolderNode(Child) then begin // Folder node.
      XmlNode := Doc.CreateElement('Folder');
      TDOMElement(XmlNode).SetAttribute('name', Child.Text);
      XmlRoot.AppendChild(XmlNode);
      InternalSaveToXml(Doc, XmlNode, Child);
    end
    else begin // Bookmark node.
      XmlNode := Doc.CreateElement('Bookmark');
      BM := TBookmark(Child.Data);
      with TDOMElement(XmlNode) do begin
        SetAttribute('name', BM.Name);
        SetAttribute('locked', IfThen(BM.Locked, '1', '0'));
      end;
      XmlNode.AppendChild(Doc.CreateCDATASection(BM.Request.ToJson));
      XmlRoot.AppendChild(XmlNode);
    end;
    Child := Child.GetNextSibling;
  end; // while
end;

procedure TBookmarkManager.InternalLoadFromXml(XmlNode: TDOMNode; aNode: TTreeNode);
var
  Elem: TDOMElement;
  Child: TDOMNode;
  BM: TBookmark;
  fNode: TTreeNode;
begin
  if XmlNode = NIL then // Stops if reached a leaf.
    Exit; // =>
  Child := XmlNode.FirstChild;
  while Child <> NIL do begin
    Elem := TDOMElement(Child);
    case LowerCase(Child.NodeName) of
      'folder': begin
        fNode := InternalAddFolder(aNode, Elem.GetAttribute('name'));
        InternalLoadFromXml(Child, fNode);
      end;
      'bookmark': begin
        BM := TBookmark.Create(Elem.GetAttribute('name'));
        BM.Locked := Elem.GetAttribute('locked') = '1';
        BM.Request := TRequestObject.CreateFromJson(Child.TextContent);
        AddBookmark(BM, GetNodePath(aNode));
      end;
    end;
    Child := Child.NextSibling;
  end;
end;

procedure TBookmarkManager.SetNodeSelectedImage(aNode: TTreeNode;
  NeedReset: Boolean);
var
  i: Integer;
begin
  if NeedReset then i := -1 else i := FImgIdxSelected;
  aNode.SelectedIndex := i;
  aNode.ImageIndex := i;
end;

procedure TBookmarkManager.SortNodes(ParentNode: TTreeNode);
begin
  ParentNode.CustomSort(@SortNodeCompare);
end;

function TBookmarkManager.SortNodeCompare(Node1, Node2: TTreeNode): integer;
begin
  // Folders come first.
  if (Node1.Data = NIL) and (Node2.Data <> NIL) then Exit(-1);
  if (Node1.Data <> NIL) and (Node2.Data = NIL) then Exit(1);
  // Compare folders or bookmarks by name.
  if ((Node1.Data = NIL) and (Node2.Data = NIL))
     or ((Node1.Data <> NIL) and (Node2.Data <> NIL)) then
    Exit(AnsiCompareStr(Node1.Text, Node2.Text));
end;

procedure TBookmarkManager.SetNodeStyle(aNode: TTreeNode);
var
  Prefix: string;
  Idx: SmallInt;
  BM: TBookmark;
begin
  BM := NodeToBookmark(aNode);
  case FBookmarkNodeStyle of
    bnsText: begin
      case BM.Request.Method of
        'DELETE':  Prefix := 'DEL';
        'OPTIONS': Prefix := 'OPT';
        'PATCH':   Prefix := 'PAT';
        else       Prefix := BM.Request.Method;
      end;
      aNode.Text := Format('%s %s', [Prefix, BM.Name]);
      aNode.StateIndex := -1;
    end;
    bnsIcon: begin
      case BM.Request.Method of
        'GET':     Idx := 1;
        'POST':    Idx := 2;
        'PUT':     Idx := 3;
        'OPTIONS': Idx := 4;
        'DELETE':  Idx := 5;
        'PATCH':   Idx := 6;
        'HEAD':    Idx := 7;
        else       Idx := -1;
      end;
      aNode.Text := BM.Name;
      aNode.StateIndex := Idx;
    end;
    else begin
      aNode.Text := BM.Name;
      aNode.StateIndex := -1;
    end;
  end;
end;

procedure TBookmarkManager.UpdateBookmarkNodeStyle;
  procedure InternalIterate(aNode: TTreeNode);
  var
    Child: TTreeNode;
  begin
    if not Assigned(aNode) then
      Exit; //=>
    Child := aNode.GetFirstChild;
    while Child <> NIL do begin
      if IsFolderNode(Child) then
        InternalIterate(Child)
      else
        SetNodeStyle(Child);
      Child := Child.GetNextSibling;
    end;
  end;
begin
  InternalIterate(FTreeView.Items.GetFirstNode);
end;

function TBookmarkManager.GetNodeFolderPath(aNode: TTreeNode): string;
var
  path: string;
  p: SizeInt;
begin
  path := GetNodePath(aNode);
  if IsFolderNode(aNode) then
    Exit(path);
  p := RPos('/', path);
  Result := LeftStr(path, p - 1);
end;

procedure TBookmarkManager.SaveXmlToStream(S: TStream);
var
  Doc: TXMLDocument;
  XmlRoot: TDOMNode;
begin
  try
    Doc := TXMLDocument.Create;
    XmlRoot := Doc.CreateElement('Bookmarks');
    TDOMElement(XmlRoot).SetAttribute('name', RootName);
    Doc.AppendChild(XmlRoot);
    InternalSaveToXml(Doc, XmlRoot, FRootNode);
    WriteXML(Doc, S);
  finally
    Doc.Free;
  end;
end;

procedure TBookmarkManager.LoadXmlFromStream(S: TStream);
var
  Doc: TXMLDocument;
  XmlRoot: TDOMNode;
begin
  try
    ReadXMLFile(Doc, S);
    XmlRoot := Doc.FindNode('Bookmarks');
    if not Assigned(XmlRoot) then
      raise Exception.Create('Malformed xml input.');
    CreateRootNode;
    FRootNode.Text := TDOMElement(XmlRoot).GetAttribute('name');
    while XmlRoot <> NIL do begin
      InternalLoadFromXml(XmlRoot, FRootNode);
      XmlRoot := XmlRoot.NextSibling;
    end;
  finally
    Doc.Free;
  end;
end;

function TBookmarkManager.GetBookmarkPath(BM: TBookmark): string;
var
  bNode: TTreeNode;
begin
  Result := '';
  bNode := FindNode(BM);
  if bNode = NIL then
    Exit; // =>
  Result := GetNodePath(bNode);
end;

constructor TBookmarkManager.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FImgIdxFolder := -1;
  Align := alClient;
  Caption := '';
  BevelOuter := bvNone;
  FTreeView := CreateTree;
  Popup := TBookmarkPopup.Create(Self);
  BorderSpacing.Left := 4;
  FCurrentNode := NIL;
  FBookmarkNodeStyle := bnsNone;
  CreateRootNode;
end;

destructor TBookmarkManager.Destroy;
begin
  DeleteFolderNode(FRootNode);
  FreeAndNil(FTreeView);
  inherited Destroy;
end;

function TBookmarkManager.AddBookmark(BM: TBookmark; FolderPath: string
  ): TTreeNode;
var
  FolderNode: TTreeNode;
begin
  FolderNode := FindFolder(FolderPath);
  if FolderNode = NIL then
    raise ENodePathNotFound.CreatePath(FolderPath);
  if FolderNode.FindNode(BM.Name) <> NIL then
    raise ENodeException.CreateNode(FolderNode, Format('Name "%s" already exists.', [BM.Name]));
  Result := FTreeView.Items.AddChild(FolderNode, '');
  Result.Data := BM;
  Result.Parent.Expanded := True;
  SetNodeStyle(Result);
  SortNodes(FolderNode);
end;

procedure TBookmarkManager.AttachFolderNodes(CustomTree: TCustomTreeView);
  procedure WalkNodes(CurrentNode: TTreeNode; NewParent: TTreeNode = NIL);
  var
    Child: TTreeNode;
  begin
    Child := CurrentNode.GetFirstChild;
    while Child <> NIL do begin
      if IsFolderNode(Child) then
        WalkNodes(Child, CustomTree.Items.AddChild(NewParent, Child.Text));
      Child := Child.GetNextSibling;
    end;
  end;
var
  FirstNode, NewParent: TTreeNode;
begin
  FirstNode := FTreeView.Items.GetFirstNode;
  CustomTree.Items.Clear;
  NewParent := CustomTree.Items.AddChild(FirstNode.Parent, FirstNode.Text);
  WalkNodes(FirstNode, NewParent);
end;

function TBookmarkManager.AddFolder(FolderPath: string): TTreeNode;
var
  p: SizeInt;
  CurFolder: string;
  NextNode: TTreeNode;
begin
  Result := NIL;
  repeat
    p := system.Pos('/', FolderPath);
    if p > 0 then begin
      CurFolder := LeftStr(FolderPath, p-1);
      system.Delete(FolderPath, 1, p);
    end
    else begin
      CurFolder := FolderPath;
      FolderPath := '';
    end;
    if Result = NIL then begin
      if CurFolder <> FRootNode.Text then
        raise ENodePathNotFound.CreatePath(CurFolder);
      Result := FRootNode;
    end
    else begin
      NextNode := Result.FindNode(CurFolder);
      if NextNode = NIL then
        NextNode := InternalAddFolder(Result, CurFolder);
      Result := NextNode;
    end;
  until FolderPath = '';
end;

function TBookmarkManager.RenameFolder(FolderPath, NewName: string): Boolean;
var
  Folder: TTreeNode;
  p: SizeInt;
  newPath: string;
begin
  if Length(Trim(NewName)) = 0 then // is empty name ?
    Exit(False); // =>
  if system.Pos('/', NewName) <> 0 then // no slashes in the new name.
    Exit(False); // =>
  p := RPos('/', FolderPath);
  newPath := LeftStr(FolderPath, p - 1) + '/' + NewName;
  if FindNodePath(FTreeView.Items, newPath) <> NIL then
    Exit(False);
  Folder := FindFolder(FolderPath);
  if Folder = NIL then
    Exit(False); // =>
  Folder.Text := NewName;
  Result := True;
end;

procedure TBookmarkManager.ResetCurrent;
begin
  if Assigned(FCurrentNode) then begin
    SetNodeSelectedImage(FCurrentNode, True);
  end;
  FCurrentNode := NIL;
end;

function TBookmarkManager.UpdateBookmark(BM: TBookmark; ANewName, FolderPath: string): Boolean;
var
  bNode: TTreeNode;
  isCurrent: Boolean;
begin
  bNode := FindNode(BM);
  if not Assigned(bNode) then
    Exit(False); // =>
  // Rename.
  if (ANewName <> '') and (BM.Name <> ANewName) then begin
    BM.Name := ANewName;
    SetNodeStyle(bNode);
  end;
  // Move to another folder.
  if (FolderPath <> '') and (GetNodeFolderPath(bNode) <> FolderPath) then begin
    isCurrent := (bNode = FCurrentNode);
    FTreeView.Items.Delete(bNode);
    bNode := AddBookmark(BM, FolderPath);
    if isCurrent then begin
      CurrentNode := bNode;
      SetNodeSelectedImage(bNode);
    end;
  end;
end;

function TBookmarkManager.IsCurrentRequest(RO: TRequestObject): Boolean;
var
  BM: TBookmark;
begin
  BM := GetCurrentBookmark;
  if not Assigned(BM) then
    Exit(False);
  Result := BM.Request.UrlPath = RO.UrlPath;
end;

function TBookmarkManager.FindFolder(FolderPath: string): TTreeNode;
begin
  Result := FindNodePath(FTreeView.Items, FolderPath);
  if (Result <> NIL) and IsFolderNode(Result) then
    Exit;
  Result := NIL;
end;

function TBookmarkManager.DeleteBookmark(BM: TBookmark): Boolean;
var
  bNode: TTreeNode;
begin
  bNode := FindNode(BM);
  if not Assigned(bNode) then
    Exit(False); // =>
  if bNode = FCurrentNode then begin
    ResetCurrent;
  end;
  FreeAndNil(BM);
  bNode.Delete;
  Result := True;
end;

function TBookmarkManager.DeleteFolder(FolderPath: string): Boolean;
var
  fNode: TTreeNode;
begin
  fNode := FindFolder(FolderPath);
  if fNode = NIL then
    Exit(False);
  Result := DeleteFolderNode(fNode);
end;

function TBookmarkManager.DeleteFolderNode(FolderNode: TTreeNode): Boolean;
  // Recursive node delete.
  procedure DeleteNode(aNode: TTreeNode);
  begin
    if aNode = FCurrentNode then
      ResetCurrent;
    while aNode.HasChildren do
      DeleteNode(aNode.GetLastChild);
    if Assigned(aNode.Data) then
      TBookmark(aNode.Data).Free;
    aNode.Delete;
  end;

begin
  if not IsFolderNode(FolderNode) then
    Exit(False);
  DeleteNode(FolderNode);
  Result := True;
end;

function TBookmarkManager.FindNode(BM: TBookmark): TTreeNode;
  function InternalFind(aNode: TTreeNode): TTreeNode;
  var
    Child: TTreeNode;
  begin
    Result := NIL;
    if not Assigned(aNode) then
      Exit; // =>
    Child := aNode.GetFirstChild;
    while Child <> NIL do begin
      if IsFolderNode(Child) then begin
        Result := InternalFind(Child);
        if Result <> NIL then
          Exit; // =>
      end;
      if Child.Data = Pointer(BM) then
        Exit(Child);
      Child := Child.GetNextSibling;
    end;
  end;
begin
  Result := InternalFind(FTreeView.Items.GetFirstNode);
end;

procedure TBookmarkManager.OpenBookmark(BM: TBookmark = NIL);
var
  Selected: TTreeNode;
  Prev: TBookmark;
begin
  if BM = NIL then
    Selected := FTreeView.Selected
  else
    Selected := FindNode(BM);
  // The node must be selected and is not be a folder node.
  if not (Assigned(Selected) and (not IsFolderNode(Selected))) then
    Exit; // =>
  if Selected = FCurrentNode then
    Exit; // =>
  Prev := GetCurrentBookmark;
  CurrentNode := Selected;
  if Assigned(FOnChangeBookmark) then begin
    FOnChangeBookmark(Prev, GetCurrentBookmark);
    CurrentNode := Selected; // Preserve selected node after user callback.
  end;
  FTreeView.Selected := Selected;
end;

function TBookmarkManager.OpenBookmarkPath(Path: string): TBookmark;
var
  bNode: TTreeNode;
begin
  Result := NIL;
  Path := Trim(Path);
  if Length(Path) = 0 then
    Exit; // =>
  bNode := FindNodePath(FTreeView.Items, Path);
  if (bNode = NIL) or (IsFolderNode(bNode)) then
    Exit; // =>
  Result := NodeToBookmark(bNode);
  OpenBookmark(Result);
end;

end.
