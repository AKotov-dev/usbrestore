unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartRestore = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartRestore.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    //Создаём раздел ${usb}1 (0B - W95 FAT32) (0C - W95 FAT32 LBA)
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    //Группа команд
    ExProcess.Parameters.Add('usb=' + Copy(MainForm.DevBox.Text, 1, 8) +
      '; umount -l $usb ${usb}1 ${usb}2 ${usb}3 ${usb}4 2>/dev/null;' +
      'echo "Clearing the partition table..." && dd if=/dev/zero of=$usb count=512 && sync && '
      + 'echo -e "\nCreating a dos partition label..." &&  echo ' +
      '''' + 'label: dos' + '''' +
      ' | sfdisk $usb && echo -e "\nCreating a FAT32 partition..." && ' +
      'echo ' + '''' + 'start=2048, type=0B, bootable' + '''' +
      ' | sfdisk $usb && echo -e "\nFormatting the partition ${usb}1 in FAT32..." && ' +
      'mkfs.fat -v -F32 -n "USBDRIVE" ${usb}1 && echo -e "\nChecking the partition ${usb}1..." && '
      + 'fsck.fat -a -w -v ${usb}1 && sync && echo -e "\nThe operation was completed successfully..."');

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      //Выводим лог
      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartRestore.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;
    Application.ProcessMessages;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Refresh;
    StartBtn.Enabled := False;
  end;
end;

//Стоп индикатора
procedure StartRestore.StopProgress;
begin
  with MainForm do
  begin
    Application.ProcessMessages;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Refresh;
    StartBtn.Enabled := True;
  end;
end;

//Вывод лога
procedure StartRestore.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Append(Result[i]);

  //Промотать список вниз
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;

  //Вывод пачками
  //MainForm.LogMemo.Lines.Assign(Result);
end;

end.
