unit HttpsConnection;

interface

uses
  Classes, IdHTTP, IdSSLOpenSSL, IdAuthentication, IdHeaderList;

{$DEFINE USE_EXT_PROXY_AUTH}
{-$DEFINE DEBUG_SAVE_LOG}

type
//------------------------------------------------------------------------------
  THttpsConnection = class
  private
    FInitialized: Boolean;
    FIdHttp: TIdHTTP;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    FProxyUsername: string;
    FProxyPassword: string;
    function getConnectTimeout: Integer;
    function getReadTimeout: Integer;
    procedure setConnectTimeout(const Value: Integer);
    procedure setReadTimeout(const Value: Integer);
    function getProxyPort: Integer;
    function getProxyServer: string;
    procedure setProxyServer(const Value: string);
    procedure setProxyPort(const Value: Integer);
    function getHttpAccept: string;
    function getHttpAcceptCharSet: string;
    function getHttpAcceptEncoding: string;
    function getHttpAcceptLanguage: string;
    function getHttpCacheControl: string;
    function getHttpConnection: string;
    function getHttpContentEncoding: string;
    function getHttpPragma: string;
    function getHttpUserAgent: string;
    procedure setHttpAccept(const Value: string);
    procedure setHttpAcceptCharSet(const Value: string);
    procedure setHttpAcceptEncoding(const Value: string);
    procedure setHttpAcceptLanguage(const Value: string);
    procedure setHttpCacheControl(const Value: string);
    procedure setHttpConnection(const Value: string);
    procedure setHttpContentEncoding(const Value: string);
    procedure setHttpPragma(const Value: string);
    procedure setHttpUserAgent(const Value: string);
    function getHttpContentType: string;
    procedure setHttpContentType(const Value: string);
  protected
    procedure OnSelectProxyAuthorization(ASender: TObject;
      var AAuthenticationClass: TIdAuthenticationClass; AAuthInfo: TIdHeaderList);
    procedure OnProxyAuthorization(ASender: TObject;
      AAuthentication: TIdAuthentication; var AHandled: Boolean);
    procedure SaveDebugData(AStream: TStream; AMessage, AFileName: string);
    procedure OnSelectAuthorization(ASender: TObject; var AAuthenticationClass: TIdAuthenticationClass; AAuthInfo: TIdHeaderList);
    procedure OnAuthorization(ASender: TObject; AAuthentication: TIdAuthentication; var AHandled: Boolean);
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Initialize();
    procedure Post(AURL: string; ARequest, AResponse: TStream); overload;
    property ReadTimeout: Integer read getReadTimeout write setReadTimeout;
    property ConnectTimeout: Integer read getConnectTimeout write setConnectTimeout;
    property ProxyServer: string read getProxyServer write setProxyServer;
    property ProxyPort: Integer read getProxyPort write setProxyPort;
    property ProxyUsername: string read FProxyUsername write FProxyUsername;
    property ProxyPassword: string read FProxyPassword write FProxyPassword;
    property HttpUserAgent: string read getHttpUserAgent write setHttpUserAgent;
    property HttpAccept: string read getHttpAccept write setHttpAccept;
    property HttpAcceptCharSet: string read getHttpAcceptCharSet write setHttpAcceptCharSet;
    property HttpAcceptLanguage: string read getHttpAcceptLanguage write setHttpAcceptLanguage;
    property HttpAcceptEncoding: string read getHttpAcceptEncoding write setHttpAcceptEncoding;
    property HttpCacheControl: string read getHttpCacheControl write setHttpCacheControl;
    property HttpConnection: string read getHttpConnection write setHttpConnection;
    property HttpPragma: string read getHttpPragma write setHttpPragma;
    property HttpContentEncoding: string read getHttpContentEncoding write setHttpContentEncoding;
    property HttpContentType: string read getHttpContentType write setHttpContentType;
  end;

implementation

uses
  SysUtils, IdStack, IdExceptionCore, IdAuthenticationSSPI,
  IdAuthenticationDigest;

{ THttpsConnection }

constructor THttpsConnection.Create();
begin
  inherited;
  FInitialized := false;
  FIdHttp := TIdHTTP.Create();
  FIdSSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create();

  {$IFDEF USE_EXT_PROXY_AUTH}
  FIdHttp.OnSelectAuthorization := OnSelectAuthorization;
  FIdHttp.OnAuthorization := OnAuthorization;
  FIdHttp.OnSelectProxyAuthorization := OnSelectProxyAuthorization;
  FIdHttp.OnProxyAuthorization := OnProxyAuthorization;
  FIdHttp.HTTPOptions := FIdHttp.HTTPOptions + [hoInProcessAuth];
  {$ENDIF}
end;

destructor THttpsConnection.Destroy;
begin
  FIdHttp.Free();
  FIdSSLIOHandlerSocketOpenSSL.Free();
  inherited;
