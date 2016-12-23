unit YDSDatabase;

interface

uses Classes, dbxJSON;

const
  cFMT_CLOUD_API_DB          = 'https://cloud-api.yandex.net/v1/data/%s/databases/%s';
  cFMT_CLOUD_API_DB_REVISION = 'https://cloud-api.yandex.net/v1/data/%s/databases/%s/?fields=revision';
  cFMT_CLOUD_API_DELTAS      = 'https://cloud-api.yandex.net/v1/data/%s/databases/%s/deltas';
  cFMT_CLOUD_API_SNAPSHOT    = 'https://cloud-api.yandex.net/v1/data/%s/databases/%s/snapshot';

  cHandleTag       = 'handle';
  cRecordsCountTag = 'records_count';
  cCreatedTag      = 'created';
  cModifiedTag     = 'modified';
  cDatabaseIDTag   = 'database_id';
  cRevisionTag     = 'revision';
  cSizeTag         = 'size';


type TDataSyncDatabase = class (TObject)
  private
    FHandle: String;
    FRecordsCount: Integer;
    FCreated: string;//TDateTime;
    FModified: string;//TDateTime;
    FDatabaseID: String;
    FRevision: Integer;
    FSize: Integer;
    function getURI(AContext, ADatabaseID: String): String;
    function getURIDeltas(AContext, ADatabaseID: String): String;
    function getURIRevision(AContext, ADatabaseID: String): String;
    function getURISnapshot(AContext, ADatabaseID, ACollectionID: String): String;
    procedure parseJSON(Value: TJSONValue);
  published
    property revision : Integer read FRevision;
    property size : Integer read FSize;
    property RecordsCount : Integer read FRecordsCount;
    property database_id: string read FDatabaseID;
    property handle: string read FHandle;
    property created: string read FCreated;
    property modified: string read FModified;
  public
    function CreateDatabase(AContext, ADatabaseID, AToken: String; AFields: TObject): Integer;
    function GetDatabaseInfo(AContext, ADatabaseID, AToken: String): Integer;
    function GetDatabaseRevision(AContext, ADatabaseID, AToken: String; VDocument: TMemoryStream): Integer;
    function PostData(AContext, ADatabaseID, AToken: String; ARevision: Integer;var VDocument: TMemoryStream): Integer;
    function GetSnapshot(AContext, ADatabaseID, AToken, ACollectionID: String; var VDocument: TMemoryStream): Integer;
    constructor Create;
    destructor Destroy; override;
    function StreamToString(AStream: TMemoryStream): String;
end;

implementation

{ TDataSyncDatabase }

uses SysUtils, httpsend, Dialogs;

constructor TDataSyncDatabase.Create;
begin
  inherited Create;
end;

function TDataSyncDatabase.CreateDatabase(AContext, ADatabaseID, AToken: String;
  AFields: TObject): Integer;
begin
  with THTTPSend.Create do
  begin
    Headers.Add('Authorization: OAuth '+AToken);
    Headers.Add('Content-Type: application/json');

    if HTTPMethod('PUT', getURI(AContext, ADatabaseID)) then
    begin
      ShowMessage(Format('%d ===== %s', [ResultCode, ResultString]));
    end;
    Result := ResultCode;
  end;
end;

destructor TDataSyncDatabase.Destroy;
begin
  inherited Destroy;
end;

function TDataSyncDatabase.StreamToString(AStream: TMemoryStream): String;
var
  sl: TStringList;
begin
  Result := '';
  sl := TStringList.Create;
  try
    AStream.Position := 0;
    sl.LoadFromStream(AStream);
    Result := sl.Text;
  finally
    sl.Free;
  end;
end;

function TDataSyncDatabase.GetDatabaseInfo(AContext, ADatabaseID,
  AToken: String): Integer;
var
  json: TJSONObject;
  text: string;
begin
  with THTTPSend.Create do
  begin
    Headers.Add('Authorization: OAuth '+AToken);
    Headers.Add('Content-Type: application/json');

    if HTTPMethod('GET', getURI(AContext, ADatabaseID)) then
    begin
      if ResultCode = 200 then
      begin
        text := StreamToString(Document);
        json := TJSONObject.ParseJSONValue(text) as TJSONObject;
        parseJSON(json);
      end;
    end;
    Result := ResultCode;
  end;
end;

function TDataSyncDatabase.GetDatabaseRevision(AContext, ADatabaseID,
  AToken: String; VDocument: TMemoryStream): Integer;
