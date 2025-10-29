unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartRestore = class(TThread)
  private
    // Строка для передачи в ShowLog через Synchronize
    FTempLine: string;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  protected
    procedure Execute; override;

  end;

implementation

uses Unit1;

  { TRD }

procedure StartRestore.Execute;
var
  ExProcess: TProcess;
  Buf: array[0..1023] of ansichar;
  Len: longint;
  Acc: ansistring;
  LinePos: integer;
  S: string;
begin
  FreeOnTerminate := True; //Уничтожить по завершении
  Synchronize(@StartProgress);

  Acc := '';

  try //Вывод лога и прогресса
    ExProcess := TProcess.Create(nil);

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
      'echo "The operation was completed successfully..."');

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    // , poWaitOnExit (синхронный вывод)


    ExProcess.Execute;

    while ExProcess.Running or (ExProcess.Output.NumBytesAvailable > 0) do
    begin
      Len := ExProcess.Output.NumBytesAvailable;
      if Len > 0 then
      begin
        if Len > SizeOf(Buf) then Len := SizeOf(Buf);
        ExProcess.Output.Read(Buf, Len);
        Acc := Acc + Copy(Buf, 0, Len);
        // аккумулируем байты в строку

        // Разбиваем на строки по LineEnding
        LinePos := Pos(LineEnding, string(Acc));
        while LinePos > 0 do
        begin
          S := Copy(Acc, 1, LinePos - 1);
          FTempLine := S;
          Synchronize(@ShowLog); // добавляем строку в Memo
          Delete(Acc, 1, LinePos + Length(LineEnding) - 1);
          LinePos := Pos(LineEnding, string(Acc));
        end;
      end;
      Sleep(10);
    end;

    // Вывод остатка
    if Acc <> '' then
    begin
      FTempLine := string(Acc);
      Synchronize(@ShowLog);
    end;

  finally
    ExProcess.Free;
    Synchronize(@StopProgress);
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartRestore.StartProgress;
begin
  if Assigned(MainForm) then
    with MainForm do
    begin
      LogMemo.Clear;
      Application.ProcessMessages;
      ProgressBar1.Style := pbstMarquee;
      ProgressBar1.Refresh;
      DevBox.Enabled := False;
      ReloadBtn.Enabled := False;
      StartBtn.Enabled := False;
    end;
end;

//Стоп индикатора
procedure StartRestore.StopProgress;
begin
  if Assigned(MainForm) then
    with MainForm do
    begin
      Application.ProcessMessages;
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Refresh;
      DevBox.Enabled := True;
      ReloadBtn.Enabled := True;
      StartBtn.Enabled := True;
    end;
end;

//Вывод лога
procedure StartRestore.ShowLog;
begin
  //Вывод построчно
  if Assigned(MainForm) then
    with MainForm do
    begin
      LogMemo.Lines.Append(FTempLine);

      //Промотать список вниз
      LogMemo.SelStart := Length(MainForm.LogMemo.Text);
      LogMemo.SelLength := 0;
    end;
end;

end.
