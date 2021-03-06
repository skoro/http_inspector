unit thread_http_client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, httpclient, fgl, UrlUtils;

type

  TTimeMSec = Int64;

  TTimeCheckPoint = record
    CheckPoint: Integer;
    Start: TDateTime;
    Finish: TDateTime;
    Duration: TTimeMSec;
  end;

  TTimeCheckPointList = specialize TFPGMap<string, TTimeCheckPoint>;

  { TTimeProfiler }

  TTimeProfiler = class
  private
    function GetCheckPoint(T: string): TTimeCheckPoint;
    function GetCheckPointByIndex(AIndex: Integer): TTimeCheckPoint;
  protected
    type
      TLabels = array of string;
    protected var
    FCheckPoints: TTimeCheckPointList;
    FCurrentPoint: Integer;
    function GetLabels: TLabels;
  public
    constructor Create; virtual;
    destructor Destory; virtual;
    procedure Reset;
    procedure Start(Timer: string);
    procedure Stop(Timer: string);
    property CheckPoint[T: string]: TTimeCheckPoint read GetCheckPoint;
    property Labels: TLabels read GetLabels;
    property CheckPoints: TTimeCheckPointList read FCheckPoints;
    property CheckPointIndex[AIndex: Integer]: TTimeCheckPoint read GetCheckPointByIndex;
  end;

  { TCustomHttpClient }

  TCustomHttpClient = class(TFPHTTPClient)
  private
    FTimeProfiler: TTimeProfiler;
    FSentCookies: TStrings; // Preserve sent cookies to use them in server log.
  protected
    procedure ConnectToServer(const AHost: String; APort: Integer; UseSSL : Boolean=False); override;
    procedure SendRequest(const AMethod: String; URI: TURI); override;
    function ReadResponseHeaders: integer; override;
    function ReadResponse(Stream: TStream;  const AllowedResponseCodes: array of Integer; HeadersOnly: Boolean = False): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CreateRequestLines(AMethod, AUrl: string): TStrings; virtual;
    procedure HTTPMethod(Const AMethod,AURL : String; Stream : TStream; Const AllowedResponseCodes : Array of Integer); override;
    procedure MultiFileStreamFormPost(FormData, FileNames: TStrings);
    property TimeProfiler: TTimeProfiler read FTimeProfiler;
  end;

  { TQueryParams }

  TQueryParams = specialize TFPGMap<string, string>;

  { TResponseInfo }

  TResponseInfo = class
  private
    FContent: TStringStream;
    FHttpVersion: string;
    FMethod: string;
    FRequestHeaders: TStrings;
    FResponseHeaders: TStrings;
    FStatusCode: Integer;
    FStatusText: string;
    FUrl: string;
    FTimeCheckPoints: TTimeCheckPointList;
    FRequestLines: TStrings;
    FServerHttpVersion: string;
    function GetContentType: string;
    function GetLocation: string;
    function GetRequestTime: TTimeMSec;
  public
    constructor Create;
    destructor Destroy; override;
    // Fill a buffer with request - response exchange with the server.
    // inStr  - a prefix for request headers.
    // outStr - a prefix for response headers.
    procedure ServerLog(Buffer: TStrings; inStr: string = '<'; outStr: string = '>');
    property StatusCode: Integer read FStatusCode write FStatusCode;
    property StatusText: string read FStatusText write FStatusText;
    property HttpVersion: string read FHttpVersion write FHttpVersion;
    property Url: string read FUrl write FUrl;
    property Method: string read FMethod write FMethod;
    // Original request headers. For additional headers that can be added
    // by the http client see RequestLines property.
    property RequestHeaders: TStrings read FRequestHeaders;
    property ResponseHeaders: TStrings read FResponseHeaders;
    property Content: TStringStream read FContent;
    property ContentType: string read GetContentType;
    property TimeCheckPoints: TTimeCheckPointList read FTimeCheckPoints;
    property RequestTime: TTimeMSec read GetRequestTime;
    property Location: string read GetLocation;
    // Request Lines are the lines that actually transmitted to the server.
    // These lines include the requested resource (the first lines) and
    // all the request headers.
    property RequestLines: TStrings read FRequestLines write FRequestLines;
    property ServerHttpVersion: string read FServerHttpVersion write FServerHttpVersion;
  end;

  TOnRequestComplete = procedure(ResponseInfo: TResponseInfo) of object;
  TOnException = procedure(Url, Method: string; E: Exception) of object;

  { TThreadHttpClient }

  TThreadHttpClient = class(TThread)
  private
    FHttpClient: TCustomHttpClient;
    FHttpMethod: string;
    FUrl: string;
    FOnRequestComplete: TOnRequestComplete;
    FResponseData: TStringStream;
    FOnClientException: TOnException;
    FException: Exception;
    FCookies: TStrings;
    function GetRequestBody: TStream;
    procedure SetHttpMethod(AValue: string);
    procedure SetRequestBody(AValue: TStream);
    procedure SetUrl(AValue: string);
    procedure RequestComplete;
    procedure OnClientException;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspened: boolean);
    destructor Destroy; override;
    procedure AddHeader(const AHeader, AValue: string);
    procedure AddCookie(const AName, AValue: string; EncodeValue: boolean = True);
    property Client: TCustomHttpClient read FHttpClient;
    property Method: string read FHttpMethod write SetHttpMethod;
    property Url: string read FUrl write SetUrl;
    property RequestBody: TStream read GetRequestBody write SetRequestBody;
    property OnRequestComplete: TOnRequestComplete
      read FOnRequestComplete write FOnRequestComplete;
    property OnException: TOnException read FOnClientException write FOnClientException;
  end;

  { TMimeType }

  TMimeType = record
    MimeType: string;
    Subtype: string;
  end;