begin
  with THTTPSend.Create do
  begin
    Headers.Add('Authorization: OAuth '+AToken);
    Headers.Add('Content-Type: application/json');

    if HTTPMethod('GET', getURIRevision(AContext, ADatabaseID)) then
    begin
      Document.SaveToStream(VDocument);
    end;
    Result := ResultCode;
  end;
end;

function TDataSyncDatabase.GetSnapshot(AContext, ADatabaseID, AToken,
  ACollectionID: String; var VDocument: TMemoryStream): Integer;
begin
  with THTTPSend.Create do
  begin
    Headers.Add('Authorization: OAuth '+AToken);
    MimeType := 'application/json';

    if HTTPMethod('GET', getURISnapshot(AContext, ADatabaseID, ACollectionID)) then
    begin
      Document.SaveToStream(VDocument);
    end;
    Result := ResultCode;
  end;
end;

function TDataSyncDatabase.getURI(AContext, ADatabaseID: String): String;
begin
  Result := Format(cFMT_CLOUD_API_DB, [AContext, ADatabaseID]);
end;

function TDataSyncDatabase.getURIDeltas(AContext, ADatabaseID: String): String;
begin
  Result := Format(cFMT_CLOUD_API_DELTAS, [AContext, ADatabaseID]);
end;

function TDataSyncDatabase.getURIRevision(AContext,
  ADatabaseID: String): String;
begin
  Result := Format(cFMT_CLOUD_API_DB_REVISION, [AContext, ADatabaseID]);
end;

function TDataSyncDatabase.getURISnapshot(AContext, ADatabaseID,
  ACollectionID: String): String;
begin
  if Length(ACollectionID)=0 then
    Result := Format(cFMT_CLOUD_API_SNAPSHOT, [AContext, ADatabaseID])
  else
    Result := Format(cFMT_CLOUD_API_SNAPSHOT, [AContext, ADatabaseID])+'/?collection_id='+ACollectionID
end;

procedure TDataSyncDatabase.parseJSON(Value: TJSONValue);
var
  JObject: TJSONObject;
  JPair: TJSONPair;
  i:integer;
  MemberName: string;
begin
  if not Assigned(Value) then  Exit;
  JObject := (Value as TJSONObject);//привели значение пары к классу TJSONObject
  try
    {проходим по каждой паре}
    for I := 0 to JObject.Size-1 do
      begin
        JPair:=JObject.Get(i);//получили пару по её индексу
        MemberName:=JPair.JsonString.Value;//определили имя

        {ищем в какое свойство записывать значение}
        if CompareText(MemberName, cHandleTag) = 0 then
          FHandle := JPair.JsonValue.Value
        else
          if CompareText(MemberName, cRecordsCountTag) = 0 then
            FRecordsCount := StrToInt(JPair.JsonValue.Value)
          else
            if CompareText(MemberName, cCreatedTag) = 0 then
              FCreated := JPair.JsonValue.Value
            else
              if CompareText(MemberName, cModifiedTag) = 0 then
                FModified := JPair.JsonValue.Value
              else
                if CompareText(MemberName, cDatabaseIDTag) = 0 then
                  FDatabaseID := JPair.JsonValue.Value
                else
                  if CompareText(MemberName, cRevisionTag) = 0 then
                    FRevision := StrToInt(JPair.JsonValue.Value)
                  else
                    if CompareText(MemberName, cSizeTag) = 0 then
                      FSize := StrToInt(JPair.JsonValue.Value)
      end;
  except
    raise Exception.Create('Ошибка разбора JSON');
  end;

end;

function TDataSyncDatabase.PostData(AContext, ADatabaseID, AToken: String;
  ARevision: Integer;var VDocument: TMemoryStream): Integer;
begin
  with THTTPSend.Create do
  begin
    Document.LoadFromStream(VDocument);
    Headers.Add('Authorization: OAuth '+AToken);
    Headers.Add(Format('if-match: %d', [ARevision]));
//    Headers.Add('content-type: application/json');
//    MimeType := 'application/json; charset=utf-8';
    MimeType := 'application/json; charset=windows-1251';
//    Headers.Add(Format('content-length: %d',[Document.Size]));
//    Headers.Add('charset: windows-1251');

    if HTTPMethod('POST', getURIDeltas(AContext, ADatabaseID)) then
    begin
      Document.SaveToStream(VDocument);
    end;
    Result := ResultCode;
  end;
end;

end.
