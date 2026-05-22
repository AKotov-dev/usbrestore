unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons;

type

  { TSelectForm }

  TSelectForm = class(TForm)
    StartBtn: TBitBtn;
    CancelBtn: TBitBtn;
    Label1: TLabel;
    RadioGroup1: TRadioGroup;
    procedure StartBtnClick(Sender: TObject);
  private

  public

  end;

var
  SelectForm: TSelectForm;

implementation

uses unit1, start_trd;


{$R *.lfm}

{ TSelectForm }

procedure TSelectForm.StartBtnClick(Sender: TObject);
begin
    StartRestore.Create(False);
end;

end.