function DecodeUrl(const url: string): string;
function GetURLQueryParams(const url: string): TQueryParams;
function ReplaceURLQueryParams(const url: string; Params: TQueryParams): string;
function SplitMimeType(const ContentType: string): TMimeType;

// Appends 'http:' proto to the url if it missing.
function NormalizeUrl(Url: string): string;

function ParseContentType(Headers: TStrings): string;

// Generate filename from the url and content type.
// If parameter 'DefExt' is empty then extension will be detected depending on
// the document.
function GetRequestFilename(Url: string; ContentType: string = ''; DefExt: string = ''): string;

// Returns the url without a query part.
function UrlPath(Url: string): string;

implementation

uses dateutils, strutils, RtlConsts, base64, ValEdit, app_helpers;

const
  CRLF = #13#10;

function DecodeUrl(const url: string): string;
begin
  Result := ReplaceStr(url, '+', ' ');
  Result := DecodeURLElement(Result);
end;

function GetURLQueryParams(const url: string): TQueryParams;
var
  URI: TURI;
  Params, KV: TStringList;
  I: integer;
  ParamStr: string;
begin
  Result := TQueryParams.Create;
  Params := TStringList.Create;
  KV := TStringList.Create;
  try
    URI := ParseURI(url);
    ParamStr := EscapeURI(URI.Params);
    SplitStrings(ParamStr, '&', Params);
    for I := 0 to Params.Count - 1 do
    begin
      SplitStrings(Params[I], '=', KV);
      case KV.Count of
        1: Result.Add(UnescapeURI(KV[0]), '');
        2: Result.Add(UnescapeURI(KV[0]), UnescapeURI(KV[1]));
      end;
    end;
  finally
    FreeAndNil(KV);
    FreeAndNil(Params);
  end;
end;

function ReplaceURLQueryParams(const url: string; Params: TQueryParams): string;
var
  URI: TURI;
  ParamStr, Key, Data: string;
  I: integer;
begin
  ParamStr := '';
  for I := 0 to Params.Count - 1 do
  begin
    Key := Trim(Params.Keys[I]);
    Data := Params.Data[I];
    if Key <> '' then
      ParamStr := ParamStr + IfThen(Data = '', Key, Format('%s=%s', [Key, Data])) + '&';
  end;
  ParamStr := TrimRightSet(ParamStr, ['&']);

  URI := ParseURI(url);
  URI.Params := ParamStr;
  Result := EncodeURI(URI, False);
