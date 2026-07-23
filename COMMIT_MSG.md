20260722: Inno Setup rebuilt with BUG-029 fix — source-level system.o

All 5 Inno targets recompiled against fpc264irc with BUG-029 fix.
fpc_AnsiStr_Decr_Ref now uses sub eax,12 (source-level fix in codepage
backport, rebuilt system.ppu on all 6 targets). No more binary patches.

Audit confirmed:
  AnsiStr functions: all use sub eax,12 (12-byte TAnsiRec header) ✅
  UnicodeStr_Assign: sub eax,8 (correct, 8-byte header) ✅
  DynArray_Clear: sub eax,8 (correct, 8-byte header) ✅

Setup.exe should no longer AV on Win98/Win11 — the heap corruption
that caused the Access Violation during message string processing
is eliminated at the source.

Test on Windows: run ISCC.exe test.iss, then run test-setup.exe.
