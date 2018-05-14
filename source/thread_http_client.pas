unit thread_http_client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fgl;

type

  { TQueryParams }

  TQueryParams = specialize TFPGMap<string, string>;

  { TRequestInfo }

  TResponseInfo = record
    StatusCode: integer;
    StatusText: string;
    HttpVersion: string;
    Url: string;
    Method: string;
    RequestHeaders: TStrings;
    ResponseHeaders: TStrings;
    Content: TStringStream;
    Time: Int64; // time of request execution in milliseconds
  end;

  TOnRequestComplete = procedure (ResponseInfo: TResponseInfo) of object;
  TOnException = procedure (Url, Method: string; E: Exception) of object;

  { TThreadHttpClient }

  TThreadHttpClient = class(TThread)
  private
    FHttpClient: TFPHTTPClient;
    FHttpMethod: string;
    FUrl: string;
    FOnRequestComplete: TOnRequestComplete;
    FResponseData: TStringStream;
    FOnClientException: TOnException;
    FException: Exception;
    FStartTime: TDateTime;
    FFinishTime: TDateTime;
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
    constructor Create(CreateSuspened: Boolean);
    destructor Destroy; override;
    procedure AddHeader(const AHeader,AValue : String);
    procedure AddCookie(const AName, AValue : String; EncodeValue: Boolean = True);
    property Client: TFPHTTPClient read FHttpClient;
    property Method: string read FHttpMethod write SetHttpMethod;
    property Url: string read FUrl write SetUrl;
    property RequestBody: TStream read GetRequestBody write SetRequestBody;
    property OnRequestComplete: TOnRequestComplete read FOnRequestComplete write FOnRequestComplete;
    property OnException: TOnException read FOnClientException write FOnClientException;
  end;

  function DecodeUrl(const url: string): string;
  function GetURLQueryParams(const url: string): TQueryParams;
  function ReplaceURLQueryParams(const url: string; Params: TQueryParams): string;

implementation

uses dateutils, strutils, URIParser, app_helpers;

function DecodeUrl(const url: string): string;
begin
  Result := ReplaceStr(url, '+', ' ');
  Result := DecodeURLElement(Result);
end;

function GetURLQueryParams(const url: string): TQueryParams;
var
  URI: TURI;
  Params, KV: TStringList;
  I: Integer;
begin
  Result := TQueryParams.Create;
  Params := TStringList.Create;
  KV := TStringList.Create;
  try
    URI := ParseURI(url);
    SplitStrings(URI.Params, '&', Params);
    for I := 0 to Params.Count - 1 do begin
      SplitStrings(Params[I], '=', KV);
      case KV.Count of
        1: Result.Add(DecodeURLElement(KV[0]), '');
        // Fix: DecodeURLElement on empty string leads to use the value from the previous iteration.
        2: Result.Add(DecodeURLElement(KV[0]), IfThen(KV[1] = '', '', DecodeURLElement(KV[1])));
      end;
    end;
  finally
    KV.Free;
    Params.Free;
  end;
end;

function ReplaceURLQueryParams(const url: string; Params: TQueryParams): string;
var
  URI: TURI;
  ParamStr, Key, Data: string;
  I: integer;
begin
  ParamStr:='';
  for I:=0 to Params.Count-1 do begin
    Key:=Trim(Params.Keys[I]);
    Data:=Params.Data[I];
    if Key <> '' then
      ParamStr:=ParamStr + IfThen(Data = '', Key, Format('%s=%s', [Key, Data])) + '&';
  end;
  ParamStr:=TrimRightSet(ParamStr, ['&']);

  URI:=ParseURI(url);
  URI.Params:=ParamStr;
  Result:=EncodeURI(URI);
end;

{ TThreadHttpClient }

function TThreadHttpClient.GetRequestBody: TStream;
begin
  Result := FHttpClient.RequestBody;
end;

procedure TThreadHttpClient.SetHttpMethod(AValue: string);
begin
  if FHttpMethod = AValue then Exit; // =>
  AValue := UpperCase(Trim(AValue));
  if Length(AValue) = 0 then AValue := 'GET'; // GET by default.
  FHttpMethod := AValue;
end;

procedure TThreadHttpClient.SetRequestBody(AValue: TStream);
begin
  FHttpClient.RequestBody := AValue;
end;

procedure TThreadHttpClient.SetUrl(AValue: string);
begin
  if FUrl = AValue then Exit; // =>
  // TODO: need better protocol parser.
  if Pos('http', AValue) = 0 then AValue := 'http://' + AValue;
  FUrl := AValue;
end;

procedure TThreadHttpClient.RequestComplete;
var
  info: TResponseInfo;
begin
  if Assigned(FOnRequestComplete) then
  begin
    info.Method:=FHttpMethod;
    info.Url:=FUrl;
    info.RequestHeaders:=FHttpClient.RequestHeaders;
    info.ResponseHeaders:=FHttpClient.ResponseHeaders;
    info.StatusCode:=FHttpClient.ResponseStatusCode;
    info.StatusText:=FHttpClient.ResponseStatusText;
    info.HttpVersion:=FHttpClient.ServerHTTPVersion;
    info.Content:=FResponseData;
    info.Time:=MilliSecondsBetween(FFinishTime, FStartTime);
    FOnRequestComplete(info);
  end;
end;

procedure TThreadHttpClient.OnClientException;
begin
  if Assigned(FOnClientException) then FOnClientException(Url, Method, FException);
end;

procedure TThreadHttpClient.Execute;
begin
  try
    if Assigned(FCookies) then FHttpClient.Cookies := FCookies;
    FStartTime := Now;
    FHttpClient.HTTPMethod(FHttpMethod, FUrl, FResponseData, []);
    FFinishTime := Now;
    Synchronize(@RequestComplete);
  except
    on E: Exception do
    begin
      FException := E;
      Synchronize(@OnClientException);
    end;
  end;
end;

constructor TThreadHttpClient.Create(CreateSuspened: Boolean);
begin
  inherited Create(CreateSuspened);
  FreeOnTerminate := True;
  FHttpClient := TFPHTTPClient.Create(nil);
  FResponseData := TStringStream.Create('');
  FOnClientException:=nil;
  FOnRequestComplete:=nil;
  FCookies:=nil;
end;

destructor TThreadHttpClient.Destroy;
begin
  if Assigned(FCookies) then FCookies.Free;
  FHttpClient.RequestBody.Free;
  FreeAndNil(FHttpClient);
  FreeAndNil(FResponseData);
  inherited Destroy;
end;

procedure TThreadHttpClient.AddHeader(const AHeader, AValue: String);
begin
  FHttpClient.AddHeader(AHeader, AValue);
end;

procedure TThreadHttpClient.AddCookie(const AName, AValue: String; EncodeValue: Boolean = True);
begin
  if not Assigned(FCookies) then FCookies := TStringList.Create;
  FCookies.Add(Format('%s=%s', [
    AName, IfThen(EncodeValue, EncodeURLElement(AValue), AValue)
  ]));
end;

end.