end;

function SplitMimeType(const ContentType: string): TMimeType;
var
  P: Word;
begin
  Result.MimeType := '';
  Result.Subtype  := '';
  P := Pos('/', ContentType);
  if P = 0 then
    Exit;
  Result.MimeType := LowerCase(LeftStr(ContentType, P - 1));
  Result.Subtype  := LowerCase(RightStr(ContentType, Length(ContentType) - P));
end;

function NormalizeUrl(Url: string): string;
begin
  Result := Trim(Url);
  if Result = '' then
    raise Exception.Create('Url is empty');
  if not AnsiStartsText('http://', Url) then
    if not AnsiStartsText('https://', Url) then
      Result := 'http://' + Result;
end;

function ParseContentType(Headers: TStrings): string;
var
  I, P: integer;
  KV: TKeyValuePair;
begin
  Result := '';
  for I := 0 to Headers.Count - 1 do
  begin
    KV := SplitKV(Headers.Strings[I], ':');
    if LowerCase(KV.Key) = 'content-type' then begin
      Result := KV.Value;
      P := Pos(';', Result);
      if P <> 0 then // remove charset option.
        Result := Trim(LeftStr(Result, P - 1));
    end;
  end;
end;

function UrlPath(Url: string): string;
var
  uri: TURI;
begin
  if Url = '' then Exit('');
  uri := ParseURI(Url);
  Result := Format('%s://%s%s%s%s', [
    uri.Protocol,
    uri.Host,
    IfThen(uri.Port <> 0, ':' + IntToStr(uri.Port), ''),
    uri.Path,
    uri.Document
  ]);
end;

function GetRequestFilename(Url, ContentType: string; DefExt: string): string;
var
  uri: TURI;
  basename: string;
begin
  uri := ParseURI(NormalizeUrl(Url));
  if (ContentType <> '') and (DefExt = '') then begin
    DefExt := RightStr(ContentType, Length(ContentType) - Pos('/', ContentType));
    // Get extension name from strings like 'rss+xml', etc.
    DefExt := RightStr(DefExt, Length(DefExt) - Pos('+', DefExt));
  end;
  basename := TrimSet(uri.Document, ['/']);
  if basename = '' then
    basename := uri.Host;
  // Strip extension from a document name (mainly for images).
  if RightStr(basename, Length(DefExt) + 1) = '.' + DefExt then
    basename := LeftStr(basename, Length(basename) - Length(DefExt) - 1);
  // Don't append a content type extension to a jpeg image if the image
  // already contains the extension.
  if (ContentType = 'image/jpeg') and (RightStr(basename, 4) = '.jpg') then
    Exit(basename);
  Result := IfThen(DefExt <> '', Format('%s.%s', [basename, DefExt]), basename);
end;

{ TTimeProfiler }

function TTimeProfiler.GetCheckPoint(T: string): TTimeCheckPoint;
begin
  Result := FCheckPoints[T];
end;

function TTimeProfiler.GetCheckPointByIndex(AIndex: Integer): TTimeCheckPoint;
var
  I: Integer;
begin
  for I := 0 to FCheckPoints.Count - 1 do
    if FCheckPoints.Data[I].CheckPoint = AIndex then
      Exit(FCheckPoints.Data[I]);
  FCheckPoints.Error(SListIndexError, AIndex)
end;

function TTimeProfiler.GetLabels: TLabels;
var
  I: Integer;
begin
  SetLength(Result, FCheckPoints.Count);
  for I := 0 to FCheckPoints.Count - 1 do
    Result[I] := FCheckPoints.Keys[I];
end;

constructor TTimeProfiler.Create;
begin
  inherited;
  FCurrentPoint := 0;
  FCheckPoints := TTimeCheckPointList.Create;
end;

destructor TTimeProfiler.Destory;
begin
  FCheckPoints.Destroy;
  inherited;
end;

procedure TTimeProfiler.Reset;
begin
  FCurrentPoint := 0;
  FCheckPoints.Clear;
