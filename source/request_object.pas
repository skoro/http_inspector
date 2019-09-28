unit request_object;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Grids, thread_http_client;

type

  TBodyTab = (btForm, btJson, btOther);
  TAuthTab = (atNone = -1, atBasic, atBearer);

  { TRequestParamItem }

  TRequestParamItem = class(TCollectionItem)
  private
    FEnabled: boolean;
    FName: string;
    FValue: string;
  protected
  public
    procedure CopyFrom(Src: TRequestParamItem);
  published
    property Enabled: boolean read FEnabled write FEnabled;
    property Name: string read FName write FName;
    property Value: string read FValue write FValue;
  end;

  { TRequestParamsEnumerator }

  TRequestParamsEnumerator = class(TCollectionEnumerator)
  public
    function GetCurrent: TRequestParamItem;
    property Current: TRequestParamItem read GetCurrent;
  end;

  { TRequestParamList }

  TRequestParamList = class(TCollection)
  private
    function GetItems(Index: integer): TRequestParamItem;
    procedure SetItems(Index: integer; AValue: TRequestParamItem);
  public
    constructor Create;
    procedure CopyFrom(Src: TRequestParamList);
    function Add: TRequestParamItem;
    function GetEnumerator: TRequestParamsEnumerator;
    property Items[Index: integer]: TRequestParamItem read GetItems write SetItems; default;
  end;

  { TFormTypeItem }

  TFormTypeItem = (ftiText, ftiFile);

  { TFormParamItem }

  TFormParamItem = class(TRequestParamItem)
  private
    FElemType: TFormTypeItem;
  public
    procedure CopyFrom(Src: TFormParamItem);
  published
    property ElemType: TFormTypeItem read FElemType write FElemType;
  end;

  { TFormParamsEnumerator }

  TFormParamsEnumerator = class(TCollectionEnumerator)
  public
    function GetCurrent: TFormParamItem;
    property Current: TFormParamItem read GetCurrent;
  end;

  { TFormParamList }

  TFormParamList = class(TCollection)
  private
    function GetItems(Index: integer): TFormParamItem;
    procedure SetItems(Index: integer; AValue: TFormParamItem);
  public
    constructor Create;
    procedure CopyFrom(Src: TFormParamList);
    function GetEnumerator: TFormParamsEnumerator;
    function Add: TFormParamItem;
    property Items[Index: integer]: TFormParamItem read GetItems write SetItems;
  end;

  { TAuthBasic }

  TAuthBasic = class
  private
    FLogin: string;
    FPassword: string;
  public
    procedure CopyFrom(Src: TAuthBasic);
  published
    property Login: string read FLogin write FLogin;
    property Password: string read FPassword write FPassword;
  end;

  { TAuthBearer }

  TAuthBearer = class
  private
    FPrefix: string;
    FToken: string;
  public
    constructor Create;
    procedure CopyFrom(Src: TAuthBearer);
  published
    property Prefix: string read FPrefix write FPrefix;
    property Token: string read FToken write FToken;
  end;

  { TRequestObject }

  TRequestObject = class(TPersistent)
  private
    FMethod: string;
    FUrl: string;
    FBody: string;
    FJson: string;
    FHeaders: TRequestParamList;
    FCookies: TRequestParamList;
    FParams: TRequestParamList; // GET params
    FForm: TFormParamList;
    FAuthBasic: TAuthBasic;
    FAuthBearer: TAuthBearer;
    FAuthType: TAuthTab; // TODO: should be TAuthType
    FDataType: TBodyTab;
    FNotes: string;
    FResponseInfo: TResponseInfo;
    function GetFilename: string;
    function GetUrlPath: string;
    procedure SetMethod(AValue: string);
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure CopyFrom(Src: TRequestObject);
    procedure SetCollectionFromGrid(Grid: TStringGrid; coll: TCollection);
    procedure SetCollectionToGrid(coll: TCollection; Grid: TStringGrid);
    procedure SetFormToGrid(FormGrid: TStringGrid);
    procedure GetFormFromGrid(FormGrid: TStringGrid);
    procedure AddHeader(AName, AValue: string; IsEnabled: Boolean = True);
    procedure AddCookie(AName, AValue: string; IsEnabled: Boolean = True);
    procedure AddForm(AName, AValue: string; IsEnabled: Boolean = True;
      AElemType: TFormTypeItem = ftiText);
    function IsJson: Boolean;
    // Serialize to a json string.
    function ToJson: string;
    // Unserialize from a json string.
    class function CreateFromJson(json: string): TRequestObject;
    property ResponseInfo: TResponseInfo read FResponseInfo write FResponseInfo;
  published
    property Method: string read FMethod write SetMethod;
    property Url: string read FUrl write FUrl;
    property UrlPath: string read GetUrlPath;
    property Body: string read FBody write FBody;
    property Json: string read FJson write FJson;
    property Headers: TRequestParamList read FHeaders;
    property Form: TFormParamList read FForm;
    property Cookies: TRequestParamList read FCookies;
    property Params: TRequestParamList read FParams;
    property AuthType: TAuthTab read FAuthType write FAuthType;
    property AuthBasic: TAuthBasic read FAuthBasic write FAuthBasic;
    property AuthBearer: TAuthBearer read FAuthBearer write FAuthBearer;
    property DataType: TBodyTab read FDataType write FDataType;
    property Filename: string read GetFilename;
    property Notes: string read FNotes write FNotes;
  end;

