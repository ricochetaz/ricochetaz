unit YDSResponse;

interface


type TDatabaseErrorRec = record
  Code: Integer;
  Desc: string;
end;

const
  CreateDatabaseErrorResponse:  array[1..8] of TDatabaseErrorRec =
  (
    ( Code:   400; Desc: 'Некорректно задан контекст базы данных.'),
    ( Code:   401; Desc: 'Клиент не авторизован.'),
    ( Code:   403; Desc: 'Доступ запрещен. Возможно, у приложения недостаточно прав для данного действия.'),
    ( Code:   404; Desc: 'Ресурс не найден.'),
    ( Code:   406; Desc: 'Формат передаваемых данных не поддерживается.'),
    ( Code:   423; Desc: 'В настоящий момент ресурс недоступен по техническим причинам.'),
    ( Code:   429; Desc: 'Клиент слишком часто отправляет запросы.'),
//Клиентскую часть следует реализовать таким образом, чтобы при получении такого ответа клиент отправлял серверу повторный запрос.
    ( Code:   507; Desc: 'Количество созданных баз данных достигло максимального значения.')
  );

type TDataSyncResponse = class(TObject)
  private
    FCode: Integer;
    FDesc: String;
  public
end;

implementation

end.
