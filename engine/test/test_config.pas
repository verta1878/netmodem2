program test_config;
{$MODE OBJFPC}{$H+}
{ Config parsing + validation: NetModem settings (comport, baud, mode).
  Connection targets come from AT dial, not config. }
uses SysUtils, NM_UART16550, NM_Fossil, NetTransport, NM_ATCommand, NM_Node, NM_Config;
var
  cfg: TNMConfig; pass,fail: Integer; c: TNodeConfig;
procedure Check(cc:Boolean;const nm:string);
begin if cc then begin Inc(pass);writeln('  PASS: ',nm);end else begin Inc(fail);writeln('  FAIL: ',nm);end;end;

begin
  pass:=0;fail:=0;

  writeln('== happy path: valid node line ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 3 comport 3 baud 38400 mode fossil'), 'valid line accepted');
  Check(cfg.NodeCount = 1, 'one node loaded');
  Check(cfg.GetNode(3, c), 'node 3 found');
  Check((c.ComPort=3) and (c.Baud=38400) and (c.Mode=nmFossil), 'fields correct');
  Check(cfg.IsValid, 'config valid');
  cfg.Free;

  writeln('== shorthand: just comport, defaults apply ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 5 comport 5'), 'shorthand accepted');
  Check(cfg.GetNode(5, c), 'node 5 found');
  Check((c.ComPort=5) and (c.Baud=38400) and (c.Mode=nmFossil), 'defaults: baud=38400 mode=fossil');
  cfg.Free;

  writeln('== comments and blanks ignored ==');
  cfg := TNMConfig.Create;
  cfg.ParseLine('; comment');
  cfg.ParseLine('# comment');
  cfg.ParseLine('');
  cfg.ParseLine('   ');
  Check(cfg.NodeCount = 0, 'no nodes from comments');
  Check(cfg.IsValid, 'no errors');
  cfg.Free;

  writeln('== BOUNDARY: node index 0 and 98 valid, 99 and -1 rejected ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 0 comport 1'),  'index 0 accepted');
  Check(cfg.ParseLine('node 98 comport 2'), 'index 98 accepted');
  Check(not cfg.ParseLine('node 99 comport 3'),  'index 99 REJECTED');
  Check(not cfg.ParseLine('node -1 comport 4'),  'index -1 REJECTED');
  Check(cfg.ErrorCount = 2, '2 range errors');
  cfg.Free;

  writeln('== BOUNDARY: comport 1 and 99 valid, 0 and 100 rejected ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 5 comport 1'),  'comport 1 accepted');
  Check(cfg.ParseLine('node 6 comport 99'), 'comport 99 accepted');
  Check(not cfg.ParseLine('node 7 comport 0'),   'comport 0 REJECTED');
  Check(not cfg.ParseLine('node 8 comport 100'), 'comport 100 REJECTED');
  cfg.Free;

  writeln('== baud rate validation ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 3 comport 3 baud 9600'),   '9600 accepted');
  Check(cfg.ParseLine('node 4 comport 4 baud 115200'), '115200 accepted');
  Check(not cfg.ParseLine('node 5 comport 5 baud 12345'), 'invalid baud REJECTED');
  cfg.Free;

  writeln('== mode validation ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseLine('node 3 comport 3 mode fossil'), 'fossil accepted');
  Check(cfg.ParseLine('node 4 comport 4 mode uart'),   'uart accepted');
  Check(not cfg.ParseLine('node 5 comport 5 mode bogus'), 'invalid mode REJECTED');
  cfg.Free;

  writeln('== malformed lines rejected ==');
  cfg := TNMConfig.Create;
  Check(not cfg.ParseLine('node 3'),                    'too few fields rejected');
  Check(not cfg.ParseLine('node abc comport 3'),        'non-numeric index rejected');
  Check(not cfg.ParseLine('node 3 comport abc'),        'non-numeric comport rejected');
  Check(not cfg.ParseLine('frobnicate 3 comport 3'),    'unknown keyword rejected');
  Check(cfg.ErrorCount = 4, 'all 4 bad lines recorded');
  cfg.Free;

  writeln('== ParseText: multi-line config ==');
  cfg := TNMConfig.Create;
  Check(cfg.ParseText(
    '; my board' + #10 +
    'node 1 comport 3 baud 38400 mode fossil' + #10 +
    'node 2 comport 4 baud 57600' + #10 +
    '# end') = 2, 'ParseText loaded 2 nodes');
  Check(cfg.GetNode(2, c) and (c.Baud=57600), 'node 2 baud correct');
  Check(cfg.IsValid, 'multi-line valid');
  cfg.Free;

  writeln('== redefining a node updates it ==');
  cfg := TNMConfig.Create;
  cfg.ParseLine('node 4 comport 3 baud 19200');
  cfg.ParseLine('node 4 comport 5 baud 57600');
  Check(cfg.NodeCount = 1, 'still one node');
  Check(cfg.GetNode(4, c) and (c.ComPort=5) and (c.Baud=57600), 'node 4 updated');
  cfg.Free;

  writeln;
  writeln('RESULT: ',pass,' passed, ',fail,' failed');
  if fail=0 then writeln('CONFIG - VERIFIED');
end.
