unit DebuggeeOpenFile;

interface

procedure InitPlugin(Unload: Boolean);

implementation

uses
  SysUtils, ToolsAPI, DebugAPI, IDEHooks, Hooking, FrmFileSelector;

type
  TFormFileSelectorAccess = class(TFormFileSelector);

function GetFullUnitFileName(const AUnitName: string): string;
var
  I: Integer;
  FS: TFormFileSelectorAccess;
begin
  Result := '';
  FS := TFormFileSelectorAccess.Create(nil);
  try
    FS.GetFilenames;
    for I := 0 to Pred(FS.FAllData.Count) do
      if SameText(TInfo(FS.FAllData[I]).Name, AUnitName) then
      begin
        Result := TInfo(FS.FAllData[I]).FileName;
        Break;
      end;
  finally
    FS.Free;
  end;
end;

procedure TDebuggerMgr_AddLogStr(Self: TObject; const LogStr: string; LogItemType: TLogItemType; const LogItem: INTALogItem; const AProcess: IOTAProcess);
  external coreide_bpl name '@Debuggermgr@TDebuggerMgr@AddLogStr$qqrx20System@UnicodeString21Toolsapi@TLogItemTypex47System@%DelphiInterface$20Debugapi@INTALogItem%x47System@%DelphiInterface$20Toolsapi@IOTAProcess%';
var
  Org_TDebuggerMgr_AddLogStr: procedure(Self: TObject; const LogStr: string; LogItemType: TLogItemType; const LogItem: INTALogItem; const AProcess: IOTAProcess);

procedure TDebuggerMgr_AddLogStrHook(Self: TObject; const LogStr: string; LogItemType: TLogItemType; const LogItem: INTALogItem; const AProcess: IOTAProcess);
const
  cIDEOpenUnit = 'IDEOpenUnit=';
var
  S: string;
  P: Integer;
begin
  if (LogItemType = litODS) and (Pos(cIDEOpenUnit, LogStr) > 0) then
  begin
    P := Pos(cIDEOpenUnit, LogStr);
    S := GetFullUnitFileName(Copy(LogStr, P + Length(cIDEOpenUnit), MaxInt));
    if S <> '' then
      (BorlandIDEServices as IOTAActionServices).OpenFile(S);
  end
  else
    Org_TDebuggerMgr_AddLogStr(Self, LogStr, LogItemType, LogItem, AProcess);
end;

procedure InitPlugin(Unload: Boolean);
begin
  if not Unload then
    @Org_TDebuggerMgr_AddLogStr := RedirectOrgCall(@TDebuggerMgr_AddLogStr, @TDebuggerMgr_AddLogStrHook)
  else
    RestoreOrgCall(@TDebuggerMgr_AddLogStr, @Org_TDebuggerMgr_AddLogStr);
end;

end.
