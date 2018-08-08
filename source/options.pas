unit options;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, ExtCtrls, StdCtrls, JSONPropStorage, Spin, ComCtrls, fpjson,
  PairSplitter, Dialogs, Graphics, Controls, response_tabs, Classes, PropertyStorage;

type

  TUIFontItem = (fiGrids, fiEditor, fiJson, fiContent, fiValue);
  TFontItemList = array of TFont;

  { TOptionsPage }

  TOptionsPage = (opAppearance, opJson);

  { TOptionsForm }

  TOptionsForm = class(TForm)
    Button1: TButton;
    btnSelectFont: TButton;
    cbJsonExpanded: TCheckBox;
    cbJsonSaveFmt: TCheckBox;
    cbJsonFmtArray: TCheckBox;
    cbHideGridButtons: TCheckBox;
    cboxFontItem: TComboBox;
    editIndentSize: TSpinEdit;
    dlgFont: TFontDialog;
    GroupBox1: TGroupBox;
    gbLayout: TGroupBox;
    GroupBox2: TGroupBox;
    gbFonts: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    lFontDemo: TLabel;
    pagesOptions: TPageControl;
    Panel1: TPanel;
    Props: TJSONPropStorage;
    rbJsonTree: TRadioButton;
    rbJsonFormatted: TRadioButton;
    rbLayoutVert: TRadioButton;
    rbLayoutHor: TRadioButton;
    tabJson: TTabSheet;
    tabAppearance: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnSelectFontClick(Sender: TObject);
    procedure cboxFontItemChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FFontItemList: TFontItemList;
    function GetGridButtonsHidden: Boolean;
    function GetJsonFormatOptions: TFormatOptions;
    function GetJsonIndentSize: Integer;
    function GetJsonExpanded: Boolean;
    function GetJsonSaveFmt: Boolean;
    function GetJsonView: TViewPage;
    function GetPanelsLayout: TPairSplitterType;
    function GetFontIndexFromKeyName(AKeyName: string): integer;
    procedure SetFontDemo;
    procedure InitFonts;
    procedure OnPropsFontSave(Sender: TStoredValue; var Value: TStoredType);
    procedure OnPropsFontRestore(Sender: TStoredValue; var Value: TStoredType);

  public
    function ShowModalPage(page: TOptionsPage): TModalResult;
    function GetFontItem(AFontItem: TUIFontItem): TFont;
    procedure SetFontItem(AFontItem: TUIFontItem; AFont: TFont);
    procedure ApplyControlFont(const ParentControl: TWinControl; const AClassName: string; AFontItem: TUIFontItem);
    property JsonExpanded: Boolean read GetJsonExpanded;
    property JsonSaveFormatted: Boolean read GetJsonSaveFmt;
    property JsonIndentSize: Integer read GetJsonIndentSize;
    property JsonView: TViewPage read GetJsonView;
    property JsonFormat: TFormatOptions read GetJsonFormatOptions;
    property PanelsLayout: TPairSplitterType read GetPanelsLayout;
    property GridButtonsHidden: Boolean read GetGridButtonsHidden;
  end;

var
  OptionsForm: TOptionsForm;

implementation

uses app_helpers, SynEdit, fpjsonrtti;

{$R *.lfm}

{ TOptionsForm }

procedure TOptionsForm.FormCreate(Sender: TObject);
var
  CF: String;
  I: integer;
begin
  SetLength(FFontItemList, Ord(High(TUIFontItem)) + 1);
  InitFonts;

  CF := GetAppConfigDir(False) + DirectorySeparator + 'Options' + ConfigExtension;
  Props.JSONFileName := CF;

  // Save/restore fonts.
  for I := Ord(Low(TUIFontItem)) to Ord(High(TUIFontItem)) do
    with TStoredValue(Props.StoredValues.Add) do begin
      // Should be named like these. In save/restore index will be parsed.
      Name := 'Font_' + IntToStr(I);
      KeyString := 'Font_' + IntToStr(I);
      OnSave := @OnPropsFontSave;
      OnRestore := @OnPropsFontRestore;
    end;

  Props.Active := True;
  pagesOptions.ActivePage := tabAppearance;
end;

procedure TOptionsForm.FormShow(Sender: TObject);
begin
  SetFontDemo;
end;

function TOptionsForm.GetFontItem(AFontItem: TUIFontItem): TFont;
begin
  Result := FFontItemList[Ord(AFontItem)];
end;

procedure TOptionsForm.btnSelectFontClick(Sender: TObject);
var
  fdo: TFontDialogOptions;
begin
  // FIXME: fdFixedPitchOnly doesn't work on GTK widgetset ?
  fdo := dlgFont.Options;
  Exclude(fdo, fdFixedPitchOnly);
  if cboxFontItem.ItemIndex = Ord(fiEditor) then
    Include(fdo, fdFixedPitchOnly);
  dlgFont.Options := fdo;

  dlgFont.Font := FFontItemList[cboxFontItem.ItemIndex];
  if dlgFont.Execute then begin
    FFontItemList[cboxFontItem.ItemIndex].Assign(dlgFont.Font);
    SetFontDemo;
  end;
end;