end;

//------------------------------------------------------------------------------

procedure THttpsConnection.Initialize;
begin
  try
    with FIdSSLIOHandlerSocketOpenSSL do
    begin
      SSLOptions.Method         := sslvTLSv1; // sslvSSLv23;
      SSLOptions.Mode           := sslmUnassigned;
      SSLOptions.VerifyMode     := [];
      SSLOptions.VerifyDepth    := 0;
      Host                      := '';
    end;

    FIdHttp.IOHandler           := FIdSSLIOHandlerSocketOpenSSL;
    FIdHttp.HandleRedirects     := true;
    FIdHttp.Request.Method      := 'POST';

    FInitialized := true;
  except
    on e: Exception do
      raise Exception.CreateFmt(
        'HttpsConnection initialization error. %s', [e.Message]);
  end;
end;

//------------------------------------------------------------------------------

procedure THttpsConnection.OnSelectProxyAuthorization(ASender: TObject;
  var AAuthenticationClass: TIdAuthenticationClass; AAuthInfo: TIdHeaderList);
begin
  with FIdHTTP do
    if (Pos('NTLM'      , AAuthInfo.Text) >= 0)
    or (Pos('Negotiate' , AAuthInfo.Text) >= 0)  then
    begin
      AAuthenticationClass := TIdSSPINTLMAuthentication;
      ProxyParams.BasicAuthentication := false;
    end
    else if Pos('Basic' , AAuthInfo.Text) >= 0 then
    begin
      AAuthenticationClass := TIdBasicAuthentication;
      ProxyParams.BasicAuthentication := true;
    end
    else if Pos('Digest', AAuthInfo.Text) >= 0 then
    begin
      AAuthenticationClass := TIdDigestAuthentication;
      ProxyParams.BasicAuthentication := false;
    end;
end;

procedure THttpsConnection.OnProxyAuthorization(ASender: TObject;
  AAuthentication: TIdAuthentication; var AHandled: Boolean);
begin
  if AAuthentication is TIdSSPINTLMAuthentication then
  begin
    AHandled := True;
  end
  else
  begin
    AAuthentication.Username := FProxyUsername;
    AAuthentication.Password := FProxyPassword;
    if (AAuthentication is TIdDigestAuthentication) then
    begin
      TIdDigestAuthentication(AAuthentication).Method := FIdHTTP.Request.Method;
      TIdDigestAuthentication(AAuthentication).Uri    := FIdHTTP.URL.URI;
    end;
    AHandled := True;
  end;
end;

//------------------------------------------------------------------------------

procedure THttpsConnection.SaveDebugData(AStream: TStream; AMessage, AFileName: string);
var
  fs: TFileStream;
  ts: string;