implementation

uses strutils, URIParser, fpjsonrtti;

{ TFormParamItem }

procedure TFormParamItem.CopyFrom(Src: TFormParamItem);
begin
  inherited CopyFrom(Src);
  ElemType := Src.ElemType;
end;

{ TRequestParamItem }

procedure TRequestParamItem.CopyFrom(Src: TRequestParamItem);
begin
  Enabled := Src.Enabled;
  Name := Src.Name;
  Value := Src.Value;
end;

{ TAuthBasic }

procedure TAuthBasic.CopyFrom(Src: TAuthBasic);
begin
  FLogin := Src.Login;
  FPassword := Src.Password;
end;

{ TFormParamsEnumerator }

function TFormParamsEnumerator.GetCurrent: TFormParamItem;
begin
  Result := inherited GetCurrent as TFormParamItem;
end;

{ TRequestParamsEnumerator }

function TRequestParamsEnumerator.GetCurrent: TRequestParamItem;
begin
  Result := inherited GetCurrent as TRequestParamItem;
end;

{ TAuthBearer }

constructor TAuthBearer.Create;
begin
  FPrefix := 'Bearer';
end;

procedure TAuthBearer.CopyFrom(Src: TAuthBearer);
begin
  FPrefix := Src.Prefix;
  FToken := Src.Token;
end;

{ TFormParamList }

function TFormParamList.GetItems(Index: integer): TFormParamItem;
begin
  Result := TFormParamItem(inherited Items[Index]);
end;

procedure TFormParamList.SetItems(Index: integer; AValue: TFormParamItem);
begin
  Items[Index].Assign(AValue);
end;

constructor TFormParamList.Create;
begin
  inherited Create(TFormParamItem);
end;

procedure TFormParamList.CopyFrom(Src: TFormParamList);
var
  fpi: TFormParamItem;
begin
  Clear;
  for fpi in Src do
    with Add do
      CopyFrom(fpi);
end;

function TFormParamList.GetEnumerator: TFormParamsEnumerator;
begin
  Result := TFormParamsEnumerator.Create(Self);
end;

function TFormParamList.Add: TFormParamItem;
begin
  Result := inherited Add as TFormParamItem;
end;

{ TRequestParamList }

function TRequestParamList.GetItems(Index: integer): TRequestParamItem;
begin
  Result := TRequestParamItem(inherited Items[Index]);
end;

procedure TRequestParamList.SetItems(Index: integer; AValue: TRequestParamItem);
begin
  Items[Index].Assign(AValue);
end;

constructor TRequestParamList.Create;
begin
  inherited Create(TRequestParamItem);
end;

procedure TRequestParamList.CopyFrom(Src: TRequestParamList);
var
  rpi: TRequestParamItem;
begin
  Clear;
  for rpi in Src do
    with Add do
      CopyFrom(rpi);
end;

function TRequestParamList.Add: TRequestParamItem;
begin
  Result := inherited Add as TRequestParamItem;
end;

function TRequestParamList.GetEnumerator: TRequestParamsEnumerator;
begin
  Result := TRequestParamsEnumerator.Create(Self);
end;

{ TRequestParamItem }

{ TRequestObject }

procedure TRequestObject.SetCollectionFromGrid(Grid: TStringGrid;
  coll: TCollection);
var
  I: Integer;
  name: string;
  item: TRequestParamItem;
begin
  for I := 1 to grid.RowCount - 1 do begin
    name := trim(grid.Cells[1, I]);
    if name = '' then continue;
    item := TRequestParamItem(coll.Add);
    item.Enabled := grid.cells[0, i] = '1';
    item.Name := grid.cells[1, i];
    item.Value := grid.cells[2, i];
  end;
end;

procedure TRequestObject.SetMethod(AValue: string);
begin
  if FMethod = AValue then
    Exit;
  FMethod := UpperCase(AValue);
end;

function TRequestObject.GetFilename: string;
var
  U: TURI;
begin
  U := ParseURI(FUrl);
  Result := TrimSet(U.Document, ['/']);
  if Result = '' then
    Result := U.Host;
end;

function TRequestObject.GetUrlPath: string;
begin
  Result := thread_http_client.UrlPath(FUrl);
end;

constructor TRequestObject.Create;
begin
  inherited Create;
  FHeaders    := TRequestParamList.Create;
  FCookies    := TRequestParamList.Create;
  FParams     := TRequestParamList.Create;
  FForm       := TFormParamList.Create;
  FAuthType   := atNone;
  FAuthBasic  := TAuthBasic.Create;
  FAuthBearer := TAuthBearer.Create;
  FMethod     := 'GET';
  FNotes      := '';
  FResponseInfo := nil;
end;

