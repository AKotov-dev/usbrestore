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

    //Создаём раздел ${usb}1
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    //Группа команд (parted)
    ExProcess.Parameters.Add('usb=' + Copy(MainForm.DevBox.Text, 1, 8) +
      '; umount -l $usb ${usb}1 ${usb}2 ${usb}3 ${usb}4 2>/dev/null; ' +
      'echo -e "Creating a dos partition label..." && ' +
      'wipefs -a $usb && parted -s $usb mklabel msdos && ' +
      'echo -e "\nCreating a FAT32 partition..." && ' +
      'parted -s $usb mkpart primary fat32 1MiB 100% && ' +
      'parted -s $usb set 1 boot on && ' +
      'echo -e "\nFormatting the partition ${usb}1..." && ' +
      'mkfs.fat -v -F32 -n "USBDRIVE" ${usb}1 && ' +
      'echo -e "\nChecking the partition ${usb}1..." && ' +
      'fsck.fat -a -w -v ${usb}1 && sync && ' +
      'echo -e "\nResult for $usb..." && parted -s $usb print && ' +
      'echo -e "The operation was completed successfully...\n"');

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
