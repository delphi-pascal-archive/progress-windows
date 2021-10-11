program Project;

{$R Project.res}

uses
  Windows, F_Constants, CommCtrl, F_SysPrgBar, D_Window;

begin
  InitCommonControls;
  iccex.dwSize := SizeOf(TInitCommonControlsEx);
  iccex.dwICC  := ICC_BAR_CLASSES;
  InitCommonControlsEx(iccex);
  InitProgressClass(hInstance);
  DialogBox(hInstance, MAKEINTRESOURCE(RES_DIALOG), 0, @MainDlgProc);
end.