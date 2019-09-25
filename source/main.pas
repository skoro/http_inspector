unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Dialogs, StdCtrls, ComCtrls, ValEdit, ExtCtrls, Grids, Menus,
  fphttpclient, fpjson, Controls, JSONPropStorage, PairSplitter, Buttons,
  SynEdit, SynHighlighterJScript, thread_http_client, response_tabs, key_value,
  profiler_graph, bookmarks, request_object, GridNavigator, SysUtils,
  jsonparser;

type

  TGridOperation = (goNew, goEdit, goDelete, goClear);
  TResponseView = (rvList, rvText, rvTimings);

  { TMainForm }

  TMainForm = class(TForm)
    btnSubmit: TButton;
    cbBasicShowPassword: TCheckBox;
    cbMethod: TComboBox;
    cbUrl: TComboBox;
    dlgFind: TFindDialog;
    editBasicLogin: TLabeledEdit;
    editBasicPassword: TLabeledEdit;
    editBearerPrefix: TLabeledEdit;
    editBearerToken: TLabeledEdit;
    editJson: TSynEdit;
    editNotes: TMemo;
    editOther: TMemo;
    gaInsertRow: TMenuItem;
    gaEditRow: TMenuItem;
    gaManageHeaders: TMenuItem;
    gaSaveHeader: TMenuItem;
    gaSeparator: TMenuItem;
    gnavBody: TGridNavigator;
    gnavCookie: TGridNavigator;
    gnavHeaders: TGridNavigator;
    gnavParams: TGridNavigator;
    gridForm: TStringGrid;
    gridParams: TStringGrid;
    gridReqCookie: TStringGrid;
    gridRespCookie: TStringGrid;
    RequestIcons: TImageList;
    LayoutSplitter: TPairSplitter;
    lblDesc: TLabel;
    miSep3: TMenuItem;
    miSep2: TMenuItem;
    miBookmarks: TMenuItem;
    miLayoutVert: TMenuItem;
    miLayoutHor: TMenuItem;
    miTabSep: TMenuItem;
    miTabToggle: TMenuItem;
    miTabNotes: TMenuItem;
    miTabAuth: TMenuItem;
    miTabs: TMenuItem;
    miTabHeaders: TMenuItem;
    miTabQuery: TMenuItem;
    miTabBody: TMenuItem;
    miTabCookie: TMenuItem;
    miView: TMenuItem;
    btnBookmark: TSpeedButton;
    pagesAuth: TPageControl;
    pagesBody: TPageControl;
    pagesRequest: TPageControl;
    pagesResponse: TPageControl;
    pagesRespView: TPageControl;
    AppSplitter: TPairSplitter;
    BookmarkSide: TPairSplitterSide;
    WorkSide: TPairSplitterSide;
    panelRequest: TPanel;
    panelResponse: TPanel;
    requestHeaders: TStringGrid;
    responseHeaders: TStringGrid;
    responseRaw: TMemo;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    splitterSideRequest: TPairSplitterSide;
    splitterSideResponse: TPairSplitterSide;
    tabAuth: TTabSheet;
    tabAuthBasic: TTabSheet;
    tabAuthBearer: TTabSheet;
    tabBody: TTabSheet;
    tabBodyForm: TTabSheet;
    tabBodyJson: TTabSheet;
    tabBodyOther: TTabSheet;
    tabContent: TTabSheet;
    tabHeaders: TTabSheet;
    tabNotes: TTabSheet;
    tabQuery: TTabSheet;
    tabReqCookie: TTabSheet;
    tabRespCookie: TTabSheet;
    tabRespList: TTabSheet;
    tabResponse: TTabSheet;
    tabRespText: TTabSheet;
    tabRespTime: TTabSheet;
    tbtnAuthType: TToolButton;
    tbtnBodyFormat: TToolButton;
    tbtnBodyType: TToolButton;
    tbtnFormUpload: TToolButton;
    tbtnJsonLoad: TToolButton;
    tbtnManageHeaders: TToolButton;
    tbtnRespFollow: TToolButton;
    tbtnRespList: TToolButton;
    tbtnRespText: TToolButton;
    tbtnRespTime: TToolButton;
    tbtnSaveHeader: TToolButton;
    textResp: TMemo;
    toolbarAuth: TToolBar;
    toolbarIcons: TImageList;
    miJsonExpand: TMenuItem;
    miJsonCollapse: TMenuItem;
    miExport: TMenuItem;
    miImport: TMenuItem;
    miFindNext: TMenuItem;
    miSep1: TMenuItem;
    miFind: TMenuItem;
    miHelpCmd: TMenuItem;
    miJsonFilter: TMenuItem;
    StatusImageSize: TImage;
    StatusTextInfo: TLabel;
    StatusTextSize: TLabel;
    miAuthNone: TMenuItem;
    miAuthBasic: TMenuItem;
    miAuthBearer: TMenuItem;
    miJsonView: TMenuItem;
    miJsonCopyValue: TMenuItem;
    miJsonCopyKey: TMenuItem;
    miJsonCopyValueKey: TMenuItem;
    miBodyForm: TMenuItem;
    miBodyJson: TMenuItem;
    miBodyOther: TMenuItem;
    miNewWindow: TMenuItem;
    miOptions: TMenuItem;
    panelUrl: TPanel;
    popupJsonTree: TPopupMenu;
    pmBodyType: TPopupMenu;
    pmAuthType: TPopupMenu;
    miOpenRequest: TMenuItem;
    miSaveRequest: TMenuItem;
    miSaveResponse: TMenuItem;
    miNew: TMenuItem;
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    jsImages: TImageList;
    miEdit: TMenuItem;
    gaClearRows: TMenuItem;
    miManageHeaders: TMenuItem;
    gaDeleteRow: TMenuItem;
    popupGridActions: TPopupMenu;
    PSMAIN: TJSONPropStorage;
    AppMenu: TMainMenu;
    miFile: TMenuItem;
    miHelp: TMenuItem;
    miQuit: TMenuItem;
    miAbout: TMenuItem;
    MenuItem6: TMenuItem;
    StatusImageTime: TImage;
    StatusPanel: TPanel;
    StatusTextMain: TLabel;
    StatusTextTime: TLabel;
    synJS: TSynJScriptSyn;
    TimerRequest: TTimer;
    toolbarResponse: TToolBar;
    ToolButton1: TToolButton;
    procedure btnBookmarkClick(Sender: TObject);
    procedure btnSubmitClick(Sender: TObject);
    procedure cbBasicShowPasswordClick(Sender: TObject);
    procedure cbMethodChange(Sender: TObject);
    procedure cbUrlChange(Sender: TObject);
    procedure cbUrlKeyPress(Sender: TObject; var Key: char);
    procedure dlgFindFind(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure gaClearRowsClick(Sender: TObject);
    procedure gaEditRowClick(Sender: TObject);
    procedure gaInsertRowClick(Sender: TObject);
    procedure gridColRowInserted(Sender: TObject; IsColumn: Boolean; sIndex,
      tIndex: Integer);
    procedure gridEditDblClick(Sender: TObject);
    procedure gridFormSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure gridParamsCheckboxToggled(sender: TObject; aCol, aRow: Integer;
      aState: TCheckboxState);
    procedure gridParamsEditingDone(Sender: TObject);
    procedure gridRespCookieDblClick(Sender: TObject);
    procedure miBookmarksClick(Sender: TObject);
    procedure miExportClick(Sender: TObject);
    procedure miFindClick(Sender: TObject);
    procedure miFindNextClick(Sender: TObject);
    procedure miHelpCmdClick(Sender: TObject);
    procedure miImportClick(Sender: TObject);
    procedure miManageHeadersClick(Sender: TObject);
    procedure JsonTreeDblClick(Sender: TObject);
    procedure JsonTreePopupMenuClick(Sender: TObject);
    procedure miNewClick(Sender: TObject);
    procedure miNewWindowClick(Sender: TObject);
    procedure miOpenRequestClick(Sender: TObject);
    procedure miOptionsClick(Sender: TObject);
    procedure miQuitClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure gaDeleteRowClick(Sender: TObject);
    procedure miSaveRequestClick(Sender: TObject);
    procedure miSaveResponseClick(Sender: TObject);
    procedure OnGridClear(Sender: TObject; Grid: TStringGrid);
    procedure OnGridDeleteRow(Sender: TObject; Grid: TStringGrid);
    procedure OnGridEditRow(Sender: TObject; Grid: TStringGrid;
      const aRow: Integer);
    procedure OnGridNewRow(Sender: TObject; Grid: TStringGrid;
      const aRow: Integer);
    procedure pagesResponseChange(Sender: TObject);
    procedure PairSplitterResize(Sender: TObject);
    procedure pmAuthTypeClick(Sender: TObject);
    procedure pmBodyTypeClick(Sender: TObject);
    procedure popupGridActionsPopup(Sender: TObject);
    procedure PSMAINRestoreProperties(Sender: TObject);
    procedure PSMAINRestoringProperties(Sender: TObject);
    procedure PSMAINSavingProperties(Sender: TObject);
    procedure requestHeadersBeforeSelection(Sender: TObject; aCol, aRow: Integer
      );
    procedure tbtnFormUploadClick(Sender: TObject);
    procedure tbtnJsonLoadClick(Sender: TObject);
    procedure tbtnManageHeadersClick(Sender: TObject);
    procedure tbtnBodyFormatClick(Sender: TObject);
    procedure tbtnRespFollowClick(Sender: TObject);
    procedure tbtnRespViewClick(Sender: TObject);
    procedure tbtnSaveHeaderClick(Sender: TObject);
    procedure TimerRequestTimer(Sender: TObject);
    procedure ViewSwitchLayout(Sender: TObject);
    procedure ViewSwitchTabs(Sender: TObject);
    procedure ViewToggleTabs(Sender: TObject);
    procedure ViewToggleTabsMenu(Status: Boolean);
  private
    FContentType: string;
    FHttpClient: TThreadHttpClient;
    FResponseTabManager: TResponseTabManager;
    FResponseJsonTab: TResponseJsonTab;
    FFindTextPos: Integer;
    FRequestSeconds: Integer;
    FProfilerGraph: TProfilerGraph;
    FBookManager: TBookmarkManager;
    FKeepResponseTab: string;
    procedure OnHttpException(Url, Method: string; E: Exception);
    function ParseHeaderLine(line: string; delim: char = ':'; all: Boolean = False): TKeyValuePair;
    procedure UpdateHeadersPickList;
    function EncodeFormData: string;
    procedure OnRequestComplete(Info: TResponseInfo);
    procedure UpdateStatusLine(Main: string = '');
    procedure UpdateStatusLine(Info: TResponseInfo);
    procedure ShowResponseCookie(Headers: TStrings);
    function PromptNewRequest(const prompt: string; const promptTitle: string = 'New request'): Boolean;
    function GetPopupSenderAsStringGrid(Sender: TObject): TStringGrid;
    function EditGridRow(Grid: TStringGrid;
      const ValueFocused: Boolean = False): TModalResult;
    procedure SetAppCaption(const AValue: String = '');
    procedure SyncURLQueryParams;
    procedure SyncGridQueryParams;
    function IsRowEnabled(const grid: TStringGrid; aRow: Integer = -1): Boolean;
    procedure DoGridOperation(Grid: TStringGrid; const op: TGridOperation);
    procedure OnOpenResponseTab(Tab: TResponseTab; ResponseInfo: TResponseInfo);
    procedure OnSaveResponseTab(const FileName: string; Tab: TResponseTab);
    procedure OnJsonTabButtonOptionsClick(Sender: TObject);
    procedure JsonTab_OnJsonFormat(JsonData: TJSONData; Editor: TSynEdit);
    procedure FindStart(Search: Boolean = True);
    procedure ToggleRequestSide(VisibleSide: Boolean);
    procedure ToggleBookmarksSide(VisibleSide: Boolean);
    procedure FinishRequest;
    procedure ResetFindTextPos;
    procedure EnableSubmitButton;
    procedure BookmarkButtonIcon(Added: Boolean);
    procedure BookmarkEditorShow(Sender: TObject; BM: TBookmark);
    procedure OnChangeBookmark(Prev, Selected: TBookmark);
    procedure OnDeleteBookmark(Sender: TObject; BM: TBookmark);
  public
    procedure ApplyOptions;
    procedure SwitchLayout;
    procedure AddRequestHeader(AHeader, AValue: string);
    procedure AddFormData(AName, AValue: string; isFile: Boolean = False);
    procedure OpenRequestFile(jsonStr: string);
    procedure SelectBodyTab(const tab: TBodyTab);
    procedure SelectAuthTab(const tab: TAuthTab);
    procedure SelectResponseViewTab(rView: TResponseView);
    function GetSelectedBodyTab: TBodyTab;
    function GetSelectedAuthTab: TAuthTab;
    function GetSelectedResponseViewTab: TResponseView;
    procedure StartNewRequest;
    function SetJsonBody(jsonStr: string; var ErrMsg: string): Boolean;
    function SubmitRequest: Boolean;
    procedure FindText;
    function CreateRequestObject: TRequestObject;
    procedure SetRequestObject(RO: TRequestObject);
    procedure KeepCurrentResponseTab;
    property BookmarkManager: TBookmarkManager read FBookManager;
  end;

var
  MainForm: TMainForm;

implementation

uses about, headers_editor, cookie_form,
  app_helpers, strutils, help_form, cmdline, options,
  import_form, export_form, bookmark_form, state, Clipbrd;

const
  MAX_URLS = 15; // How much urls we can store in url dropdown history.
  BOOKMARK_IMG_UNSET = 4;
  BOOKMARK_IMG_SET = 5;

  // App states for splitters: bookmark and request-response.
  STATE_BOOKMARK_SIDE = 'bookmarkSide';
  STATE_SPLITTER_SIDE = 'splitterSideRequest';

{$R *.lfm}

{ TMainForm }

procedure TMainForm.btnSubmitClick(Sender: TObject);
var
  RO: TRequestObject;
begin
  // Don't submit a request when the current request is in progress by pressing
  // shortcut key.
  if not btnSubmit.Enabled then
    Exit; // =>

  // A different url will unbookmark the current bookmark.
  try
    RO := CreateRequestObject;
    if not FBookManager.IsCurrentRequest(RO) then begin
      BookmarkButtonIcon(False);
      FBookManager.ResetCurrent;
    end;
  finally
    FreeAndNil(RO);
  end;

  TimerRequest.Enabled := False;
  FRequestSeconds := 0;
  if SubmitRequest then
    TimerRequest.Enabled := True;
end;

procedure TMainForm.btnBookmarkClick(Sender: TObject);
begin
  BookmarkEditorShow(Sender, FBookManager.CurrentBookmark);
end;

function TMainForm.SubmitRequest: Boolean;
var
  url, method, formData, contentType: string;
  i: integer;
  KV: TKeyValue;
  FileNames, FormValues: TStringList;
begin
  Result := False;
  try
    url := NormalizeUrl(cbUrl.Text);
  except on E: Exception do
    begin
      cbUrl.SetFocus;
      Exit; //=>
    end;
  end;

  Screen.Cursor:=crHourGlass;
  FContentType := '';
  formData := '';
  contentType := '';

  FHttpClient := TThreadHttpClient.Create(true);
  FHttpClient.OnRequestComplete := @OnRequestComplete;
  FHttpClient.OnException := @OnHttpException;
  FHttpClient.Client.IOTimeout := OptionsForm.Timeout * TimerRequest.Interval;

  method := UpperCase(Trim(cbMethod.Text));
  if method = '' then method := 'GET';

  // Post the form data.
  if (method = 'POST') and (GetSelectedBodyTab = btForm) then begin
    if gridForm.Cols[3].IndexOf('File') = -1 then begin
      formData := EncodeFormData;
      contentType := 'application/x-www-form-urlencoded';
    end
    else begin
      // Form multi file upload.
      FileNames := TStringList.Create;
      FormValues := TStringList.Create;
      try
        for I := 1 to gridForm.RowCount - 1 do begin
          if IsRowEnabled(gridForm, I) then begin
            KV := GetRowKV(gridForm, I);
            if gridForm.Cells[3, I] = 'File' then
              FileNames.Values[KV.Key] := KV.Value
            else
              FormValues.Values[KV.Key] := KV.Value;
          end;
        end;
        try
          FHttpClient.Client.MultiFileStreamFormPost(FormValues, FileNames);
          // Content-type header is already added to the http client.
          // Remove any content-type from request grid.
          for I := 1 to requestHeaders.RowCount - 1 do
            if IsRowEnabled(requestHeaders, I) then begin
              KV := GetRowKV(requestHeaders, I);
              if LowerCase(KV.Key) = 'content-type' then begin
                requestHeaders.DeleteRow(I);
                Break;
              end;
            end;
        except on E: Exception do
          begin
            FreeAndNil(FHttpClient);
            ShowMessage(E.Message);
            FinishRequest;
            Exit; //=>
          end;
        end;
      finally
        FreeAndNil(FileNames);
        FreeAndNil(FormValues);
      end;
    end;
  end;

  // Post, put, delete, etc other data.
  if (method <> 'GET') and (GetSelectedBodyTab <> btForm) then begin
    case GetSelectedBodyTab of
      btJson : begin
        formData := editJson.Text;
        contentType := 'application/json';
      end;
      btOther: formData:=editOther.Text;
    end;
  end;

  if (method <> 'GET') and (Length(formData) > 0) then
    FHttpClient.RequestBody := TStringStream.Create(formData);

  btnSubmit.Enabled := False;
  btnBookmark.Enabled := False;

  // Assign request headers to the client.
  for i:=1 to requestHeaders.RowCount-1 do
  begin
    KV := GetRowKV(requestHeaders, i);
    if (LowerCase(KV.Key) = 'content-type') and (contentType <> '') then begin
      if LowerCase(KV.Value) <> contentType then begin
        requestHeaders.Cells[2, i] := contentType;
        KV.Value := contentType;
        if not IsRowEnabled(requestHeaders, i) then
          requestHeaders.Cells[0, i] := '1';
      end;
      contentType := ''; // No need to insert content type below.
    end;
    if (IsRowEnabled(requestHeaders, i)) and (Trim(KV.Key) <> '') then
      FHttpClient.AddHeader(KV.key, KV.value);
  end;

  if contentType <> '' then begin
    requestHeaders.InsertRowWithValues(1, ['1', 'Content-Type', contentType]);
    FHttpClient.AddHeader('Content-Type', contentType);
  end;

  // Set request cookies
  for I := 1 to gridReqCookie.RowCount - 1 do
  begin
    if not IsRowEnabled(gridReqCookie, I) then continue;
    kv := GetRowKV(gridReqCookie, I);
    if kv.key = '' then continue;
    FHttpClient.AddCookie(kv.key, kv.value);
  end;

  // Process auth tab
  case GetSelectedAuthTab of
    atBearer: begin
      if (Length(editBearerPrefix.Text) > 0)
           and (Length(editBearerToken.Text) > 0)
      then
        FHttpClient.AddHeader('Authorization', Format('%s %s', [
          editBearerPrefix.Text,
          editBearerToken.Text
        ]));
    end;
    atBasic: begin
      FHttpClient.Client.UserName := editBasicLogin.Text;
      FHttpClient.Client.Password := editBasicPassword.Text;
    end;
  end;

  SyncURLQueryParams;
  UpdateStatusLine('Waiting for the response...');

  FHttpClient.Url := url;
  FHttpClient.Method := method;
  FHttpClient.Start;

  Result := True;
end;

procedure TMainForm.FindText;
var
  fp: TFindPos;
  tab: TResponseTab;
  FindSucc: Integer;
  Ans: Integer;
  ActiveTab: TTabSheet;
  Txt: string = '';
  memo: TMemo = nil;
  i, row, col: Integer;
  chr: Char;
begin
  ActiveTab := pagesResponse.ActivePage;
  tab := FResponseTabManager.CanFind;
  // Priority of the search:
  // Dynamic tab (from the response_tabs unit) when no "Content" or "Response"
  // tab is selected.
  if (tab <> nil) and ((ActiveTab <> tabContent) and (ActiveTab <> tabResponse)) then begin
    pagesResponse.ActivePage := tab.TabSheet;
    FindSucc := tab.FindNext;
  end
  // Search in focused internal tabs: Response and subtabs, Content...
  else begin
    // Next, "Content" tab priority.
    if (ActiveTab = tabContent) and tabContent.TabVisible then
      Memo := responseRaw
    else begin
      // And finally fallback to the "Response" tab.
      // Search in Response subtabs.
      if (ActiveTab = tabResponse) then
      begin
        //ActiveTab := tabResponse;
        if pagesRespView.ActivePage = tabRespTime then
          Exit // =>
        else if pagesRespView.ActivePage = tabRespList then
            Txt := GridToString(responseHeaders, #9, 1, 0)
        else if pagesRespView.ActivePage = tabRespText then
            memo := textResp;
      end;
    end;
    if (memo = nil) and (txt = '') then
      Exit; //=>
    if Assigned(memo) and (txt = '') then
      txt := memo.Text;
    //pagesResponse.ActivePage := ActiveTab;
    fp := FindInText(Txt, dlgFind.FindText, dlgFind.Options, FFindTextPos);
    if (fp.Pos = -1) and (FFindTextPos = 0) then
      FindSucc := -1 // Not found at all.
    else
      FindSucc := fp.Pos + 1;
    if fp.Pos > 0 then
    begin
      if Assigned(memo) then
      begin
        Memo.SelStart  := fp.SelStart;
        Memo.SelLength := fp.SelLength;
        if Memo.Parent.Focused then
          Memo.SetFocus;
      end;
      if frDown in dlgFind.Options then
        FFindTextPos := fp.Pos + fp.SelLength
      else
        FFindTextPos := fp.Pos - fp.SelLength;
    end;
  end;

  case FindSucc of
    // Not found at all.
    -1: begin
      miFindNext.Enabled := False;
      ERRMsg('Not found', 'Search string "' + dlgFind.FindText + '" not found.');
    end;
    // Not found but previous search was successful.
    0: begin
      Ans := ConfirmDlg('Not found', 'Search string "' + dlgFind.FindText + '" not found.'#13'Continue search from the beginning ?');
      if Ans = mrOK then
        FindStart
      else
        miFindNext.Enabled := False;
    end;
    // The search string is found.
    else
      if (ActiveTab = tabResponse) and (pagesRespView.ActivePage = tabRespList) then begin
        // Convert the search position to grid row, col.
        Row := 1;
        Col := 0;
        for i := 1 to Length(txt) do begin
          chr := txt[i];
          if (i = fp.Pos) then
            break
          else if (chr = #10) then begin // Line ending - next row.
            Inc(Row);
            Col := 0;
          end
          else if (chr = #9) then // Tab - next column.
            Inc(Col);
        end;
        responseHeaders.Row := Row;
        responseHeaders.Col := Col;
      end;
  end;
end;

function TMainForm.CreateRequestObject: TRequestObject;
begin
  Result := TRequestObject.Create;
  with Result do begin
    Method := cbMethod.Text;
    Url    := NormalizeUrl(cbUrl.Text);
    Body   := editOther.Text;
    Json   := editJson.Text;
    SetCollectionFromGrid(requestHeaders, Headers);
    SetCollectionFromGrid(gridReqCookie, Cookies);
    SetCollectionFromGrid(gridParams, Params);
    GetFormFromGrid(gridForm);
    AuthType := GetSelectedAuthTab;
    AuthBasic.Login    := editBasicLogin.Text;
    AuthBasic.Password := editBasicPassword.Text;
    AuthBearer.Prefix  := editBearerPrefix.Text;
    AuthBearer.Token   := editBearerToken.Text;
    DataType := GetSelectedBodyTab;
    Notes := editNotes.Text;
  end;
end;

procedure TMainForm.SetRequestObject(RO: TRequestObject);
var
  bt: TBodyTab;
begin
  with RO do begin
    cbUrl.Text     := Url;
    cbMethod.Text  := Method;
    editOther.Text := Body;
    editJson.Text  := Json;
    editNotes.Text := Notes;

    SetCollectionToGrid(Headers, requestHeaders);
    SetCollectionToGrid(Cookies, gridReqCookie);
    SetCollectionToGrid(Params, gridParams);
    SetFormToGrid(gridForm);

    SelectAuthTab(AuthType);
    editBasicLogin.Text    := AuthBasic.Login;
    editBasicPassword.Text := AuthBasic.Password;
    editBearerPrefix.Text  := AuthBearer.Prefix;
    editBearerToken.Text   := AuthBearer.Token;

    // Set body tab depending on data.
    if IsJson then
       bt := btJson
    else
      if not Body.Trim.IsEmpty then
        bt := btOther
    else
      bt := btForm;
    SelectBodyTab(bt);

    // Set response content.
    if Assigned(ResponseInfo) then
      OnRequestComplete(ResponseInfo);

    SyncGridQueryParams;
  end;
end;

procedure TMainForm.KeepCurrentResponseTab;
begin
  if Assigned(pagesResponse.ActivePage) then
    FKeepResponseTab := pagesResponse.ActivePage.Caption;
end;

procedure TMainForm.SelectResponseViewTab(rView: TResponseView);
begin
  case rView of
    rvList: begin
      tbtnRespList.Down := True;
      tbtnRespText.Down := False;
      tbtnRespTime.Down := False;
      pagesRespView.ActivePage := tabRespList;
      ResetFindTextPos;
      if Showing then // Don't focus the component when form is creating.
        responseHeaders.SetFocus;
    end;
    rvText: begin
      tbtnRespList.Down := False;
      tbtnRespText.Down := True;
      tbtnRespTime.Down := False;
      pagesRespView.ActivePage := tabRespText;
      ResetFindTextPos;
      if Showing then
        textResp.SetFocus;
    end;
    rvTimings: begin
      tbtnRespList.Down := False;
      tbtnRespText.Down := False;
      tbtnRespTime.Down := True;
      pagesRespView.ActivePage := tabRespTime;
    end;
  end;
end;

procedure TMainForm.cbBasicShowPasswordClick(Sender: TObject);
begin
  if cbBasicShowPassword.Checked then
    editBasicPassword.EchoMode := emNormal
  else
    editBasicPassword.EchoMode := emPassword;
end;

procedure TMainForm.cbMethodChange(Sender: TObject);
var
  BM: TBookmark;
begin
  // Update the current bookmark node (icon or text).
  with FBookManager do begin
    BM := CurrentBookmark;
    if Assigned(BM) and (not BM.Locked) then begin
      BM.Request.Method := cbMethod.Text;
      SetNodeStyle(CurrentNode);
    end;
  end;
end;

procedure TMainForm.cbUrlChange(Sender: TObject);
begin
  SyncURLQueryParams;
  EnableSubmitButton;
end;

procedure TMainForm.cbUrlKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then btnSubmitClick(Sender);
end;

procedure TMainForm.dlgFindFind(Sender: TObject);
begin
  dlgFind.CloseDialog;
  FindStart;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  C: string;
begin
  inherited;

  // Earlier options initialization. We need options during
  // main form creation.
  OptionsForm := TOptionsForm.Create(Self);

  // Defaults. Before configuration is read.
  SelectResponseViewTab(rvList);

  // Init app configuration.
  C := GetAppConfigFile(False, True);
  PSMAIN.JSONFileName := C;
  C := ExtractFilePath(C);
  if not ForceDirectories(C) then
    ShowMessage(Format('Cannot create directory "%s"', [C]));
  PSMAIN.Active := True;

  // Form components defaults.
  StatusTextTime.Caption := '';
  StatusTextSize.Caption := '';
  StatusTextInfo.Caption := '';
  miSaveResponse.Enabled := False;

  HeadersEditorForm := THeadersEditorForm.Create(Application);

  // Initialize and register response tabs.
  FResponseTabManager := TResponseTabManager.Create(pagesResponse);
  FResponseTabManager.RegisterTab(TResponseImageTab.Create);
  FResponseJsonTab := TResponseJsonTab.Create;
  FResponseJsonTab.OnJsonFormat := @JsonTab_OnJsonFormat;
  FResponseTabManager.RegisterTab(FResponseJsonTab);
  FResponseTabManager.OnOpenResponseTab := @OnOpenResponseTab;
  FResponseTabManager.OnSaveTab := @OnSaveResponseTab;
  FResponseTabManager.RegisterTab(TResponseXMLTab.Create);

  UpdateHeadersPickList;

  gridForm.Cells[0, 1] := '1';
  gridReqCookie.Cells[0, 1] := '1';
  gridParams.Cells[0, 1] := '1';

  KeyValueForm := TKeyValueForm.Create(Application);

  // Bookmark manager initialization.
  FBookManager := TBookmarkManager.Create(Self);
  FBookManager.Parent := BookmarkSide;
  FBookManager.TreeView.Images := toolbarIcons;
  FBookManager.TreeView.StateImages := RequestIcons;
  FBookManager.ImageIndexFolder := 0;
  FBookManager.ImageIndexSelected := 5;
  FBookManager.ImageIndexRoot := 8;
  FBookManager.OnChangeBookmark := @OnChangeBookmark;
  with FBookManager.Popup do begin
    OnEditClick := @BookmarkEditorShow;
    OnDeleteClick := @OnDeleteBookmark;
    Images := toolbarIcons;
    Items[0].ImageIndex := 11; // open
    Items[1].ImageIndex := 10; // new folder
    Items[2].ImageIndex := 9;  // edit
    Items[3].ImageIndex := 8;  // delete
  end;
  LoadAppBookmarks(FBookManager);

  SelectBodyTab(btForm);
  SelectAuthTab(atNone);
  pagesRequest.ActivePage := tabHeaders;
  FKeepResponseTab := '';

  StartNewRequest;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Save the current bookmark.
  if Assigned(FBookManager.CurrentBookmark) then
    FBookManager.CurrentBookmark.UpdateRequest(CreateRequestObject);
  SaveAppBookmarks(FBookManager);

  FreeAndNil(FResponseTabManager);

  if Assigned(FProfilerGraph) then
    FreeAndNil(FProfilerGraph);

  // Если не освободить, то когда активна вкладка JSON при выходе
  // из приложения возникают исключения что память не освобождена.
  jsImages.Free;

  // In some rare situations Terminate leads to access violation error.
  {if Assigned(FHttpClient) then begin
    FHttpClient.Terminate;
  end;}

  // Free and save options.
  OptionsForm.Free;

  inherited;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case OptionsForm.GetShortCutItem(Key, Shift) of
    sciFocusUrl:    cbUrl.SetFocus;
    sciFocusMethod: cbMethod.SetFocus;
    sciSubmit:      btnSubmitClick(Sender);
    sciBookmark:    btnBookmarkClick(Sender);
    sciSwitchView: begin
      // Switch views in the response tab (list or text view).
      if pagesResponse.ActivePage = tabResponse then
        case GetSelectedResponseViewTab of
          rvList:    SelectResponseViewTab(rvText);
          rvText:    SelectResponseViewTab(rvTimings);
          rvTimings: SelectResponseViewTab(rvList);
        end;
    end;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  I: Byte;
begin
  // Restore tabs visibility.
  ViewSwitchTabs(nil);
  ViewToggleTabs(nil);
  // OnResize callback should be after ToggleBookmarksSide otherwise
  // bookmarks will be always opened despite on its status.
  if not Assigned(BookmarkSide.OnResize) then
    BookmarkSide.OnResize := @PairSplitterResize;
  // Select and show active visible tab.
  for I := 0 to pagesRequest.PageCount - 1 do
    if pagesRequest.Pages[I].TabVisible then begin
      pagesRequest.ActivePageIndex := I;
      break;
    end;
end;

procedure TMainForm.gaClearRowsClick(Sender: TObject);
var
  Grid: TStringGrid;
begin
  Grid := GetPopupSenderAsStringGrid(Sender);
  DoGridOperation(Grid, goClear);
end;

procedure TMainForm.gaEditRowClick(Sender: TObject);
var
  Grid: TStringGrid;
begin
  Grid := GetPopupSenderAsStringGrid(Sender);
  DoGridOperation(Grid, goEdit);
end;

procedure TMainForm.gaInsertRowClick(Sender: TObject);
var
  Grid: TStringGrid;
begin
  Grid := GetPopupSenderAsStringGrid(Sender);
  DoGridOperation(Grid, goNew);
end;

procedure TMainForm.gridColRowInserted(Sender: TObject; IsColumn: Boolean; sIndex,
  tIndex: Integer);
begin
  // New inserted columns with "On" checked by default.
  (Sender as TStringGrid).Cells[0, sIndex] := '1';
end;

procedure TMainForm.gridEditDblClick(Sender: TObject);
var
  grid: TStringGrid;
begin
  if Sender is TStringGrid then begin
    grid := TStringGrid(Sender);
    if grid = responseHeaders then
    begin
      if grid.RowCount > 1 then
        KeyValueForm.View(GetRowKV(grid), 'View: ' + grid.Cells[0, grid.Row])
    end
    else
      EditGridRow(grid);
  end;
end;

procedure TMainForm.gridFormSelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
begin
  if aCol = 3 then
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do begin
        Style := csDropDownList;
        Items.CommaText := 'Text,File';
      end;
end;

procedure TMainForm.gridParamsCheckboxToggled(sender: TObject; aCol,
  aRow: Integer; aState: TCheckboxState);
var
  Params: TQueryParams;
  KV: TKeyValue;
  I: Integer;
begin
  Params:=nil;
  try
    KV:=GetRowKV(gridParams, aRow);
    if KV.Key = '' then Exit;
    Params := GetURLQueryParams(cbUrl.Text);
    I := Params.IndexOf(KV.Key);
    // Add param to the url.
    if (IsRowEnabled(gridParams, aRow)) and (I = -1) then
      Params.AddOrSetData(KV.Key, KV.Value);
    // Remove param from the url
    if (not IsRowEnabled(gridParams, aRow)) and (I >= 0) then
      Params.Remove(KV.Key);
    // Construct a new url.
    cbUrl.Text:=ReplaceURLQueryParams(cbUrl.Text, Params);
  finally
    FreeAndNil(Params);
  end;
end;

procedure TMainForm.gridParamsEditingDone(Sender: TObject);
begin
  SyncGridQueryParams;
end;

procedure TMainForm.gridRespCookieDblClick(Sender: TObject);
begin
  with TCookieForm.Create(Self) do begin
    ResponseGrid := gridRespCookie;
    RequestGrid := gridReqCookie;
    View;
    Free;
  end;
end;

procedure TMainForm.miBookmarksClick(Sender: TObject);
begin
  miBookmarks.Checked := not miBookmarks.Checked;
  ToggleBookmarksSide(miBookmarks.Checked);
end;

procedure TMainForm.miExportClick(Sender: TObject);
begin
  if Trim(cbUrl.Text) = '' then begin
    OKMsg('Export', 'Request url is missing.');
    Exit;
  end;
  with TExportForm.Create(Self) do begin
    ShowModal;
    Free;
  end;
end;

procedure TMainForm.miFindClick(Sender: TObject);
var
  tab: TResponseTab;
  Sel: string;
  Page: TTabSheet;
  Txt: TMemo;
begin
  Page := pagesResponse.ActivePage;
  // Autofill find text from the raw content tab.
  if (Page = tabContent) or (Page = tabResponse) then begin
    if Page = tabContent then
      Txt := responseRaw;
    if Page = tabResponse then begin
      // Don't show find dialog if response timing tab is opened.
      if pagesRespView.ActivePage = tabRespTime then
        Exit;
      Txt := textResp;
    end;
    if Txt.SelText <> '' then
      dlgFind.FindText := txt.SelText;
  end
  else begin
    // Autofill find text from the response tab.
    tab := FResponseTabManager.CanFind;
    if (tab <> Nil) and (Page = tab.TabSheet) and (tab is IEditorSelectedText) then begin
      Sel := (tab as IEditorSelectedText).SelectedText;
      if Sel <> '' then
        dlgFind.FindText := Sel;
    end;
  end;
  dlgFind.Execute;
end;

procedure TMainForm.miFindNextClick(Sender: TObject);
begin
  FindText;
end;

procedure TMainForm.miHelpCmdClick(Sender: TObject);
begin
  THelpForm.HelpModal(Self, 'Command line help', Trim(Usage));
end;

procedure TMainForm.miImportClick(Sender: TObject);
begin
  with TImportForm.Create(Self) do begin
    if ShowModal = mrOK then begin
      if RequestObjects.Count = 0 then
        ERRMsg('Error', 'Data not imported.')
      else
        Self.SetRequestObject(RequestObjects.Items[0].RequestObject);
    end;
    Free;
  end;
end;

procedure TMainForm.JsonTreeDblClick(Sender: TObject);
var
  Node: TTreeNode;
begin
  if Sender is TTreeView then begin
    Node := TTreeView(Sender).Selected;
    if not Assigned(Node) then
      Exit;
    // Double click on parent nodes expand/collapse children.
    // But on child node shows KeyValue modal.
    if not Node.HasChildren then
      JsonTreePopupMenuClick(miJsonView);
  end;
end;

// Various copy operations on Json tree node.
// Popup menu handler for the following operations:
// 1. Copy node value. For root values (object, array) it will copy the whole
//    child tree.
// 2. Copy node key.
// 3. Copy node key + value.
procedure TMainForm.JsonTreePopupMenuClick(Sender: TObject);
var
  Node, ParentNode: TTreeNode;
  MenuItem: TMenuItem;
  JsonData, ParentData: TJSONData;
  I: Integer;
  Value, Key: String;
begin
  Node := FResponseJsonTab.TreeView.Selected;
  if not Assigned(Node) then Exit;

  // Get json node value.
  JsonData := TJSONData(Node.Data);
  case JsonData.JSONType of
    jtNumber, jtString, jtBoolean: Value := JsonData.AsString;
    jtArray, jtObject:             Value := FormatJson(JsonData);
    jtNull:                        Value := '';
  end;

  MenuItem := Sender as TMenuItem;
  if MenuItem = miJsonCopyValue then
  begin
    Clipboard.AsText := Value;
    Exit;
  end;

  // Get json node key.
  Key := '';
  ParentNode := Node.Parent;

  // Expand/collapse children.
  if MenuItem = miJsonCollapse then
    FResponseJsonTab.ExpandChildren(Node, True);
  if MenuItem = miJsonExpand then
    FResponseJsonTab.ExpandChildren(Node);

  // The items that require a key don't work without the parent.
  if not Assigned(ParentNode) then Exit;

  ParentData := TJSONData(ParentNode.Data);
  case ParentData.JSONType of
    jtObject:
      begin
        I := TJSONObject(ParentData).IndexOf(JsonData);
        if I >= 0 then
          Key := TJSONObject(ParentData).Names[I];
      end;
    jtArray:
      begin
        I := TJSONArray(ParentData).IndexOf(JsonData);
        if I >= 0 then
          Key := IntToStr(I);
      end;
  end;

  if MenuItem = miJsonCopyKey then
    Clipboard.AsText := Key
  else if MenuItem = miJsonCopyValueKey then
    Clipboard.AsText := IfThen(Key = '', Value, Format('"%s": %s', [Key, FormatJson(JsonData)]));

  if MenuItem = miJsonView then
    KeyValueForm.View(Key, Value, Key);

  if MenuItem = miJsonFilter then
    FResponseJsonTab.Filter(Node);
end;

procedure TMainForm.miManageHeadersClick(Sender: TObject);
var
  i, aRow, p1, p2: integer;
  gridHeaders: TStringGrid;
  hname, hvalue: string;
begin
  gridHeaders := HeadersEditorForm.gridHeaders;
  // Button "Insert" pressed.
  if (HeadersEditorForm.ShowModal = mrOK) and
     (gridHeaders.SelectedRangeCount > 0) then
  begin
    for i := 0 to gridHeaders.SelectedRangeCount - 1 do
    begin
      aRow := gridHeaders.SelectedRange[i].Top;
      hname := gridHeaders.Cells[0, aRow];
      hvalue := gridHeaders.Cells[1, aRow];
      with requestHeaders do begin
        p1 := Cols[1].IndexOf(hname);
        p2 := Cols[2].IndexOf(hvalue);
        // A new header-value pair.
        if (p1 = -1) then begin
          RowCount := RowCount + 1;
          Row := RowCount - 1;
          Cells[0, Row] := '1';
          Cells[1, Row] := hname;
          Cells[2, Row] := hvalue;
        end;
        // Update a header value.
        if (p1 <> -1) and (p1 <> p2) then begin
          Cells[2, p1] := hvalue;
        end;
      end;
    end;
  end;
  UpdateHeadersPickList;
end;

procedure TMainForm.miNewClick(Sender: TObject);
begin
  if PromptNewRequest('Are you sure you want to start a new request ?') then begin
    StartNewRequest;
    cbUrl.SetFocus;
  end;
end;

procedure TMainForm.miNewWindowClick(Sender: TObject);
begin
  AppExec(Application.ExeName, ['--new']);
end;

procedure TMainForm.miOpenRequestClick(Sender: TObject);
var
  jsonStr: string;
begin
  if not PromptNewRequest('Do you want to open a request file ?', 'Open request file') then Exit;

  dlgOpen.DefaultExt := 'json';
  if dlgOpen.Execute then begin

    if not FileGetContents(dlgOpen.FileName, jsonStr) then begin
      ShowMessage('Cannot read file ' + dlgOpen.FileName);
      Exit;
    end;

    OpenRequestFile(jsonStr);
  end;
end;

procedure TMainForm.miOptionsClick(Sender: TObject);
begin
  if OptionsForm.ShowModal = mrOK then ApplyOptions;
end;

procedure TMainForm.miQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.miAboutClick(Sender: TObject);
begin
  with TAboutForm.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TMainForm.gaDeleteRowClick(Sender: TObject);
var
  Grid: TStringGrid;
begin
  Grid := GetPopupSenderAsStringGrid(Sender);
  DoGridOperation(Grid, goDelete);
end;

procedure TMainForm.miSaveRequestClick(Sender: TObject);
var
  obj: TRequestObject;
  json: string;
begin
  try
    obj := CreateRequestObject;
    try
      dlgSave.FileName := GetRequestFilename(cbUrl.Text, FContentType, 'request.json');
      dlgSave.Title := 'Save the request to a file';
      json := obj.ToJson;
      if json = '' then
        raise Exception.Create('Cannot convert the request to a string.');
      if dlgSave.Execute then
        if not FilePutContents(dlgSave.Filename, obj.ToJson) then
          ShowMessage('Cannot create file ' + dlgSave.FileName);
    except on E: Exception do
      ShowMessage(E.Message);
    end;
  finally
    obj.Free;
  end;
end;

procedure TMainForm.miSaveResponseClick(Sender: TObject);
begin
  try
    dlgSave.FileName := GetRequestFilename(cbUrl.Text, FContentType);
    dlgSave.Title := 'Save the response to a file';
    if dlgSave.Execute then begin
      if (FResponseTabManager.OpenedTabs.Count = 0) and (tabContent.TabVisible) then
        responseRaw.Lines.SaveToFile(dlgSave.FileName)
      else
        FResponseTabManager.Save(dlgSave.FileName);
    end;
  except on E: Exception do
    ShowMessage(E.Message);
  end;
end;

procedure TMainForm.OnGridClear(Sender: TObject; Grid: TStringGrid);
begin
  // Force to update url query params.
  if Grid = gridParams then SyncGridQueryParams;
  Grid.SetFocus;
end;

procedure TMainForm.OnGridDeleteRow(Sender: TObject; Grid: TStringGrid);
begin
  // Force to update url query params.
  if Grid = gridParams then SyncGridQueryParams;
  Grid.SetFocus;
end;

procedure TMainForm.OnGridEditRow(Sender: TObject; Grid: TStringGrid;
  const aRow: Integer);
begin
  EditGridRow(Grid);
  Grid.SetFocus;
end;

procedure TMainForm.OnGridNewRow(Sender: TObject; Grid: TStringGrid;
  const aRow: Integer);
begin
  // New inserted columns with "On" checked by default.
  Grid.Cells[0, aRow] := '1';
  if EditGridRow(Grid) <> mrOK then
    Grid.DeleteRow(aRow);
  Grid.SetFocus;
end;

procedure TMainForm.pagesResponseChange(Sender: TObject);
begin
  // Switching between tabs resets FindNext search.
  // This behaviour doesn't affect the search from the response_tabs unit
  // in case when a response tab implements find methods with the internal next position.
  ResetFindTextPos;
  // Keep an opened response tab for the next request.
  KeepCurrentResponseTab;
end;

procedure TMainForm.PairSplitterResize(Sender: TObject);
var
  pss: TPairSplitterSide;
  splSize: Integer;
begin
  if not (Sender is TPairSplitterSide) then
    Exit; // =>
  pss := TPairSplitterSide(Sender);
  if (pss = BookmarkSide) then begin
    miBookmarks.Checked := pss.Width > 1;
  end
  else if (pss = splitterSideRequest) then begin
    if (LayoutSplitter.SplitterType = pstVertical) then
      splSize := pss.Height
    else
      splSize := pss.Width;
    miTabToggle.Checked := splSize > 1;
    ViewToggleTabsMenu(miTabToggle.Checked);
  end;
end;

procedure TMainForm.pmAuthTypeClick(Sender: TObject);
var
  mi: TMenuItem;
begin
  mi := Sender as TMenuItem;
  if mi = miAuthNone then SelectAuthTab(atNone)
  else if mi = miAuthBasic then SelectAuthTab(atBasic)
  else if mi = miAuthBearer then SelectAuthTab(atBearer);
end;

procedure TMainForm.pmBodyTypeClick(Sender: TObject);
var
  mi: TMenuItem;
begin
  mi := Sender as TMenuItem;
  if mi = miBodyForm then SelectBodyTab(btForm)
  else if mi = miBodyJson then SelectBodyTab(btJson)
  else if mi = miBodyOther then SelectBodyTab(btOther);
end;

// Show/hide some items in Grid's popup menu.
// Depending on grid popup menu can show or hide some menu items for specific
// grid.
procedure TMainForm.popupGridActionsPopup(Sender: TObject);
begin
  gaSaveHeader.Visible := False;
  gaManageHeaders.Visible := False;
  if GetPopupSenderAsStringGrid(Sender) = requestHeaders then begin
    gaManageHeaders.Visible := True;
    gaSaveHeader.Visible := True;
  end;
end;

procedure TMainForm.PSMAINRestoreProperties(Sender: TObject);
begin
  // Update Query tab and app title.
  SetAppCaption(UrlPath(cbUrl.Text));
  SyncURLQueryParams;
  FBookManager.BookmarkNodeStyle := OptionsForm.BookmarkNodeStyle;
  EnableSubmitButton;
end;

procedure TMainForm.PSMAINRestoringProperties(Sender: TObject);
  procedure SetColumns(grid: TStringGrid);
  var
    Val, col: Integer;
  begin
    for col := 1 to grid.ColCount do begin
      Val := PSMAIN.ReadInteger(grid.Name + 'Col' + IntToStr(col), 0);
      if Val > 0 then grid.Columns.Items[col - 1].Width := Val;
    end;
  end;
var
  IntVal: integer;
  StrVal: string;
  RO: TRequestObject;
begin
  SetColumns(requestHeaders);
  SetColumns(responseHeaders);
  SetColumns(gridForm);
  SetColumns(gridReqCookie);
  SetColumns(gridRespCookie);
  SetColumns(gridParams);
  with PSMAIN do begin
    miTabHeaders.Checked := ReadBoolean('tabHeaders', True);
    miTabQuery.Checked := ReadBoolean('tabQuery', True);
    miTabCookie.Checked := ReadBoolean('tabCookie', True);
    miTabBody.Checked := ReadBoolean('tabBody', True);
    miTabAuth.Checked := ReadBoolean('tabAuth', True);
    miTabNotes.Checked := ReadBoolean('tabNotes', True);
    miTabToggle.Checked := ReadBoolean('tabToggle', True);
    miBookmarks.Checked := ReadBoolean('bookmarks', True);
    StrVal := ReadString('selBookmark', '');
    if StrVal <> '' then
      FBookManager.OpenBookmarkPath(StrVal)
    else begin
      StrVal := ReadString('currentRequest', '');
      if StrVal <> '' then begin
        try
          RO := TRequestObject.CreateFromJson(StrVal);
          SetRequestObject(RO);
        finally
          RO.Free;
        end;
      end;
    end;
    // Read splitter side sizes.
    IntVal := ReadInteger(STATE_SPLITTER_SIDE, 0);
    if IntVal > 0 then
      AppState.WriteInteger(STATE_SPLITTER_SIDE, IntVal);
    IntVal := ReadInteger(STATE_BOOKMARK_SIDE, 0);
    if IntVal > 0 then
      AppState.WriteInteger(STATE_BOOKMARK_SIDE, IntVal);
  end;
end;

procedure TMainForm.PSMAINSavingProperties(Sender: TObject);
  procedure SaveColumns(grid: TStringGrid);
  var
    I: Integer;
  begin
    for I := 0 to grid.Columns.Count - 1 do
      PSMAIN.WriteInteger(grid.Name + 'Col' + IntToStr(I + 1), grid.Columns.Items[I].Width);
  end;
var
  RO: TRequestObject;
begin
  SaveColumns(requestHeaders);
  SaveColumns(gridForm);
  SaveColumns(responseHeaders);
  SaveColumns(gridReqCookie);
  SaveColumns(gridRespCookie);
  SaveColumns(gridParams);
  with PSMAIN do begin
    WriteBoolean('tabHeaders', miTabHeaders.Checked);
    WriteBoolean('tabQuery', miTabQuery.Checked);
    WriteBoolean('tabCookie', miTabCookie.Checked);
    WriteBoolean('tabBody', miTabBody.Checked);
    WriteBoolean('tabAuth', miTabAuth.Checked);
    WriteBoolean('tabNotes', miTabNotes.Checked);
    WriteBoolean('tabToggle', miTabToggle.Checked);
    WriteBoolean('bookmarks', miBookmarks.Checked);
    // Save the selected bookmark or the current request.
    with FBookManager do
      if CurrentBookmark = NIL then begin
        WriteString('selBookmark', '');
        try
          RO := CreateRequestObject;
          WriteString('currentRequest', RO.ToJson);
        finally
          RO.Free;
        end;
      end
      else begin
        WriteString('selBookmark', GetBookmarkPath(CurrentBookmark));
        WriteString('currentRequest', '');
      end;
    // Save splitter side sizes before it has been hidden.
    if AppState.ReadInteger(STATE_SPLITTER_SIDE, 0) > 0 then
      WriteInteger(STATE_SPLITTER_SIDE, AppState.ReadInteger(STATE_SPLITTER_SIDE, 0));
    if AppState.ReadInteger(STATE_BOOKMARK_SIDE, 0) > 0 then
      WriteInteger(STATE_BOOKMARK_SIDE, AppState.ReadInteger(STATE_BOOKMARK_SIDE, 0));
  end;
end;

procedure TMainForm.requestHeadersBeforeSelection(Sender: TObject; aCol,
  aRow: Integer);
var
  header: string;
begin
  header := Trim(GetRowKV(requestHeaders, aRow).Key);
  if header <> '' then
    HeadersEditorForm.FillHeaderValues(header, requestHeaders.Columns.Items[2].PickList);
end;

procedure TMainForm.tbtnFormUploadClick(Sender: TObject);
var
  Row, A: Integer;
begin
  if gridForm.RowCount = 1 then Exit;
  Row := gridForm.Row;

  if gridForm.Cells[3, Row] <> 'File' then begin
    A := ConfirmDlg('Upload', 'To upload a file the form element must be the file type.'#13'Do you want to change it to the file type ?');
    if A = mrOK then
      gridForm.Cells[3, Row] := 'File';
  end;

  if gridForm.Cells[3, Row] = 'File' then begin
    dlgOpen.Title := 'Upload a file';
    if dlgOpen.Execute then
      gridForm.Cells[2, Row] := dlgOpen.FileName;
  end;
end;

procedure TMainForm.tbtnJsonLoadClick(Sender: TObject);
var
  fs: TStream;
  parser: TJSONParser;
begin
  if dlgOpen.Execute then begin
    try
      // Load and validate a json file.
      fs := TFileStream.Create(dlgOpen.FileName, fmOpenRead);
      Parser := TJSONParser.Create(fs);
      try
        Parser.Parse;
        fs.Position := 0; // Stream should be resetted to the beginning after json parser
        editJson.Lines.LoadFromStream(fs);
      except on E: Exception do
        ERRMsg('Load error', E.Message);
      end;
    finally
      FreeAndNil(Parser);
      FreeAndNil(fs);
    end;
  end;
end;

procedure TMainForm.tbtnManageHeadersClick(Sender: TObject);
begin
  miManageHeadersClick(requestHeaders);
end;

procedure TMainForm.tbtnBodyFormatClick(Sender: TObject);
var
  ErrMsg: string;
begin
  if Length(Trim(editJson.Text)) = 0 then
    Exit;
  if not SetJsonBody(editJson.Text, ErrMsg) then
    ShowMessage(ErrMsg);
end;

procedure TMainForm.tbtnRespFollowClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 1 to responseHeaders.RowCount do
    if (LowerCase(responseHeaders.Cells[0, I]) = 'location') then begin
      cbUrl.Text := responseHeaders.Cells[1, I];
      btnSubmitClick(btnSubmit);
      Exit;
    end;
end;

procedure TMainForm.tbtnRespViewClick(Sender: TObject);
var
  btn: TToolButton;
begin
  if not (Sender is TToolButton) then
    Exit; // =>
  btn := TToolButton(Sender);
  if btn = tbtnRespList then
    SelectResponseViewTab(rvList)
  else if btn = tbtnRespText then
    SelectResponseViewTab(rvText)
  else if btn = tbtnRespTime then
    SelectResponseViewTab(rvTimings);
end;

procedure TMainForm.tbtnSaveHeaderClick(Sender: TObject);
var
  KV: TKeyValue;
begin
  KV := GetRowKV(requestHeaders);
  if KV.Key <> '' then
    HeadersEditorForm.Add(KV.Key, KV.Value);
end;

procedure TMainForm.TimerRequestTimer(Sender: TObject);
var
  Min, Sec: Integer;
begin
  Inc(FRequestSeconds);
  Min := FRequestSeconds div 60;
  Sec := FRequestSeconds mod 60;
  StatusTextInfo.Caption := Format('%.2d:%.2d', [Min, Sec]);
end;

procedure TMainForm.ViewSwitchLayout(Sender: TObject);
var
  mi: TMenuItem;
begin
  if (Sender is TMenuItem) then begin
    mi := TMenuItem(Sender);
    if mi = miLayoutVert then
      OptionsForm.PanelsLayout := pstVertical;
    if mi = miLayoutHor then
      OptionsForm.PanelsLayout := pstHorizontal;
    SwitchLayout;
  end;
end;

procedure TMainForm.ViewSwitchTabs(Sender: TObject);
var
  mi: TMenuItem;
  I: Byte;
  Restore: Boolean; // Need to restore Request splitter side ?
begin
  if (Sender <> Nil) and (Sender is TMenuItem) then begin
    mi := TMenuItem(Sender);
    mi.Checked := not mi.Checked;
  end;
  // Should the splitter side restored ?
  Restore := True;
  for I := 0 to pagesRequest.PageCount - 1 do
    // Don't restore if one of tabs is visible.
    if pagesRequest.Pages[I].TabVisible then begin
      Restore := False;
      Break;
    end;
  // Switch tabs visibility.
  tabHeaders.TabVisible := miTabHeaders.Checked;
  tabQuery.TabVisible := miTabQuery.Checked;
  tabBody.TabVisible := miTabBody.Checked;
  tabReqCookie.TabVisible := miTabCookie.Checked;
  tabAuth.TabVisible := miTabAuth.Checked;
  tabNotes.TabVisible := miTabNotes.Checked;
  for I := 0 to pagesRequest.PageCount - 1 do
    if pagesRequest.Pages[I].TabVisible then begin
      if Restore then
        ToggleRequestSide(True);
      Exit; //=>
    end;
  // Hide request splitter side.
  ToggleRequestSide(False);
end;

procedure TMainForm.ViewToggleTabs(Sender: TObject);
begin
  if Sender <> nil then
    miTabToggle.Checked := not miTabToggle.Checked;
  with miTabToggle do begin
    ViewToggleTabsMenu(Checked);
    ToggleRequestSide(Checked);
  end;
end;

procedure TMainForm.ViewToggleTabsMenu(Status: Boolean);
begin
  pagesRequest.Visible     := Status;
  OptionsForm.LayoutEnable := Status;
  miTabHeaders.Enabled     := Status;
  miTabQuery.Enabled       := Status;
  miTabBody.Enabled        := Status;
  miTabCookie.Enabled      := Status;
  miTabAuth.Enabled        := Status;
  miTabNotes.Enabled       := Status;
  miLayoutHor.Enabled      := Status;
  miLayoutVert.Enabled     := Status;
end;

// Synchronizes query parameters from the url.
procedure TMainForm.SyncURLQueryParams;
var
  Params, Keep: TQueryParams;
  I, Idx: Integer;
  KV: TKeyValue;
begin
  Params:=nil;
  try
    Keep:=TQueryParams.Create;
    Params := GetURLQueryParams(cbUrl.Text);
    // Preserve disabled params.
    for I:=1 to gridParams.RowCount-1 do
      if not IsRowEnabled(gridParams, I) then begin
        KV:=GetRowKV(gridParams, I);
        if KV.Key='' then Continue;
        Keep.Add(KV.Key, KV.Value);
      end;
    gridParams.RowCount:=1;
    for I:=0 to Params.Count-1 do
      gridParams.InsertRowWithValues(I+1, ['1', Params.Keys[I], Params.Data[I]]);
    // Return disabled params to the grid.
    for I:=0 to Keep.Count-1 do begin
      Idx:=gridParams.Cols[1].IndexOf(Keep.Keys[I]);
      if Idx = -1 then
        gridParams.InsertRowWithValues(gridParams.RowCount, ['0', Keep.Keys[I], Keep.Data[I]]);
    end;
  finally
    FreeAndNil(Params);
    FreeAndNil(Keep);
  end;
end;

// Synchronizes query parameters from the grid.
procedure TMainForm.SyncGridQueryParams;
var
  Params: TQueryParams;
  KV: TKeyValue;
  I: Integer;
begin
  Params := TQueryParams.Create;
  try
    for I:=1 to gridParams.RowCount-1 do begin
      if not IsRowEnabled(gridParams, I) then Continue;
      KV:=GetRowKV(gridParams, I);
      if KV.Key = '' then Continue;
      Params.AddOrSetData(KV.Key, KV.Value);
    end;
    cbUrl.Text:=ReplaceURLQueryParams(cbUrl.Text, Params);
  finally
    FreeAndNil(Params);
  end;
end;

function TMainForm.IsRowEnabled(const grid: TStringGrid; aRow: Integer): Boolean;
begin
  if aRow = -1 then aRow := grid.Row;
  Result := grid.Cells[0, aRow] = '1';
end;

procedure TMainForm.SelectBodyTab(const tab: TBodyTab);
begin
  tbtnFormUpload.Visible  := False;
  tbtnBodyFormat.Visible  := False;
  tbtnBodyType.Visible    := False;
  tbtnJsonLoad.Visible    := False;
  gnavBody.ShowNavButtons := False;

  case tab of
    btForm:
      begin
        pagesBody.ActivePage := tabBodyForm;
        // This procedure is invoked in Form's Create method when
        // options form is not initalized yet. So, for the first time
        // we always show toolbar.
        if Assigned(OptionsForm) then
          gnavBody.ShowNavButtons := not OptionsForm.GridButtonsHidden
        else
          gnavBody.ShowNavButtons := True;
        tbtnBodyType.Visible := True;
        tbtnFormUpload.Visible := True;
        tbtnBodyType.Caption := 'Form';
      end;
    btJson:
      begin
        pagesBody.ActivePage:=tabBodyJson;
        tbtnBodyType.Visible:=True;
        tbtnBodyType.Caption:='JSON';
        tbtnBodyFormat.Visible:=True;
        tbtnJsonLoad.Visible:=True;
      end;
    btOther:
      begin
        pagesBody.ActivePage:=tabBodyOther;
        tbtnBodyType.Visible:=True;
        tbtnBodyType.Caption:='Other';
      end;
  end;

  tabBody.Caption := 'Body: ' + tbtnBodyType.Caption;

  // Keep buttons order after some buttons are hidden.
  gnavBody.SetButtonsOrder;
end;

procedure TMainForm.SelectAuthTab(const tab: TAuthTab);
begin
  if tab = atNone then
    pagesAuth.Visible := False
  else begin
    pagesAuth.Visible := True;
    pagesAuth.ActivePageIndex := LongInt(tab);
  end;

  case tab of
    atNone:   tbtnAuthType.Caption := 'None';
    atBasic:  tbtnAuthType.Caption := 'Basic';
    atBearer: tbtnAuthType.Caption := 'Bearer token';
  end;

  tabAuth.Caption := 'Auth: ' + tbtnAuthType.Caption;
end;

function TMainForm.GetSelectedBodyTab: TBodyTab;
begin
  case pagesBody.ActivePageIndex of
    0: Result:=btJson;
    1: Result:=btForm;
    2: Result:=btOther;
    else raise Exception.Create('No value for active tab.');
  end;
end;

function TMainForm.GetSelectedAuthTab: TAuthTab;
begin
  if pagesAuth.Visible then
    case pagesAuth.ActivePageIndex of
      0: Result := atBasic;
      1: Result := atBearer;
      else raise Exception.Create('No value for active tab');
    end
  else
    Result := atNone;
end;

function TMainForm.GetSelectedResponseViewTab: TResponseView;
begin
  if pagesRespView.ActivePage = tabRespText then
    Exit(rvText);
  if pagesRespView.ActivePage = tabRespList then
    Exit(rvList);
  if pagesRespView.ActivePage = tabRespTime then
    Exit(rvTimings);
  raise Exception.Create('Cannot get value for response view active page.');
end;

procedure TMainForm.DoGridOperation(Grid: TStringGrid; const op: TGridOperation);
var
  toolbar: TGridNavigator;
begin
  if Grid = requestHeaders then
    toolbar := gnavHeaders
  else if Grid = gridParams then
    toolbar := gnavParams
  else if Grid = gridForm then
    toolbar := gnavBody
  else if Grid = gridReqCookie then
    toolbar := gnavCookie
  else
    Exit;

  case op of
    goNew:    toolbar.NewButton.Click;
    goEdit:   toolbar.EditButton.Click;
    goDelete: toolbar.DeleteButton.Click;
    goClear:  toolbar.ClearButton.Click;
  end;
end;

procedure TMainForm.OnOpenResponseTab(Tab: TResponseTab;
  ResponseInfo: TResponseInfo);
var
  ImageTab: TResponseImageTab;
begin
  if Tab = FResponseJsonTab then
    with FResponseJsonTab do begin
      // set toolbar icons.
      with Toolbar do begin
        Images := toolbarIcons;
        Buttons[0].ImageIndex := 13; // tree
        Buttons[1].ImageIndex := 1;  // formatted
        Buttons[2].ImageIndex := 12; // options
        Buttons[3].ImageIndex := 14; // filter
      end;
      TreeView.Images := jsImages;
      TreeView.PopupMenu := popupJsonTree;
      TreeView.OnDblClick := @JsonTreeDblClick;
      TreeView.Font := OptionsForm.GetFontItem(fiJson);
      SynEdit.Highlighter := synJS;
      SynEdit.Font := OptionsForm.GetFontItem(fiEditor);
      ButtonOptions.OnClick := @OnJsonTabButtonOptionsClick;
      ViewPage := OptionsForm.JsonView;
      LineNumbers := OptionsForm.JsonLines;
    end // with
  else if Tab is TResponseImageTab then begin
    ImageTab := TResponseImageTab(Tab);
    if OptionsForm.FitImages then
      ImageTab.ResizeImage(True);
    StatusTextInfo.Caption := Format('%s: %d x %d', [
      ImageTab.ImageType,
      ImageTab.Image.Picture.Width,
      ImageTab.Image.Picture.Height
    ]);
  end;
end;

procedure TMainForm.OnSaveResponseTab(const FileName: string; Tab: TResponseTab);
begin
  if Tab is TResponseJsonTab then begin
    if OptionsForm.JsonSaveFormatted then
      FilePutContents(FileName, FormatJson(TResponseJsonTab(Tab).JsonRoot))
    else
      responseRaw.Lines.SaveToFile(FileName)
  end

  else
    Tab.Save(FileName);
end;

procedure TMainForm.OnJsonTabButtonOptionsClick(Sender: TObject);
begin
  if OptionsForm.ShowModalPage(opJson) = mrOK then
    ApplyOptions;
end;

procedure TMainForm.JsonTab_OnJsonFormat(JsonData: TJSONData; Editor: TSynEdit);
begin
  Editor.Text := FormatJson(JsonData);
end;

procedure TMainForm.FindStart(Search: Boolean = True);
var
  tab: TResponseTab;
  IsText: Boolean;
begin
  FFindTextPos := 0;
  IsText := not dlgFind.FindText.Trim.IsEmpty;
  tab := FResponseTabManager.CanFind;
  if (tab <> nil) and (IsText) then
    tab.InitSearch(dlgFind.FindText, dlgFind.Options);
  if IsText then
    miFindNext.Enabled := True;
  if Search then
    FindText;
end;

procedure TMainForm.ToggleRequestSide(VisibleSide: Boolean);
begin
  if not VisibleSide then begin
    if (LayoutSplitter.SplitterType = pstVertical) and (splitterSideRequest.Height > 1) then
    begin
      AppState.WriteInteger(STATE_SPLITTER_SIDE, splitterSideRequest.Height);
      splitterSideRequest.Height := 0;
    end
    else if (LayoutSplitter.SplitterType = pstHorizontal) and (splitterSideRequest.Width > 1) then
    begin
      AppState.WriteInteger(STATE_SPLITTER_SIDE, splitterSideRequest.Width);
      splitterSideRequest.Width := 0;
    end;
  end
  else begin
    if (LayoutSplitter.SplitterType = pstVertical) and (splitterSideRequest.Height <= 1) then
      splitterSideRequest.Height := AppState.ReadInteger(STATE_SPLITTER_SIDE, LayoutSplitter.Height div 2)
    else if (LayoutSplitter.SplitterType = pstHorizontal) and (splitterSideRequest.Width <= 1) then
      splitterSideRequest.Width :=  AppState.ReadInteger(STATE_SPLITTER_SIDE, LayoutSplitter.Width div 2);
  end;
end;

procedure TMainForm.ToggleBookmarksSide(VisibleSide: Boolean);
begin
  if VisibleSide then begin
    BookmarkSide.Width := AppState.ReadInteger(STATE_BOOKMARK_SIDE, 150);
  end
  else begin
    AppState.WriteInteger(STATE_BOOKMARK_SIDE, BookmarkSide.Width);
    BookmarkSide.Width := 1;
  end;
  miBookmarks.Checked := VisibleSide;
end;

procedure TMainForm.FinishRequest;
begin
  Screen.Cursor := crDefault;
end;

procedure TMainForm.ResetFindTextPos;
begin
  FFindTextPos := 0;
end;

procedure TMainForm.EnableSubmitButton;
var
  isEmpty: Boolean;
begin
  isEmpty := False;
  if Length(Trim(cbUrl.Text)) = 0 then
    isEmpty := True;
  btnSubmit.Enabled := not isEmpty;
  btnBookmark.Enabled := not isEmpty;
end;

procedure TMainForm.BookmarkButtonIcon(Added: Boolean);
begin
  if Added then
    toolbarIcons.GetBitmap(BOOKMARK_IMG_SET, btnBookmark.Glyph)
  else
    toolbarIcons.GetBitmap(BOOKMARK_IMG_UNSET, btnBookmark.Glyph);
end;

procedure TMainForm.BookmarkEditorShow(Sender: TObject; BM: TBookmark);
var
  RO: TRequestObject;
begin
  with TBookmarkForm.Create(Self) do
  begin
    try
      RO := CreateRequestObject;
      BookmarkManager := FBookManager;
      case ShowModal(BM, RO) of
        mrAdded:   BookmarkButtonIcon(True);
        mrDeleted: begin
          if FBookManager.CurrentBookmark = NIL then
            BookmarkButtonIcon(False);
          FreeAndNil(RO);
        end;
        mrOk: begin
          // Update url for the current bookmark.
          if (FBookManager.CurrentBookmark = BM) and (RO.Url <> Bookmark.Request.Url) then
            cbUrl.Text := Bookmark.Request.Url;
          SyncGridQueryParams;
        end;
        else begin
          FreeAndNil(RO);
        end;
      end;
    except
      on E: Exception do begin
        ERRMsg('Error', E.Message);
      end;
    end;
    Free;
  end;
end;

procedure TMainForm.OnChangeBookmark(Prev, Selected: TBookmark);
begin
  if Assigned(Prev) then
    Prev.UpdateRequest(CreateRequestObject);
  StartNewRequest;
  BookmarkButtonIcon(True);
  SetRequestObject(Selected.Request);
  btnSubmit.Enabled := True;
  btnBookmark.Enabled := True;
end;

procedure TMainForm.OnDeleteBookmark(Sender: TObject; BM: TBookmark);
var
  Curr: TBookmark;
begin
  Curr := FBookManager.CurrentBookmark;
  if (Curr = BM) or (Curr = NIL) then
    BookmarkButtonIcon(False);
end;

procedure TMainForm.ApplyOptions;
begin
  editJson.TabWidth := OptionsForm.JsonIndentSize;
  FResponseJsonTab.TreeExpanded := OptionsForm.JsonExpanded;
  FResponseJsonTab.LineNumbers  := OptionsForm.JsonLines;

  SwitchLayout;

  if GetSelectedBodyTab = btForm then
    gnavBody.ShowNavButtons := not OptionsForm.GridButtonsHidden;
  gnavBody.SetButtonsOrder;
  gnavHeaders.Visible := not OptionsForm.GridButtonsHidden;
  // Ugly hack to hide toolbar.
  // Когда тулбар скрыт при запуске приложения он всё равно отображается как
  // пустая панель. (When toolbar is hidden it always shows like empty panel)
  if OptionsForm.GridButtonsHidden then
    gnavHeaders.Height := 0
  else
    gnavHeaders.Height := gnavBody.Height;
  gnavParams.Visible := not OptionsForm.GridButtonsHidden;
  gnavCookie.Visible := not OptionsForm.GridButtonsHidden;

  // Apply fonts
  OptionsForm.ApplyControlFont(Self, 'TStringGrid', fiGrids);
  OptionsForm.ApplyControlFont(Self, 'TSynEdit', fiEditor);
  OptionsForm.ApplyControlFont(Self, 'TTreeView', fiJson);
  KeyValueForm.textValue.Font := OptionsForm.GetFontItem(fiValue);
  responseRaw.Font := OptionsForm.GetFontItem(fiContent);
  textResp.Font := OptionsForm.GetFontItem(fiContent);

  cbMethod.ReadOnly := not OptionsForm.EditRequestMethods;

  editJson.Gutter.Parts.Part[1].Visible := OptionsForm.JsonLines;

  // Redefine shortcuts.
  miManageHeaders.ShortCut := OptionsForm.GetShortCutValue(sciManageHeaders);
  miOptions.ShortCut       := OptionsForm.GetShortCutValue(sciOptions);
  miFind.ShortCut          := OptionsForm.GetShortCutValue(sciFind);
  miFindNext.ShortCut      := OptionsForm.GetShortCutValue(sciFindNext);
  miNewWindow.ShortCut     := OptionsForm.GetShortCutValue(sciNewWindow);
  miNew.ShortCut           := OptionsForm.GetShortCutValue(sciNewRequest);
  miOpenRequest.ShortCut   := OptionsForm.GetShortCutValue(sciOpenRequest);
  miSaveRequest.ShortCut   := OptionsForm.GetShortCutValue(sciSaveRequest);
  miSaveResponse.ShortCut  := OptionsForm.GetShortCutValue(sciSaveBody);
  miTabToggle.ShortCut     := OptionsForm.GetShortCutValue(sciToggleTabs);
  miBookmarks.ShortCut     := OptionsForm.GetShortCutValue(sciToggleBookmarks);
  miQuit.ShortCut          := OptionsForm.GetShortCutValue(sciQuit);

  // Change bookmarks node style.
  FBookManager.BookmarkNodeStyle := OptionsForm.BookmarkNodeStyle;
end;

procedure TMainForm.SwitchLayout;
{$IfDef WINDOWS}
var
  s: string;
{$EndIf}
begin
  // Adjust window size before change layout.
  if (LayoutSplitter.SplitterType = pstVertical) and
       (OptionsForm.PanelsLayout = pstHorizontal) and
       (Width < 460) then
    Width := 600;
  if (LayoutSplitter.SplitterType = pstHorizontal) and
       (OptionsForm.PanelsLayout = pstVertical) and
       (Height < 400) then
    Height := 600;

  // Switching layout on Windows leads to fatal exception.
  // The reason is TMemo component (filled with the text).
  // This hack clears text before switching and then fills the text back.
  {$IfDef WINDOWS}
    Screen.Cursor := crHourGlass;
    s := responseRaw.Text;
    responseRaw.Clear;
  {$EndIf}
  LayoutSplitter.SplitterType := OptionsForm.PanelsLayout;
  {$IfDef WINDOWS}
    responseRaw.Text := s;
    Screen.Cursor := crDefault;
  {$EndIf}

  // View layout menu items.
  miLayoutHor.Checked := (OptionsForm.PanelsLayout = pstHorizontal);
  miLayoutVert.Checked := (OptionsForm.PanelsLayout = pstVertical);
end;

// Add values to request grid.
// Adjust header name from the predefined name from the headers editor form.
procedure TMainForm.AddRequestHeader(AHeader, AValue: string);
var
  headers: TStringList;
  iter: string;
  kv: TKeyValuePair;
begin
  headers := TStringList.Create;
  try
    HeadersEditorForm.FillHeaders(headers);
    for iter in headers do
      if LowerCase(iter) = LowerCase(AHeader) then begin
        AHeader := iter;
        break;
      end;
    kv.Key := AHeader;
    kv.Value := AValue;
    SetRowKV(requestHeaders, kv);
  finally
    headers.Free;
  end;
end;

procedure TMainForm.AddFormData(AName, AValue: string; isFile: Boolean);
var
  isUnique: Boolean = False;
  KV: TKeyValuePair;
  Added: Integer;
begin
  if AnsiContainsStr(AValue, '[]') then
    isUnique := False;
  KV.Key := AName;
  KV.Value := AValue;
  Added := SetRowKV(gridForm, KV, -1, isUnique);
  if isFile then
    gridForm.Cells[3, Added] := 'File';
end;

procedure TMainForm.OpenRequestFile(jsonStr: string);
var
  obj: TRequestObject;
begin
  try
    obj := TRequestObject.CreateFromJson(jsonStr);
    StartNewRequest;
    SetRequestObject(obj);
  except on E: Exception do
      ShowMessage(E.Message);
  end;
  obj.Free;
end;

procedure TMainForm.OnHttpException(Url, Method: string; E: Exception);
begin
  TimerRequest.Enabled := False;
  UpdateStatusLine;
  StatusTextInfo.Caption := '';
  // Is this a timeout exception ?
  if OptionsForm.Timeout = FRequestSeconds then
    ShowMessage('Request is timeout.')
  else
    ShowMessage(E.Message);
  btnSubmit.Enabled := True;
  btnBookmark.Enabled := True;
  FinishRequest;
end;

function TMainForm.ParseHeaderLine(line: string; delim: char = ':'; all: Boolean = False): TKeyValuePair;
var
  p: integer;
begin
  Result := SplitKV(line, delim);
  p := Pos(';', Result.Value);
  if (not all) and (p <> 0) then Result.Value := Trim(LeftStr(Result.Value, p - 1));
end;

procedure TMainForm.UpdateHeadersPickList;
begin
  with requestHeaders do begin
    HeadersEditorForm.FillHeaders(Columns.Items[1].PickList);
    if RowCount > 1 then
      Cells[0, 1] := '1';
  end;
end;

function TMainForm.EncodeFormData: string;
var
  i: integer;
  KV: TKeyValue;
begin
  Result := '';
  for i := 1 to gridForm.RowCount - 1 do
  begin
    if not IsRowEnabled(gridForm, i) then continue;
    KV := GetRowKV(gridForm, i);
    if KV.Key = '' then continue; // Skip empty names
    if Result <> '' then Result := Result + '&';
    Result := Result + EncodeURLElement(KV.Key) + '=' + EncodeURLElement(KV.Value);
  end;
end;

procedure TMainForm.OnRequestComplete(Info: TResponseInfo);
var
  i, p: integer;
  mime: TMimeType;
begin
  btnSubmit.Enabled := True;
  btnBookmark.Enabled := True;
  TimerRequest.Enabled := False;
  SetAppCaption(UrlPath(Info.Url));

  // Response headers.
  responseHeaders.RowCount := Info.ResponseHeaders.Count + 1;
  Info.ResponseHeaders.NameValueSeparator := ':';
  for i := 0 to Info.ResponseHeaders.Count - 1 do
  begin
    responseHeaders.Cells[0, i + 1] := Trim(Info.ResponseHeaders.Names[i]);
    responseHeaders.Cells[1, i + 1] := Trim(Info.ResponseHeaders.ValueFromIndex[i]);
  end;
  FContentType := Info.ContentType;

  textResp.Clear;
  Info.ServerLog(textResp.Lines);
  UpdateStatusLine(Info);

  if (Info.StatusCode <> 404) then
  begin
    p := cbUrl.Items.IndexOf(Info.Url);
    if p = -1 then begin // Add a new url.
      if cbUrl.Items.Count >= MAX_URLS then
        cbUrl.Items.Delete(cbUrl.Items.Count - 1);
      cbUrl.Items.Insert(0, Info.Url);
    end
    else // Move an existing url to the top of the list.
      cbUrl.Items.Move(p, 0);
    cbUrl.Text := Info.Url;
  end;

  // Fill response cookie grid or hide it.
  ShowResponseCookie(Info.ResponseHeaders);

  // Get the response content - enable menu item.
  miSaveResponse.Enabled := True;

  Info.Content.Position := 0;
  StatusTextInfo.Caption := '';
  responseRaw.Clear;
  mime := SplitMimeType(Info.ContentType);

  // Open a special content tab.
  try
    FResponseTabManager.OpenTabs(Info);
  except on E: ETabException do
    ERRMsg('Error', E.TabMessage);
  end;

  // Show/hide 'Content' response tab.
  if (mime.MimeType = 'text') or
       ((mime.MimeType = 'application') and (mime.Subtype <> 'octet-stream')) then
    tabContent.TabVisible := not (OptionsForm.HideTabContent and (FResponseTabManager.OpenedTabs.Count > 0))
  else
    tabContent.TabVisible := False;

  miFind.Enabled := True;
  miFindNext.Enabled := True;

  // Reset search: Find Next will search from the start or from the end of
  // the data with the parameters from the previous search (if it happened).
  FindStart(False);

  if tabContent.TabVisible then begin
    with responseRaw.Lines do begin
      BeginUpdate;
      try
        Add(Info.Content.DataString);
      finally
        EndUpdate;
      end;
    end;
    responseRaw.CaretPos := Point(0, 0);
  end;

  // Open the same tab as in the previous request (if it's possible).
  SwitchTabByName(pagesResponse, FKeepResponseTab);

  if not Assigned(FProfilerGraph) then
    FProfilerGraph := TProfilerGraph.Create(tabRespTime);
  FProfilerGraph.TimeCheckPoints := info.TimeCheckPoints;

  tbtnRespFollow.Visible := (Info.Location <> '');
  textResp.CaretPos := Point(0, 0);

  // Finally, dispose response info data.
  Info.Free;
  FinishRequest;
end;

procedure TMainForm.UpdateStatusLine(Main: string);
begin
  StatusTextMain.Caption  := IfThen(Main = '', ApplicationName, Main);
  StatusTextTime.Caption := '';
  StatusTextSize.Caption := '';
  StatusImageTime.Visible := False;
  StatusImageSize.Visible := False;
end;

procedure TMainForm.UpdateStatusLine(Info: TResponseInfo);
var
  w: Integer;
  tm: TTimeMSec;
begin
  StatusTextMain.Caption := Format('HTTP/%s %d %s', [Info.HttpVersion, Info.StatusCode, Info.StatusText]);

  StatusImageTime.Visible := True;
  StatusImageSize.Visible := True;

  tm := Info.RequestTime;

  StatusTextTime.Caption := IfThen(tm > 1000,
      Format('%d ms (%s)', [tm, FormatMsApprox(tm)]),
      Format('%d ms',      [tm]));

  StatusTextSize.Caption := NumberFormat(Info.Content.Size) + ' bytes';

  // Manual place components. Align property in the some cases can
  // lead to exchange of order of the image and text.
  w := StatusTextMain.Left + StatusTextMain.Width;

  // Place components in proper order.
  StatusImageTime.Left  := w + 16;
  StatusTextTime.Left   := StatusImageTime.Left + StatusImageTime.Width + 4;
  StatusTextTime.Height := StatusTextMain.Height;
  StatusImageSize.Left  := StatusTextTime.Left + StatusTextTime.Width + 8;
  StatusTextSize.Left   := StatusImageSize.Left + StatusImageSize.Width + 4;
  StatusTextSize.Height := StatusTextMain.Height;
end;

procedure TMainForm.ShowResponseCookie(Headers: TStrings);
var
  I, J, Row, Size: Integer;
  kv: TKeyValuePair;
  tokens: TStringList;
  tok: String;
begin
  Row := 1;
  tokens := TStringList.Create;
  tokens.Delimiter := ';';
  tokens.StrictDelimiter := True;

  try
    for I := 0 to Headers.Count - 1 do begin
      kv := ParseHeaderLine(Headers.Strings[I], ':', True);
      if LowerCase(kv.Key) = 'set-cookie' then begin
        gridRespCookie.RowCount := Row + 1;
        tokens.DelimitedText := kv.Value;
        Size := 0;
        // Reset grid.
        for J := 0 to gridRespCookie.ColCount - 1 do
          if (J = 6) or (J = 7) then
            gridRespCookie.Cells[J, Row] := '0'
          else
            gridRespCookie.Cells[J, Row] := '';
        // Fill grid.
        for J := 0 to tokens.Count - 1 do begin
          tok := Trim(tokens.Strings[J]);
          kv := ParseHeaderLine(tok, '=');
          // Cookie name and value
          if J = 0 then begin
            gridRespCookie.Cells[0, Row] := kv.Key;
            gridRespCookie.Cells[1, Row] := DecodeURL(kv.Value);
            Size := Length(kv.Value); // Cookie size
          end
          else
            case LowerCase(kv.Key) of
              'domain'  : gridRespCookie.Cells[2, Row] := kv.Value;
              'path'    : gridRespCookie.Cells[3, Row] := kv.Value;
              'expires' : gridRespCookie.Cells[4, Row] := kv.Value;
              'httponly': gridRespCookie.Cells[6, Row] := '1';
              'secure'  : gridRespCookie.Cells[7, Row] := '1';
              'samesite': gridRespCookie.Cells[8, Row] := kv.Value;
            end;
        end; // for
        // Cookie size
        gridRespCookie.Cells[5, Row] := IntToStr(Size);
        Inc(Row);
      end;
    end; // for
  finally
    FreeAndNil(tokens);
  end;

  if Row > 1 then tabRespCookie.TabVisible := True
    else tabRespCookie.TabVisible := False;
end;

function TMainForm.PromptNewRequest(const prompt: string; const promptTitle: string = 'New request'): Boolean;
var
  Need: Boolean = False;

  function IsEmpty(Grid: TStringGrid): Boolean;
  var
    I: Integer;
  begin
    for I := 1 to Grid.RowCount - 1 do
      if (Grid.Cells[1, I] <> '') or (Grid.Cells[2, I] <> '') then
        Exit(False);
    Result := True;
  end;

begin
  Need := Length(cbUrl.Text) > 0;
  if not Need then
    Need := not IsEmpty(requestHeaders);
  if not Need then
    Need := not IsEmpty(gridReqCookie);
  if not Need then
    Need := not IsEmpty(gridForm);
  if not Need then
    Need := not IsEmpty(gridParams);
  if not Need then
    Need := GetSelectedAuthTab <> atNone;
  if not Need then
    Need := Length(editOther.Text) > 0;
  if not Need then
    Need := Length(Trim(editJson.Text)) > 0;

  if Need and (ConfirmDlg(promptTitle, prompt) <> mrOK) then
    Exit(False); // =>
  Result := True;
end;

procedure TMainForm.StartNewRequest;
  procedure ResetGrid(grid: TStringGrid);
  begin
    grid.RowCount := 2;
    grid.Cells[0, 1] := '1';
    grid.Cells[1, 1] := '';
    grid.Cells[2, 1] := '';
  end;

begin
  // Request fields.
  cbUrl.Text     := '';
  cbMethod.Text  := 'GET';
  editOther.Text := '';
  editJson.Text  := '';
  editNotes.Text := '';
  ResetGrid(requestHeaders);
  ResetGrid(gridForm);
  ResetGrid(gridReqCookie);
  ResetGrid(gridParams);
  SelectBodyTab(btForm);

  // Response fields.
  responseHeaders.RowCount := 1;
  responseRaw.Text := '';
  textResp.Text := '';
  FContentType := '';
  tabContent.TabVisible := False;
  tabRespCookie.TabVisible := False;
  KeepCurrentResponseTab;
  pagesResponse.ActivePage := tabResponse;
  if Assigned(FProfilerGraph) then
    FreeAndNil(FProfilerGraph);

  // Menu items.
  miSaveResponse.Enabled := False;
  miFind.Enabled := False;
  miFindNext.Enabled := False;

  // Reset auth
  editBasicLogin.Text := '';
  editBasicPassword.Text := '';
  cbBasicShowPassword.Checked := False;
  editBearerPrefix.Text := 'Bearer';
  editBearerToken.Text := '';
  SelectAuthTab(atNone);

  FResponseTabManager.CloseTabs;
  SetAppCaption;
  UpdateStatusLine;

  // Submit and Bookmark buttons state.
  btnSubmit.Enabled := False;
  btnBookmark.Enabled := False;
  BookmarkButtonIcon(False);
  FBookManager.ResetCurrent;
end;

function TMainForm.SetJsonBody(jsonStr: string; var ErrMsg: string): Boolean;
var
  ss: TStringStream;
  parser: TJSONParser;
  data: TJSONData;
begin
  data := nil;
  Result := True;
  try
    ss := TStringStream.Create(jsonStr);
    Parser := TJSONParser.Create(ss);
    try
      Data := Parser.Parse;
      editJson.Text := FormatJson(Data);
    except
      on E: Exception do begin
        Result := False;
        ErrMsg := E.Message;
      end;
    end;
  finally
    FreeAndNil(ss);
    FreeAndNil(parser);
    FreeAndNil(data);
  end;
end;

// Get StringGrid instance from Popup sender.
// The sender can be a Popup menu or popup menu item.
// Returns nil when popup doesn't belongs to grid.
// Raises an exception when sender isn't popup or menu item.
function TMainForm.GetPopupSenderAsStringGrid(Sender: TObject): TStringGrid;
var
  Component: TComponent;
begin
  // What the sender is: popup or menu item ?
  if Sender is TMenuItem then
    Component := TPopupMenu(TMenuItem(Sender).GetParentMenu).PopupComponent
  else
    if Sender is TPopupMenu then
      Component := TPopupMenu(Sender).PopupComponent
  else
    raise Exception.Create('Sender is not Popup or MenuItem.');

  if Component is TStringGrid then
    Result := TStringGrid(Component)
  else if Component is TStringCellEditor then begin
    Component := TStringCellEditor(Component).Parent;
    if Component is TCompositeCellEditor then
      Result := TCompositeCellEditor(Component).Parent as TStringGrid
    else
      Result := Component as TStringGrid;
  end
  else if Component is TPickListCellEditor then begin
    Result := TPickListCellEditor(Component).Parent as TStringGrid;
  end
  else
    Result := nil;
end;

function TMainForm.EditGridRow(Grid: TStringGrid;
  const ValueFocused: Boolean): TModalResult;
var
  kv: TKeyValue;
  focus: Integer = FocusKey;
begin
  if ValueFocused then
    focus := FocusVal;
  with Grid do begin
    kv := KeyValueForm.Edit(GetRowKV(Grid), 'Edit...', focus);
    Result := KeyValueForm.ModalResult;
    if Result = mrOK then begin
      Cells[0, Row] := IfThen(kv.Enabled, '1', '0');
      Cells[1, Row] := kv.Key;
      Cells[2, Row] := kv.Value;
      // Force to update url after editing query params.
      if Grid = gridParams then
        SyncGridQueryParams;
    end;
  end;
end;

procedure TMainForm.SetAppCaption(const AValue: String);
begin
  Caption := ApplicationName;
  if AValue <> '' then Caption := Caption + ': ' + AValue;
end;

end.

