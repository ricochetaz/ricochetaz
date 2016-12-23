program YaDataSync;

uses
  Forms,
  ssl_openssl,
  InfobipTestFrm in 'form\InfobipTestFrm.pas' {Form1},
  HttpsConnection in 'src\HttpsConnection.pas',
  uAuth in 'form\uAuth.pas' {fAuth},
  httpsend in 'D:\SVN\SourceXE\Comp\Synapse\source\lib\httpsend.pas',
  YDSDatabase in 'src\YDSDatabase.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TInfobipTestForm, InfobipTestForm);
  Application.CreateForm(TfAuth, fAuth);
  Application.Run;
end.
