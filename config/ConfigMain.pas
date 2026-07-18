unit ConfigMain;
{ Main configuration dialog — rebuilt from NETMODEM.CPL::TForm1.
  Configures per-node NetModem settings: COM port, baud rate, emulation mode.
  Connection targets come from AT dial commands at runtime, not config. }
{$MODE OBJFPC}{$H+}
interface
uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Buttons, ExtCtrls,
  NMVxD;
type
  TfrmConfig = class(TForm)
    Nav: TListBox;
    Pages: TPageControl;
    cboComport: TComboBox;       // comport 1..99
    cboBaud: TComboBox;          // 9600/19200/38400/57600/115200
    cboMode: TComboBox;          // FOSSIL / UART
    chkEnabled: TCheckBox;       // node enabled
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure NavClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FDriver: TNetModemDriver;
    procedure LoadConfig;
    procedure SaveConfig;
  public
  end;
var
  frmConfig: TfrmConfig;
implementation
{$R *.lfm}
procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  FDriver := TNetModemDriver.Create;
  cboBaud.Items.CommaText := '9600,19200,38400,57600,115200';
  cboBaud.ItemIndex := 2;  { default 38400 }
  cboMode.Items.CommaText := 'FOSSIL,UART';
  cboMode.ItemIndex := 0;  { default FOSSIL }
  LoadConfig;
end;
procedure TfrmConfig.NavClick(Sender: TObject);
begin
  if Nav.ItemIndex >= 0 then Pages.PageIndex := Nav.ItemIndex;
end;
procedure TfrmConfig.LoadConfig;
begin
  // TODO: read config file -> populate controls
end;
procedure TfrmConfig.SaveConfig;
begin
  // TODO: write config file, then FDriver.ReloadConfig(node);
end;
procedure TfrmConfig.btnOKClick(Sender: TObject);
begin
  SaveConfig; Close;
end;
end.