destructor TRequestObject.Destroy;
begin
  FHeaders.Free;
  FForm.Free;
  FCookies.Free;
  FParams.Free;
  FAuthBasic.Free;
  FAuthBearer.Free;
  // Please notice, there is no free for ResponseInfo. It should be
  // freed manual.
  inherited Destroy;
end;

procedure TRequestObject.CopyFrom(Src: TRequestObject);
begin
  FMethod := Src.Method;
  FUrl := Src.Url;
  FBody := Src.Body;
  FJson := Src.Json;
  FHeaders.CopyFrom(Src.Headers);
  FCookies.CopyFrom(Src.Cookies);
  FParams.CopyFrom(Src.Params);
  FForm.CopyFrom(Src.Form);
  FAuthBasic.CopyFrom(Src.AuthBasic);
  FAuthBearer.CopyFrom(Src.AuthBearer);
  FAuthType := Src.AuthType;
  FDataType := Src.DataType;
  FNotes := Src.Notes;
end;

procedure TRequestObject.SetCollectionToGrid(coll: TCollection;
  Grid: TStringGrid);
var
  item: TRequestParamItem;
  I: Integer;
begin
  Grid.RowCount := coll.Count + 1;
  for I := 0 to coll.Count - 1 do begin
    item := TRequestParamItem(coll.Items[I]);
    Grid.Cells[0, I + 1] := IfThen(item.Enabled, '1', '0');
    Grid.Cells[1, I + 1] := item.Name;
    Grid.Cells[2, I + 1] := item.Value;
  end;
end;

procedure TRequestObject.GetFormFromGrid(FormGrid: TStringGrid);
var
  Item: TFormParamItem;
  I: Integer;
  Name: String;
begin
  for I := 1 to FormGrid.RowCount - 1 do begin
    Name := Trim(FormGrid.Cells[1, I]);
    if Name = '' then
      Continue;
    Item := TFormParamItem(FForm.Add);
    Item.Enabled  := FormGrid.Cells[0, I] = '1';
    Item.Name     := FormGrid.Cells[1, I];
    Item.Value    := FormGrid.Cells[2, I];
    if FormGrid.Cells[3, I] = 'File' then
      Item.ElemType := ftiFile
    else
      Item.ElemType := ftiText;
  end;
end;

procedure TRequestObject.SetFormToGrid(FormGrid: TStringGrid);
var
  Item: TFormParamItem;
  I: Integer;
begin
  FormGrid.RowCount := FForm.Count + 1;
  for I := 0 to FForm.Count - 1 do begin
    Item := TFormParamItem(FForm.Items[I]);
    FormGrid.Cells[0, I + 1] := IfThen(Item.Enabled, '1', '0');
    FormGrid.Cells[1, I + 1] := Item.Name;
    FormGrid.Cells[2, I + 1] := Item.Value;
    case Item.ElemType of
      ftiText: FormGrid.Cells[3, I + 1] := '';
      ftiFile: FormGrid.Cells[3, I + 1] := 'File';
    end;
  end;
end;

procedure TRequestObject.AddHeader(AName, AValue: string; IsEnabled: Boolean);
var
  Tokens: TStringArray;
begin
  // Parse Authorization header and set appropriate request object's auth type.
  if LowerCase(AName) = 'authorization' then begin
    Tokens := AValue.Split([' '], TStringSplitOptions.ExcludeEmpty);
    if (Length(Tokens) = 2) and (Tokens[0] = FAuthBearer.Prefix) then
    begin
      if Tokens[1] = 'null' then // Don't set null token.
        Exit; // =>
      AuthBearer.Token := Tokens[1];
      AuthType := atBearer;
      // Don't add that as header it will be contained in auth object.
      Exit; // =>
    end;
  end;
  with Headers.Add do begin
    Enabled := IsEnabled;
    Name := AName;
    Value := AValue;
  end;
end;

procedure TRequestObject.AddCookie(AName, AValue: string; IsEnabled: Boolean);
begin
  with Cookies.Add do begin
    Enabled := IsEnabled;
    Name := AName;
    Value := AValue;
  end;
end;

procedure TRequestObject.AddForm(AName, AValue: string; IsEnabled: Boolean;
  AElemType: TFormTypeItem);
begin
  with Form.Add do begin
    Enabled := IsEnabled;
    Name := AName;
    Value := AValue;
    ElemType := AElemType;
  end;
end;

function TRequestObject.IsJson: Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to FHeaders.Count - 1 do
    if (LowerCase(FHeaders[i].Name) = 'content-type')
       and (AnsiStartsText('application/json', FHeaders[i].Value)) then
      Exit(True);
end;

function TRequestObject.ToJson: string;
var
  streamer: TJSONStreamer;
begin
  Result := '';
  streamer := TJSONStreamer.Create(Nil);
  try
    Result := streamer.ObjectToJSONString(Self);
  finally
    streamer.Free;
  end;
end;

class function TRequestObject.CreateFromJson(json: string): TRequestObject;
var
  streamer: TJSONDeStreamer;
begin
  streamer := TJSONDeStreamer.Create(nil);
  try
    Result := TRequestObject.Create;
    streamer.JSONToObject(json, Result);
  finally
    streamer.Free;
  end;
end;

end.

