unit NM_ConfigApply;
{ ===========================================================================
  netmodem2irc — apply a parsed config to a running server
  ---------------------------------------------------------------------------
  Walks configured nodes and brings each one up on a TServerBridge with
  the configured COM port, baud rate, and emulation mode. Connection targets
  come later from AT dial commands, not from config.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  NM_Node, NM_ServerBridge, NM_Config;

type
  TApplyResult = record
    Brought : Integer;
    Skipped : Integer;
  end;

function ApplyConfig(ACfg: TNMConfig; ABridge: TServerBridge): TApplyResult;

implementation

function ApplyConfig(ACfg: TNMConfig; ABridge: TServerBridge): TApplyResult;
var
  i: Integer;
  nc: TNodeConfig;
  node: TNetModemNode;
begin
  Result.Brought := 0;
  Result.Skipped := 0;
  if (ACfg = nil) or (ABridge = nil) then Exit;
  if not ACfg.IsValid then Exit;

  for i := 0 to ACfg.NodeCount - 1 do
  begin
    if not ACfg.NodeByPosition(i, nc) then Continue;
    node := ABridge.OnConnectNode(nc.NodeIndex);
    if node <> nil then
      Inc(Result.Brought)
    else
      Inc(Result.Skipped);
  end;
end;

end.