end;

procedure TTimeProfiler.Start(Timer: string);
var
  cp: TTimeCheckPoint;
begin
  cp.Start      := Now;
  cp.Finish     := 0;
  cp.CheckPoint := FCurrentPoint;
  cp.Duration   := 0;
  FCheckPoints.AddOrSetData(Timer, cp);
  Inc(FCurrentPoint);
end;

procedure TTimeProfiler.Stop(Timer: string);
var
  cp: TTimeCheckPoint;
begin
  cp := FCheckPoints.KeyData[Timer];
  cp.Finish := Now;
  cp.Duration := MilliSecondsBetween(cp.Finish, cp.Start);
  FCheckPoints.KeyData[Timer] := cp;
end;

{ TResponseInfo }

function TResponseInfo.GetLocation: string;
var
  I: Integer;
begin
  Result := '';
  if not ((FStatusCode >= 300) and (FStatusCode < 400)) then
    Exit; // =>
  for I := 0 to FResponseHeaders.Count - 1 do
    if LowerCase(FResponseHeaders.Names[I]) = 'location' then
      Exit(FResponseHeaders.ValueFromIndex[I]);
end;

function TResponseInfo.GetContentType: string;
begin
  Result := ParseContentType(FResponseHeaders);
end;

function TResponseInfo.GetRequestTime: TTimeMSec;
begin
  Result := FTimeCheckPoints.KeyData['Total'].Duration;
end;

constructor TResponseInfo.Create;
begin
  FContent := TStringStream.Create('');
  FRequestHeaders := TStringList.Create;
  FRequestHeaders.NameValueSeparator := ':';
  FResponseHeaders := TStringList.Create;
  FResponseHeaders.NameValueSeparator := ':';
  FTimeCheckPoints := TTimeCheckPointList.Create;
  FRequestLines := nil;
end;

destructor TResponseInfo.Destroy;
begin
  FreeAndNil(FContent);
  FreeAndNil(FRequestHeaders);
  FreeAndNil(FResponseHeaders);
  FreeAndNil(FTimeCheckPoints);
  if Assigned(FRequestLines) then
    FreeAndNil(FRequestLines);
  inherited Destroy;
end;

procedure TResponseInfo.ServerLog(Buffer: TStrings; inStr: string;
  outStr: string);
var
  I: Integer;
begin
  if Assigned(FRequestLines) then begin
    with FRequestLines do begin
      Buffer.Add('%s %s', [inStr, Strings[0]]);
      NameValueSeparator := ':';
      for I := 1 to Count - 1 do
        Buffer.Add('%s %s: %s', [inStr, Names[I], ValueFromIndex[I]]);
    end;
  end;
  Buffer.Add(inStr);
  Buffer.Add('%s HTTP/%s %d %s', [outStr, FServerHttpVersion, FStatusCode, FStatusText]);
  ResponseHeaders.NameValueSeparator := ':';
  with ResponseHeaders do
    for I := 0 to Count - 1 do
      Buffer.Add('%s %s: %s', [outStr, Names[I], ValueFromIndex[I]]);
end;

{ TCustomHttpClient }

procedure TCustomHttpClient.HTTPMethod(const AMethod, AURL: String;
  Stream: TStream; const AllowedResponseCodes: array of Integer);
begin
  FTimeProfiler.Reset;
  FTimeProfiler.Start('Total');
  inherited HTTPMethod(AMethod, AURL, Stream, AllowedResponseCodes);
  FTimeProfiler.Stop('Total');
end;

procedure TCustomHttpClient.ConnectToServer(const AHost: String;
  APort: Integer; UseSSL: Boolean);
begin
  FTimeProfiler.Start('Connect');
  inherited;
  FTimeProfiler.Stop('Connect');
end;

procedure TCustomHttpClient.SendRequest(const AMethod: String; URI: TURI);
begin
  FTimeProfiler.Start('Send request');
  FreeAndNil(FSentCookies);
  FSentCookies := Cookies;
  inherited SendRequest(AMethod, URI);
  FTimeProfiler.Stop('Send request');