procedure TOptionsForm.cboxFontItemChange(Sender: TObject);
begin
  SetFontDemo;
end;

function TOptionsForm.GetGridButtonsHidden: Boolean;
begin
  Result := cbHideGridButtons.Checked;
end;

function TOptionsForm.GetJsonFormatOptions: TFormatOptions;
begin
  Result := DefaultFormat;
  if cbJsonFmtArray.Checked then
    Result := Result + [foSingleLineArray];
end;

function TOptionsForm.GetJsonIndentSize: Integer;
begin
  Result := editIndentSize.Value;
end;

function TOptionsForm.GetJsonExpanded: Boolean;
begin
  Result := cbJsonExpanded.Checked;
end;

function TOptionsForm.GetJsonSaveFmt: Boolean;
begin
  Result := cbJsonSaveFmt.Checked;
end;

function TOptionsForm.GetJsonView: TViewPage;
begin
  if rbJsonTree.Checked then
    Result := vpTree
  else if rbJsonFormatted.Checked then
    Result := vpFormatted;
end;

function TOptionsForm.GetPanelsLayout: TPairSplitterType;
begin
  if rbLayoutHor.Checked then
    Result := pstHorizontal
  else
    Result := pstVertical;
end;

function TOptionsForm.GetFontIndexFromKeyName(AKeyName: string): integer;
begin
  Result := StrToInt(StringReplace(AKeyName, 'Font_', '', []));
end;

procedure TOptionsForm.SetFontDemo;
var
  FontObj: TFont;
  StyleName: string;
begin
  FontObj := FFontItemList[cboxFontItem.ItemIndex];
  // Don't show LCL default font parameters: it's not actual.
  if FontObj.Name = 'default' then begin
    lFontDemo.Caption := '';
    Exit;
  end;
  StyleName := 'Regular';
  if FontObj.Bold then StyleName := 'Bold';
  if FontObj.Italic then StyleName := StyleName + ' Italic';
  if FontObj.Underline then StyleName := StyleName + 'Underline';
  if FontObj.StrikeThrough then StyleName := StyleName + 'StrikeThrough';
  lFontDemo.Font := FontObj;
  lFontDemo.Caption := Format('%s %d %s', [
    FontObj.Name, FontObj.Size, StyleName
  ]);
end;

procedure TOptionsForm.SetFontItem(AFontItem: TUIFontItem; AFont: TFont);
begin
  if FFontItemList[Ord(AFontItem)] <> AFont then
    FFontItemList[Ord(AFontItem)] := AFont;
end;

procedure TOptionsForm.ApplyControlFont(const ParentControl: TWinControl;
  const AClassName: string; AFontItem: TUIFontItem);
var
  ChildControls: TList;
  I: Integer;
begin
  ChildControls := TList.Create;
  try
    EnumControls(ParentControl, AClassName, ChildControls);
    if ChildControls.Count > 0 then
      for I := 0 to ChildControls.Count - 1 do
        TWinControl(ChildControls[I]).Font := GetFontItem(AFontItem);
  finally
    ChildControls.Free;
  end;
end;

procedure TOptionsForm.InitFonts;
var
  EditorFont: TFont;
begin
  FFontItemList[Ord(fiGrids)]   := TFont.Create;
  FFontItemList[Ord(fiJson)]    := TFont.Create;
  FFontItemList[Ord(fiContent)] := TFont.Create;
  FFontItemList[Ord(fiValue)]   := TFont.Create;

  // Editor needs a monospaced font.
  EditorFont := TFont.Create;
  with EditorFont do begin
    Name    := SynDefaultFontName;
    Height  := SynDefaultFontHeight;
    Pitch   := SynDefaultFontPitch;
    Quality := SynDefaultFontQuality;
  end;
  FFontItemList[Ord(fiEditor)] := EditorFont;

  cboxFontItem.Items.AddStrings([
    'Grids', 'Editor', 'Json tree', 'Response content', 'Value editor'
  ]);
  cboxFontItem.ItemIndex := 0;
end;

procedure TOptionsForm.OnPropsFontSave(Sender: TStoredValue;
  var Value: TStoredType);
var
  jStr: TJSONStreamer;
  Idx: integer;
begin
  jStr := TJSONStreamer.Create(nil);
  try
    Idx := GetFontIndexFromKeyName(Sender.KeyString);
    Value := jStr.ObjectToJSONString(FFontItemList[Idx]);
  finally
    jStr.Free;
  end;
end;

procedure TOptionsForm.OnPropsFontRestore(Sender: TStoredValue;
  var Value: TStoredType);
var
  jStr: TJSONDeStreamer;
  Idx: integer;
begin
  if Length(Trim(Value)) = 0 then
    Exit;
  jStr := TJSONDeStreamer.Create(nil);
  try
    Idx := GetFontIndexFromKeyName(Sender.KeyString);
    jStr.JSONToObject(Value, FFontItemList[Idx]);
  finally
    jStr.Free;
  end;
end;

function TOptionsForm.ShowModalPage(page: TOptionsPage): TModalResult;
begin
  case page of
    opAppearance: pagesOptions.ActivePage := tabAppearance;
    opJson:       pagesOptions.ActivePage := tabJson;
  end;
  Result := ShowModal;
end;

end.

