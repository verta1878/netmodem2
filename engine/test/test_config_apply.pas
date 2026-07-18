program test_config_apply;
{$MODE OBJFPC}{$H+}
{ Config -> parse -> apply -> nodes up on bridge. }
uses SysUtils, NM_UART16550, NM_Fossil, NetTransport, NM_ATCommand, NM_Node,
     NM_SeamProtocol, NM_ServerBridge, NM_Config, NM_ConfigApply;
var
  cfg: TNMConfig; br: TServerBridge; r: TApplyResult; pass,fail: Integer;
procedure Check(c:Boolean;const nm:string);
begin if c then begin Inc(pass);writeln('  PASS: ',nm);end else begin Inc(fail);writeln('  FAIL: ',nm);end;end;
begin
  pass:=0;fail:=0;

  writeln('== valid config -> apply -> nodes accounted for ==');
  cfg := TNMConfig.Create;
  cfg.ParseText('node 3 comport 3 baud 38400'+#10+'node 4 comport 4 baud 57600'+#10+'node 5 comport 5');
  Check(cfg.IsValid, 'config parsed cleanly');
  Check(cfg.NodeCount = 3, '3 nodes configured');
  br := TServerBridge.Create;
  r := ApplyConfig(cfg, br);
  Check(r.Brought + r.Skipped = 3, 'all 3 nodes accounted for');
  writeln('     (brought=',r.Brought,' skipped=',r.Skipped,')');
  br.Free; cfg.Free;

  writeln('== INVALID config refuses to apply ==');
  cfg := TNMConfig.Create;
  cfg.ParseText('node 3 comport 3'+#10+'node 999 comport 3');
  Check(not cfg.IsValid, 'config invalid');
  br := TServerBridge.Create;
  r := ApplyConfig(cfg, br);
  Check((r.Brought = 0) and (r.Skipped = 0), 'invalid config applied NOTHING');
  br.Free; cfg.Free;

  writeln('== empty config applies cleanly ==');
  cfg := TNMConfig.Create;
  br := TServerBridge.Create;
  r := ApplyConfig(cfg, br);
  Check((r.Brought=0) and (r.Skipped=0), 'empty -> 0 up, 0 skipped');
  br.Free; cfg.Free;

  writeln('== nil safety ==');
  r := ApplyConfig(nil, nil);
  Check((r.Brought=0) and (r.Skipped=0), 'nil handled safely');

  writeln;
  writeln('RESULT: ',pass,' passed, ',fail,' failed');
  if fail=0 then writeln('CONFIG APPLY - VERIFIED');
end.