end;

function TCustomHttpClient.ReadResponseHeaders: integer;
begin
  FTimeProfiler.Start('Response headers');
  Result := inherited ReadResponseHeaders;
  FTimeProfiler.Stop('Response headers');
end;

function TCustomHttpClient.ReadResponse(Stream: TStream;
  const AllowedResponseCodes: array of Integer; HeadersOnly: Boolean): Boolean;
begin
  FTimeProfiler.Start('Read response');
  Result := inherited ReadResponse(Stream, AllowedResponseCodes, HeadersOnly);
  FTimeProfiler.Stop('Read response');
end;

function TCustomHttpClient.CreateRequestLines(AMethod, AUrl: string): TStrings;
var
  UN,PW,S,L : String;
  I : Integer;
  Buf: TStrings;
  URI: TURI;
begin
  Buf := TStringList.Create;
  URI := ParseURI(AURL, False);
  S := Uppercase(AMethod)+' '+GetServerURL(URI)+' '+'HTTP/'+HTTPVersion;
  Buf.Add(S);
  UN := URI.Username;
  PW := URI.Password;
  if (UserName<>'') then
  begin
    UN := UserName;
    PW := Password;
  end;
  if (UN <> '') then
  begin
    S := 'Authorization: Basic ' + EncodeStringBase64(UN + ':' + PW);
    Buf.Add(S);
  end;
  S := 'Host: ' + URI.Host;
  If (URI.Port <> 0) then
    S:=S+':'+IntToStr(URI.Port);
  Buf.Add(S);
  For I:=0 to RequestHeaders.Count-1 do
  begin
    l := RequestHeaders[i];
    If AllowHeader(L) then
      Buf.Add(l);
  end;
  if Assigned(FSentCookies) then
  begin
    L := 'Cookie:';
    for I := 0 to FSentCookies.Count-1 do
    begin
      if ( I > 0 ) then
        L := L + '; ';
      L := L + FSentCookies[i];
    end;
    if AllowHeader(L) and (L <> 'Cookie:') then
      Buf.Add(L);
  end;
  Result := Buf;
end;

constructor TCustomHttpClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimeProfiler := TTimeProfiler.Create;
end;

destructor TCustomHttpClient.Destroy;
begin
  FTimeProfiler.Destory;
  inherited Destroy;
end;

procedure TCustomHttpClient.MultiFileStreamFormPost(FormData, FileNames: TStrings);
var
  N, V, S, Sep: string;
  SS: TStringStream;
  I: integer;
  FS: TFileStream;
begin
  Sep := Format('-----%.8x-%.8x_multipart_boundary', [Random($ffffff), Random($ffffff)]);
  AddHeader('Content-Type', 'multipart/form-data; boundary=' + Sep);
  SS := TStringStream.Create('');
  if (FormData <> nil) then
    for I := 0 to FormData.Count - 1 do
    begin
      FormData.GetNameValue(I, N, V);
      S := '--' + Sep + CRLF;
      S := S + Format('Content-Disposition: form-data; name="%s"' +
        CRLF + CRLF + '%s' + CRLF, [N, V]);
      SS.WriteBuffer(S[1], Length(S));
    end;
  for I := 0 to FileNames.Count - 1 do
  begin
    S := '--' + Sep + CRLF;
    FileNames.GetNameValue(I, N, V);
    S := S + Format('Content-Disposition: form-data; name="%s"; filename="%s"' + CRLF,
      [N, ExtractFileName(V)]);
    S := S + 'Content-Type: application/octet-string' + CRLF + CRLF;
    SS.WriteBuffer(S[1], Length(S));
    try
      FS := TFileStream.Create(V, fmOpenRead);
      FS.Seek(0, soFromBeginning);
      SS.CopyFrom(FS, FS.Size);
      FreeAndNil(FS);
    except
      on E: Exception do
      begin
        //FreeAndNil(FS);
        FreeAndNil(SS);
        raise Exception.Create('Couldn''t read file: ' + V);
      end;
    end;
  end;
  S := CRLF + '--' + Sep + '--' + CRLF;
  SS.WriteBuffer(S[1], Length(S));
  SS.Position := 0;
  RequestBody := SS;
  AddHeader('Content-Length', IntToStr(SS.Size));