begin
  try
    fs := TFileStream.Create(AFileName, fmOpenReadWrite);
  except
    fs := TFileStream.Create(AFileName, fmCreate);
  end;
  try
    fs.Seek(0, soFromEnd);
    ts := Format('%s : %s'#$D#$A, [TimeToStr(Now()), AMessage]);;
    fs.Write(ts[1], Length(ts));
    fs.CopyFrom(AStream, 0);
  finally
    fs.Free();
  end;
end;

//------------------------------------------------------------------------------

procedure THttpsConnection.Post(AURL: string; ARequest, AResponse: TStream);
begin
  try
    if not FInitialized then
      Initialize();

    {$IFDEF DEBUG_SAVE_LOG}
    SaveDebugData(ARequest, 'Request', 'c:\https_connection.log');
    {$ENDIF}

    FIdHttp.Request.ContentLength := ARequest.Size;
    ARequest.Position := 0;
    AResponse.Position := 0;
    FIdHttp.Post(AURL, ARequest, AResponse);

    {$IFDEF DEBUG_SAVE_LOG}
    SaveDebugData(AResponse, 'Response', 'c:\https_connection.log');
    {$ENDIF}

    AResponse.Position := 0;
  except
    on e: EIdHTTPProtocolException do
      raise Exception.CreateFmt('HTTP Protocol Exception (HTTP status: %d): %s. %s.',
        [e.ErrorCode, e.Message, e.ErrorMessage]);
    on e: EIdSocketError do
      raise Exception.CreateFmt('Socket Error (Last Error: %d): %s.',
        [e.LastError, e.Message]);
    on e: EIdReadTimeout do
      raise Exception.CreateFmt('Read Timeout: %s.', [e.Message]);
    on e: Exception do
      raise Exception.CreateFmt('HttpsConnection post error. Class Name: %s. %s.',
        [e.ClassName, e.Message]);
  end;
end;

//------------------------------------------------------------------------------

function THttpsConnection.getConnectTimeout: Integer;
begin
  Result := FIdHttp.ConnectTimeout;
end;

function THttpsConnection.getReadTimeout: Integer;
begin
  Result := FIdHttp.ReadTimeout;
end;

procedure THttpsConnection.setConnectTimeout(const Value: Integer);
begin
  FIdHttp.ConnectTimeout := Value;
end;

procedure THttpsConnection.setReadTimeout(const Value: Integer);
begin
  FIdHttp.ReadTimeout := Value;
end;

function THttpsConnection.getProxyServer: string;
begin
  Result := FIdHttp.ProxyParams.ProxyServer;
end;

procedure THttpsConnection.setProxyServer(const Value: string);
begin
  FIdHttp.ProxyParams.ProxyServer := Value;
end;

function THttpsConnection.getProxyPort: Integer;
begin
  Result := FIdHttp.ProxyParams.ProxyPort;
end;

procedure THttpsConnection.setProxyPort(const Value: Integer);
begin
  if FIdHttp.ProxyParams.ProxyServer <> '' then
    FIdHttp.ProxyParams.ProxyPort := Value;
end;

function THttpsConnection.getHttpAccept: string;
begin
  Result := FIdHttp.Request.Accept;
end;

function THttpsConnection.getHttpAcceptCharSet: string;
begin
  Result := FIdHttp.Request.AcceptCharSet;
end;

function THttpsConnection.getHttpAcceptEncoding: string;
begin
  Result := FIdHttp.Request.AcceptEncoding;
end;

function THttpsConnection.getHttpAcceptLanguage: string;
begin
  Result := FIdHttp.Request.AcceptLanguage;
end;

function THttpsConnection.getHttpCacheControl: string;
begin
  Result := FIdHttp.Request.CacheControl;
end;

function THttpsConnection.getHttpConnection: string;
begin
  Result := FIdHttp.Request.Connection;
end;

function THttpsConnection.getHttpContentEncoding: string;
begin
  Result := FIdHttp.Request.ContentEncoding;
end;

function THttpsConnection.getHttpPragma: string;
begin
  Result := FIdHttp.Request.Pragma;
end;

function THttpsConnection.getHttpUserAgent: string;
begin
  Result := FIdHttp.Request.UserAgent;
end;

function THttpsConnection.getHttpContentType: string;
begin
  Result := FIdHttp.Request.ContentType;
end;

procedure THttpsConnection.setHttpAccept(const Value: string);
begin
  FIdHttp.Request.Accept := Value;
end;

procedure THttpsConnection.setHttpAcceptCharSet(
  const Value: string);
begin
  FIdHttp.Request.AcceptCharSet := Value;
end;

procedure THttpsConnection.setHttpAcceptEncoding(
  const Value: string);
begin
  FIdHttp.Request.AcceptEncoding := Value;
end;

procedure THttpsConnection.setHttpAcceptLanguage(
  const Value: string);
begin
  FIdHttp.Request.AcceptLanguage := Value;
end;

procedure THttpsConnection.setHttpCacheControl(
  const Value: string);
begin
  FIdHttp.Request.CacheControl := Value;
end;

procedure THttpsConnection.setHttpConnection(const Value: string);
begin
  FIdHttp.Request.Connection := Value;
end;

procedure THttpsConnection.setHttpContentEncoding(
  const Value: string);
begin
  FIdHttp.Request.ContentEncoding := Value;
end;

procedure THttpsConnection.setHttpPragma(const Value: string);
begin
  FIdHttp.Request.Pragma := Value;
end;

procedure THttpsConnection.setHttpUserAgent(const Value: string);
begin
  FIdHttp.Request.UserAgent := Value;
end;

procedure THttpsConnection.setHttpContentType(const Value: string);
begin
  FIdHttp.Request.ContentType := Value;
end;

procedure THttpsConnection.OnAuthorization(ASender: TObject;
  AAuthentication: TIdAuthentication; var AHandled: Boolean);
begin
  if AAuthentication is TIdSSPINTLMAuthentication then
  begin
    AHandled := True;
  end
  else
  begin
    AAuthentication.Username := FProxyUsername;
    AAuthentication.Password := FProxyPassword;
    if (AAuthentication is TIdDigestAuthentication) then
    begin
      TIdDigestAuthentication(AAuthentication).Method := FIdHTTP.Request.Method;
      TIdDigestAuthentication(AAuthentication).Uri    := FIdHTTP.URL.URI;
    end;
    AHandled := True;
  end;
end;

procedure THttpsConnection.OnSelectAuthorization(ASender: TObject;
  var AAuthenticationClass: TIdAuthenticationClass;
  AAuthInfo: TIdHeaderList);
begin
  with FIdHTTP do
    begin
      AAuthenticationClass := TIdBasicAuthentication;
      ProxyParams.BasicAuthentication := true;
    end;
end;

end.
