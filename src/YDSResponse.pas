unit YDSResponse;

interface


type TDatabaseErrorRec = record
  Code: Integer;
  Desc: string;
end;

const
  CreateDatabaseErrorResponse:  array[1..8] of TDatabaseErrorRec =
  (
    ( Code:   400; Desc: '����������� ����� �������� ���� ������.'),
    ( Code:   401; Desc: '������ �� �����������.'),
    ( Code:   403; Desc: '������ ��������. ��������, � ���������� ������������ ���� ��� ������� ��������.'),
    ( Code:   404; Desc: '������ �� ������.'),
    ( Code:   406; Desc: '������ ������������ ������ �� ��������������.'),
    ( Code:   423; Desc: '� ��������� ������ ������ ���������� �� ����������� ��������.'),
    ( Code:   429; Desc: '������ ������� ����� ���������� �������.'),
//���������� ����� ������� ����������� ����� �������, ����� ��� ��������� ������ ������ ������ ��������� ������� ��������� ������.
    ( Code:   507; Desc: '���������� ��������� ��� ������ �������� ������������� ��������.')
  );

type TDataSyncResponse = class(TObject)
  private
    FCode: Integer;
    FDesc: String;
  public
end;

implementation

end.