end;

{ TThreadHttpClient }

function TThreadHttpClient.GetRequestBody: TStream;
begin
  Result := FHttpClient.RequestBody;
end;

procedure TThreadHttpClient.SetHttpMethod(AValue: string);
begin
  if FHttpMethod = AValue then
    Exit; // =>
  AValue := UpperCase(Trim(AValue));
  if Length(AValue) = 0 then
    AValue := 'GET'; // GET by default.
  FHttpMethod := AValue;
end;

procedure TThreadHttpClient.SetRequestBody(AValue: TStream);
begin
  FHttpClient.RequestBody := AValue;
end;

procedure TThreadHttpClient.SetUrl(AValue: string);
begin
  if FUrl = AValue then
    Exit; // =>
  // TODO: need better protocol parser.
  if Pos('http', AValue) = 0 then
    AValue := 'http://' + AValue;
  FUrl := EncodeUrl(AValue);
end;

procedure TThreadHttpClient.RequestComplete;
var
  info: TResponseInfo;
begin
  if Assigned(FOnRequestComplete) then
  begin
    info := TResponseInfo.Create;
    info.Method := FHttpMethod;
    info.Url := DecodeUrl(FUrl);
    info.RequestHeaders.Assign(FHttpClient.RequestHeaders);
    info.ResponseHeaders.Assign(FHttpClient.ResponseHeaders);
    info.StatusCode := FHttpClient.ResponseStatusCode;
    info.StatusText := FHttpClient.ResponseStatusText;
    info.HttpVersion := FHttpClient.ServerHTTPVersion;
    info.Content.WriteString(FResponseData.DataString);
    info.TimeCheckPoints.Assign(FHttpClient.TimeProfiler.CheckPoints);
    // HttpClient clears cookies after request.
    // For the server logs we need to restore them.
    if Assigned(FCookies) then
      FHttpClient.Cookies := FCookies;
    info.RequestLines := FHttpClient.CreateRequestLines(FHttpMethod, FUrl);
    info.ServerHttpVersion := FHttpClient.ServerHTTPVersion;
    FOnRequestComplete(info);
  end;
end;

procedure TThreadHttpClient.OnClientException;
begin
  if Assigned(FOnClientException) then
    FOnClientException(Url, Method, FException);
end;

procedure TThreadHttpClient.Execute;
begin
  try
    if Assigned(FCookies) then
      FHttpClient.Cookies := FCookies;
    FHttpClient.HTTPMethod(FHttpMethod, FUrl, FResponseData, []);
    Synchronize(@RequestComplete);
  except
    on E: Exception do
    begin
      FException := E;
      Synchronize(@OnClientException);
    end;
  end;
end;

constructor TThreadHttpClient.Create(CreateSuspened: boolean);
begin
  inherited Create(CreateSuspened);
  FreeOnTerminate := True;
  FHttpClient := TCustomHttpClient.Create(nil);
  FResponseData := TStringStream.Create('');
  FOnClientException := nil;
  FOnRequestComplete := nil;
  FCookies := nil;
end;

destructor TThreadHttpClient.Destroy;
begin
  if Assigned(FCookies) then
    FCookies.Free;
  FHttpClient.RequestBody.Free;
  FreeAndNil(FHttpClient);
  FreeAndNil(FResponseData);
  inherited Destroy;
end;

procedure TThreadHttpClient.AddHeader(const AHeader, AValue: string);
begin
  FHttpClient.AddHeader(AHeader, AValue);
end;

procedure TThreadHttpClient.AddCookie(const AName, AValue: string;
  EncodeValue: boolean = True);
begin
  if not Assigned(FCookies) then
    FCookies := TStringList.Create;
  FCookies.Add(Format('%s=%s',
    [AName, IfThen(EncodeValue, EncodeURLElement(AValue), AValue)]));
end;

end.
