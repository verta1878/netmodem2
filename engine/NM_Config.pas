unit NM_Config;
{ ===========================================================================
  netmodem2irc — configuration (per-node NetModem settings)
  ---------------------------------------------------------------------------
  Configures how each node behaves: COM port assignment, baud rate, emulation
  mode (FOSSIL or UART), and whether the node is enabled.

  The connection target (host/port) is NOT in config — that comes from AT dial
  commands (ATDT host:port) at runtime, just like a real modem.

  Format (plain text, one setting per line):
      node <index> comport <n> baud <rate> mode <fossil|uart>
  e.g.
      node 3 comport 3 baud 38400 mode fossil
      node 4 comport 4 baud 57600 mode fossil
  Shorthand (just comport, defaults baud=38400 mode=fossil):
      node 3 comport 3
  Lines starting with ';' or '#' are comments.

  DESIGN: parsing/validation is plain Pascal, host-testable. Every field is
  RANGE-CHECKED on load (index 0..NM_MAX_NODES-1, comport 1..99, baud in
  valid set, mode fossil|uart). Bad lines are reported, not silently accepted.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, NM_Node;

type
  TNMMode = (nmFossil, nmUart);

  TNodeConfig = record
    NodeIndex : Integer;       // node slot, 0 .. NM_MAX_NODES-1
    ComPort   : Integer;       // virtual COM port, 1..99
    Baud      : LongInt;       // baud rate: 9600/19200/38400/57600/115200
    Mode      : TNMMode;       // FOSSIL or plain UART emulation
    Enabled   : Boolean;       // node active
  end;

  TNMConfig = class
  private
    FNodes : array of TNodeConfig;
    FErrors: array of string;
    function FindNode(AIndex: Integer): Integer;
  public
    constructor Create;
    function ParseLine(const ALine: string): Boolean;
    function ParseText(const AText: string): Integer;
    function GetNode(AIndex: Integer; out ACfg: TNodeConfig): Boolean;
    function NodeCount: Integer;
    function NodeByPosition(APos: Integer; out ACfg: TNodeConfig): Boolean;
    function ErrorCount: Integer;
    function ErrorText(APos: Integer): string;
    function IsValid: Boolean;
  end;

function ValidBaud(B: LongInt): Boolean;

implementation

function ValidBaud(B: LongInt): Boolean;
begin
  Result := (B = 9600) or (B = 19200) or (B = 38400) or
            (B = 57600) or (B = 115200);
end;

constructor TNMConfig.Create;
begin
  inherited Create;
  SetLength(FNodes, 0);
  SetLength(FErrors, 0);
end;

function TNMConfig.FindNode(AIndex: Integer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to High(FNodes) do
    if FNodes[i].NodeIndex = AIndex then
    begin
      Result := i;
      Exit;
    end;
end;

function TNMConfig.ParseLine(const ALine: string): Boolean;
var
  s: string;
  parts: array of string;
  p, idx, com, code: Integer;
  baud: LongInt;
  mode: TNMMode;
  hasBaud, hasMode: Boolean;

  procedure PushErr(const Msg: string);
  begin
    SetLength(FErrors, Length(FErrors) + 1);
    FErrors[High(FErrors)] := Msg;
  end;

  procedure Split(const line: string);
  var i: Integer; cur: string;
  begin
    SetLength(parts, 0);
    cur := '';
    for i := 1 to Length(line) do
    begin
      if (line[i] = ' ') or (line[i] = #9) then
      begin
        if cur <> '' then
        begin
          SetLength(parts, Length(parts)+1);
          parts[High(parts)] := cur;
          cur := '';
        end;
      end
      else
        cur := cur + line[i];
    end;
    if cur <> '' then
    begin
      SetLength(parts, Length(parts)+1);
      parts[High(parts)] := cur;
    end;
  end;

begin
  Result := False;
  s := Trim(ALine);
  if (s = '') or (s[1] = ';') or (s[1] = '#') then Exit;

  Split(s);
  if Length(parts) = 0 then Exit;

  if LowerCase(parts[0]) <> 'node' then
  begin
    PushErr('unknown keyword: ' + parts[0]);
    Exit;
  end;

  { minimum: node <index> comport <n> }
  if Length(parts) < 4 then
  begin
    PushErr('expected: node <index> comport <n> [baud <rate>] [mode <fossil|uart>]: ' + s);
    Exit;
  end;

  { node index }
  Val(parts[1], idx, code);
  if code <> 0 then begin PushErr('node index not a number: ' + parts[1]); Exit; end;
  if (idx < 0) or (idx >= NM_MAX_NODES) then
  begin
    PushErr('node index ' + IntToStr(idx) + ' out of range (0..' +
            IntToStr(NM_MAX_NODES-1) + ')');
    Exit;
  end;

  { comport keyword + value }
  if LowerCase(parts[2]) <> 'comport' then
  begin
    PushErr('expected "comport" after node index: ' + s);
    Exit;
  end;
  Val(parts[3], com, code);
  if code <> 0 then begin PushErr('comport not a number: ' + parts[3]); Exit; end;
  if (com < 1) or (com > 99) then
  begin
    PushErr('comport ' + IntToStr(com) + ' out of range (1..99)');
    Exit;
  end;

  { defaults }
  baud := 38400;
  mode := nmFossil;
  hasBaud := False;
  hasMode := False;

  { optional: baud <rate> mode <fossil|uart> in any order }
  p := 4;
  while p <= High(parts) do
  begin
    if (LowerCase(parts[p]) = 'baud') and (p + 1 <= High(parts)) then
    begin
      Val(parts[p+1], baud, code);
      if (code <> 0) or (not ValidBaud(baud)) then
      begin
        PushErr('invalid baud rate: ' + parts[p+1] + ' (valid: 9600/19200/38400/57600/115200)');
        Exit;
      end;
      hasBaud := True;
      Inc(p, 2);
    end
    else if (LowerCase(parts[p]) = 'mode') and (p + 1 <= High(parts)) then
    begin
      if LowerCase(parts[p+1]) = 'fossil' then mode := nmFossil
      else if LowerCase(parts[p+1]) = 'uart' then mode := nmUart
      else begin PushErr('invalid mode: ' + parts[p+1] + ' (valid: fossil/uart)'); Exit; end;
      hasMode := True;
      Inc(p, 2);
    end
    else
    begin
      PushErr('unexpected token: ' + parts[p]);
      Exit;
    end;
  end;

  { store }
  p := FindNode(idx);
  if p < 0 then
  begin
    SetLength(FNodes, Length(FNodes) + 1);
    p := High(FNodes);
  end;
  FNodes[p].NodeIndex := idx;
  FNodes[p].ComPort := com;
  FNodes[p].Baud := baud;
  FNodes[p].Mode := mode;
  FNodes[p].Enabled := True;
  Result := True;
end;

function TNMConfig.ParseText(const AText: string): Integer;
var
  i, lineStart: Integer;
  line: string;
begin
  Result := 0;
  lineStart := 1;
  for i := 1 to Length(AText) + 1 do
  begin
    if (i > Length(AText)) or (AText[i] = #10) or (AText[i] = #13) then
    begin
      if i > lineStart then
      begin
        line := Copy(AText, lineStart, i - lineStart);
        if ParseLine(line) then Inc(Result);
      end;
      lineStart := i + 1;
    end;
  end;
end;

function TNMConfig.GetNode(AIndex: Integer; out ACfg: TNodeConfig): Boolean;
var pp: Integer;
begin
  pp := FindNode(AIndex);
  Result := pp >= 0;
  if Result then ACfg := FNodes[pp];
end;

function TNMConfig.NodeCount: Integer;
begin Result := Length(FNodes); end;

function TNMConfig.NodeByPosition(APos: Integer; out ACfg: TNodeConfig): Boolean;
begin
  Result := (APos >= 0) and (APos <= High(FNodes));
  if Result then ACfg := FNodes[APos];
end;

function TNMConfig.ErrorCount: Integer;
begin Result := Length(FErrors); end;

function TNMConfig.ErrorText(APos: Integer): string;
begin
  if (APos >= 0) and (APos <= High(FErrors)) then Result := FErrors[APos]
  else Result := '';
end;

function TNMConfig.IsValid: Boolean;
begin Result := Length(FErrors) = 0; end;

end.
