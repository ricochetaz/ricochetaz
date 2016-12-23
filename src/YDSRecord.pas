unit YDSRecord;

interface

uses VirtualTable, DB;

type TDataSyncDatatypes = (yatBinary, yatString, yatDouble, yatList, yatDatetime,
  yatInteger, yatBoolean, yatNan, yatNinf, yatInf, yatNull);

type TRecordChangeTypes = (rctInsert, rctUpdate, rctSet, rctDelete);
type TFieldsChangeTypes = (fctSet, fctDelete, fctListItem_Insert, fctListItem_Sett, fctListItem_Move, fctListItem_Delete);

const
  RecordChangeTypeText: array[rctInsert .. rctDelete] of string =
  ('insert', 'update', 'set', 'delete');
  FieldsChangeTypeText: array[fctSet .. fctListItem_Delete] of string =
  ('set', 'delete', 'list_item_insert', 'list_item_set', 'list_item_move', 'list_item_delete');


type TDataSyncRecord = class (TObject)
  private
  public
    procedure Insert;
    procedure Update;
    procedure SetNew;
    procedure Delete;
end;

type TDataSyncField = class (TObject)
  private
  public
    procedure SetNew;
    procedure Delete;
    procedure ListItemInsert;
    procedure ListItemSet;
    procedure ListItemMove;
    procedure ListItemDelete;
end;

type TDataSyncDeltaBuilder = class
  private
    FVirtualTable: TVirtualTable;
    function GetFieldType(AType: TFieldType): String;
    function GetFieldValue(AField: TField): String;
    function GetFieldsChanges(AChangeType: String): String;
  public
    function GetDelta(AComment, ARecChanges: String): String;
    function GetRecChanges(AChangeType, ACollectionID, ARecID: String): String;
    constructor Create(AVT: TVirtualTable);
end;

implementation

uses SysUtils, StrUtils;

{ TDataSyncRecord }

procedure TDataSyncRecord.Delete;
begin

end;

procedure TDataSyncRecord.Insert;
begin

end;

procedure TDataSyncRecord.SetNew;
begin

end;

procedure TDataSyncRecord.Update;
begin

end;

{ TDataSyncField }

procedure TDataSyncField.Delete;
begin

end;

procedure TDataSyncField.ListItemDelete;
begin

end;

procedure TDataSyncField.ListItemInsert;
begin

end;

procedure TDataSyncField.ListItemMove;
begin

end;

procedure TDataSyncField.ListItemSet;
begin

end;

procedure TDataSyncField.SetNew;
begin

end;

{ TDataSyncDeltaBuilder }

constructor TDataSyncDeltaBuilder.Create(AVT: TVirtualTable);
begin
  inherited Create;
  FVirtualTable := AVT;
end;

function TDataSyncDeltaBuilder.GetDelta(AComment, ARecChanges: String): String;
begin
  Result := '{'
    +Format(' "delta_id": "%s",',[AComment])+#13#10
    +'  "changes":'+#13#10
    +'  ['+#13#10
    +Format('%s',[ARecChanges])
    +'  ]'+#13#10
    +'}';
end;

function TDataSyncDeltaBuilder.GetFieldType(AType: TFieldType): String;
begin
//type TDataSyncDatatypes = (yatBinary, yatList,
//  yatNan, yatNinf, yatInf, yatNull);
  case AType of
//    ftUnknown : Result := '';
    ftString  : Result := 'string';
    ftSmallint,
    ftInteger ,
    ftWord    : Result := 'integer';
    ftBoolean : Result := 'boolean';
    ftFloat   ,
    ftCurrency: Result := 'double';
//    ftBCD,
    ftDate    ,
    ftTime    ,
    ftDateTime: Result := 'datetime';
  else
    raise Exception.Create('Error Type: '+FieldTypeNames[AType]);
  end;
//    ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
//    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
//    ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
//    ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
//    ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
//    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
//    ftTimeStampOffset, ftObject, ftSingle); //49..51
end;

function TDataSyncDeltaBuilder.GetFieldValue(AField: TField): String;
begin
  case AField.DataType of
    ftString  : Result := ReplaceStr(AField.AsString, '"', '\"');
    ftSmallint,
    ftInteger ,
    ftWord    : Result := AField.AsString;
    ftBoolean : Result := AField.Value;
    ftFloat   ,
    ftCurrency: Result := AField.Value;
    ftDate    : DateTimeToString(Result, 'yyyy-mm-dd', AField.AsDateTime);
    ftTime    : DateTimeToString(Result, 'hh:nn:ss', AField.AsDateTime);
    ftDateTime: DateTimeToString(Result, 'yyyy-mm-dd"T"hh:nn:ss', AField.AsDateTime);
  else
    raise Exception.Create('Error Type: '+FieldTypeNames[AField.DataType]);
  end;
end;

function TDataSyncDeltaBuilder.GetFieldsChanges(AChangeType: String): String;
var
  onefld: String;
  fldid: String;
  stype: String;
  i: Integer;
begin
  onefld := '';
  Result := '';
  i := 0;
  while i < FVirtualTable.FieldCount do
  begin
    fldid := FVirtualTable.Fields[i].FieldName;
    stype := GetFieldType(FVirtualTable.Fields[i].DataType);

    onefld := '  {'+#13#10 +Format('      "change_type": "%s",',[AChangeType])+#13#10
     + Format('      "field_id": "%s",',[fldid])+#13#10
      +'      "value": {'
//      +Format('          "type": "%s",',[stype]) // DateTimeToString(result, 'yyyy-mm-dd', myDate);
      +Format(' "%s" : "%s"',[stype, GetFieldValue(FVirtualTable.Fields[i])])
    +'}'+#13#10;

    if (i < FVirtualTable.FieldCount-1) then
      Result := Result + onefld +'      },'+#13#10
    else
      Result := Result + onefld +'      }'+#13#10;
    inc(i);
  end;


//  Result := '  {'+#13#10
//    +Format('      "change_type": "%s",',[AChangeType])+#13#10
//    +allfld
//    +'      }'+#13#10;
end;

function TDataSyncDeltaBuilder.GetRecChanges(AChangeType, ACollectionID, ARecID: String): String;
begin
  Result := '  {'+#13#10
    +Format('    "change_type": "%s",',[AChangeType])+#13#10
    +Format('    "collection_id": "%s",',[ACollectionID])+#13#10
    +Format('    "record_id": "%s",',[ARecID])+#13#10
    +'    "changes": ['+#13#10
    +Format('    %s',[GetFieldsChanges(FieldsChangeTypeText[fctSet])])
    +'    ]'+#13#10
    +'  }';
end;

end.
