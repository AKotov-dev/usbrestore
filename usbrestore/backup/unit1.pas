unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, IniPropStorage, Process, DefaultTranslator, BaseUnix;

type

  { TMainForm }

  TMainForm = class(TForm)
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    StartBtn: TBitBtn;
    StaticText2: TStaticText;
    StopBtn: TBitBtn;
    DevBox: TComboBox;
    LogMemo: TMemo;
    ReloadBtn: TSpeedButton;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReloadBtnClick(Sender: TObject);
    procedure ReloadUSBDevices;
    procedure KillAll;
    procedure StartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SDestroyData1 = 'All data on the selected device ';
  SDestroyData2 = ' will be destroyed! Continue?';
  SRootPrivileges = 'Requires root startup! Terminate!';

implementation

uses start_trd;

  {$R *.lfm}

  { TMainForm }

//Начитываем removable devices (флешки)
procedure TMainForm.ReloadUSBDevices;
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Спсок флешек в /root/.usbrestore/devlist
    ExProcess.Parameters.Add(
      '> /root/.usbrestore/devlist; lsblk -ldnp -I 8 | awk ' + '''' +
      '$3 == "1" && $4 != "0B" {print $1, $4}' + '''' + ' > /root/.usbrestore/devlist');

    ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;

    DevBox.Clear;
    DevBox.Items.LoadFromFile('/root/.usbrestore/devlist');

    if DevBox.Items.Count <> 0 then
    begin
      DevBox.ItemIndex := 0;
      StartBtn.Enabled := True;
      StopBtn.Enabled := True;
    end
    else
    begin
      StartBtn.Enabled := False;
      StopBtn.Enabled := False;
    end;
  finally
    ExProcess.Free;
  end;
end;

//Останов (killall)
procedure TMainForm.KillAll;
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(
      'for ((i=1;i<2;i++)); do killall wipefs parted mkfs mkfs.fat fsck fsck.fat; sleep 1; done');
    //  ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Запуск ремонта
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  FStartRestore: TThread;
begin
  if MessageDlg(SDestroyData1 + #13#10 + '[ ' + DevBox.Text + ' ]' +
    SDestroyData2, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FStartRestore := StartRestore.Create(False);
    FStartRestore.Priority := tpHighest;
  end;
end;

//Останов всех операций
procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  KillAll;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;
  MainForm.Caption := Application.Title;
  ReloadBtn.Width := ReloadBtn.Height;

  //Показываем флешки
  ReloadBtn.Click;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Требуется su или root
  if FPGetEUID <> 0 then
  begin
    MessageDlg(SRootPrivileges, mtError, [mbOK], 0);
    Application.Terminate;
  end;

  //Создаём рабочий каталог
  if not DirectoryExists('/root/.usbrestore') then
    MkDir('/root/.usbrestore');

  IniPropStorage1.IniFileName := '/root/.usbrestore/settings';
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  KillAll;
end;

procedure TMainForm.ReloadBtnClick(Sender: TObject);
begin
  ReloadUSBDevices;
end;

end.
