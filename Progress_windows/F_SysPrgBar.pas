unit F_SysPrgBar;

interface

uses
  Windows, Messages, CommCtrl;

function InitProgressClass(Instance: Cardinal): BOOL; stdcall;
function DeinitProgressClass(Instance: Cardinal): BOOL; stdcall;

type
  PPRO_DATA = ^PRO_DATA;
  PRO_DATA = record
    hwnd   : HWND;
    dwStyle: DWORD;
    iLow   : Integer;
    iHigh  : Integer;
    iPos   : Integer;
    iStep  : Integer;
    hfont  : HFONT;
    clrBk  : TColorRef;
    clrBar : TColorRef;
  end;

implementation

const
  szClassName = 'SysProgressBar32';

var
  wc: TWndClassEx;

//

function UpdatePosition(ppd: PPRO_DATA; iNewPos: Integer; bAllowWrap: BOOL): Integer; stdcall;
var
  iPosOrg: Integer;
  uRedraw: UINT;
begin

  iPosOrg := ppd.iPos;
  uRedraw := RDW_INVALIDATE or RDW_UPDATENOW;

  if (ppd.iLow = ppd.iHigh) then
    iNewPos := ppd.iLow;

  if (iNewPos < ppd.iLow) then
    begin
      if not bAllowWrap then
        iNewPos := ppd.iLow
      else
        begin
          iNewPos := ppd.iHigh - ((ppd.iLow - iNewPos) mod (ppd.iHigh - ppd.iLow));
          uRedraw := uRedraw or RDW_ERASE;
        end;
    end
  else
  if (iNewPos > ppd.iHigh) then
    begin
      if not bAllowWrap then
        iNewPos := ppd.iHigh
      else
        begin
          iNewPos := ppd.iLow + ((iNewPos - ppd.iHigh) mod (ppd.iHigh - ppd.iLow));
          uRedraw := uRedraw or RDW_ERASE;
        end;
    end;

  if (iNewPos < iPosOrg) then
    uRedraw := uRedraw or RDW_ERASE;

  if not (iNewPos = ppd.iPos) then
    begin
      ppd.iPos := iNewPos;
      RedrawWindow(ppd.hwnd, nil, 0, uRedraw);
    end;

  Result := iPosOrg;

end;

//

procedure ProPaint(ppd: PPRO_DATA; hdcIn: HDC); stdcall;
var
  x       : Integer;
  dxSpace : Integer;
  dxBlock : Integer;
  nBlocks : Integer;
  i       : Integer;
  dc      : HDC;
  rc      : TRect;
  rcClient: TRect;
  ps      : TPaintStruct;
  iStart  : Integer;
  iEnd    : Integer;
begin

  if (hdcIn = 0) then
    dc := BeginPaint(ppd.hwnd, ps)
  else
    dc := hdcIn;

  GetClientRect(ppd.hwnd, rcClient);
  InflateRect(rcClient, -1, -1);

  rc := rcClient;

  if ((ppd.dwStyle and PBS_VERTICAL) <> 0) then
    begin
      iStart  := rc.top;
      iEnd    := rc.bottom;
      dxBlock := (rc.right - rc.left) * 2 div 3;
    end
  else
    begin
      iStart  := rc.left;
      iEnd    := rc.right;
      dxBlock := (rc.bottom - rc.top) * 2 div 3;
    end;

  x := MulDiv(iEnd - iStart, ppd.iPos - ppd.iLow, ppd.iHigh - ppd.iLow);
  dxSpace := 2;

  if (dxBlock = 0) then
    dxBlock := 1;
  if ((ppd.dwStyle and PBS_SMOOTH) <> 0) then
    begin
      dxBlock := 1;
      dxSpace := 0;
    end;

  nBlocks := (x + (dxBlock + dxSpace) - 1) div (dxBlock + dxSpace);

  for i := 0 to nBlocks do
    begin
      if (i < nBlocks) then
        begin
          if ((ppd.dwStyle and PBS_VERTICAL) <> 0) then
            begin
              rc.top := rc.bottom - dxBlock;
              if (rc.bottom <= rcClient.top) then
                Exit;
              if (rc.top <= rcClient.top) then
                rc.top := rcClient.top + 1;
            end
          else
            begin
              rc.right := rc.left + dxBlock;
              if (rc.left >= rcClient.right) then
                Exit;
              if (rc.right >= rcClient.right) then
                rc.right := rcClient.right - 1;
            end;

          if (ppd.clrBar = CLR_DEFAULT) then
            FillRect(dc, rc, GetSysColorBrush(COLOR_HIGHLIGHT))
          else
            FillRect(dc, rc, ppd.clrBar);

          if ((ppd.dwStyle and PBS_VERTICAL) <> 0) then
            rc.bottom := rc.top - dxSpace
          else
            rc.left := rc.right + dxSpace;
        end;
    end;

  if (hdcIn = 0) then
    EndPaint(ppd.hwnd, ps);
end;

//

function Progress_OnCreate(hWnd: HWND; pcs: PCreateStruct): LRESULT; stdcall;
var
  ppd: PPRO_DATA;
begin

  ppd := PPRO_DATA(LocalAlloc(LPTR, SizeOf(ppd^)));
  if (ppd = nil) then
    begin
      Result := -1;
      Exit;
  end;

  SetWindowLong(hWnd, 0, Integer(ppd));
  ppd.hwnd    := hWnd;
  ppd.iHigh   := 100;
  ppd.iStep   := 10;
  ppd.dwStyle := pcs.style;
  ppd.clrBk   := CLR_DEFAULT;
  ppd.clrBar  := CLR_DEFAULT;
  SetWindowLong(hWnd, GWL_EXSTYLE, (pcs.dwExStyle and not WS_EX_CLIENTEDGE) or WS_EX_STATICEDGE);

  if ((pcs.dwExStyle and WS_EX_STATICEDGE) = 0) then
    SetWindowPos(hWnd, 0, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);

  Result := 0;

end;

//

function SetRange(ppd: PPRO_DATA; wParam: WPARAM; lParam: LPARAM): Integer; stdcall;
var
  lret: LRESULT;
begin
  lret := MAKELONG(ppd.iLow, ppd.iHigh);
  if (Integer(wParam) <> ppd.iLow) or (Integer(lParam) <> ppd.iHigh) then
    begin
      ppd.iHigh := Integer(lParam);
      ppd.iLow  := Integer(wParam);
      RedrawWindow(ppd.hwnd, nil, 0, RDW_INVALIDATE or RDW_ERASE);
      UpdatePosition(ppd, ppd.iPos, FALSE);
    end;
  Result := lret;
end;

//

function ProgressWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pcs : PCreateStruct;
  ppd : PPRO_DATA;
  ppb : PPBRange;
  x   : Integer;
  clr : TColorRef;
  rc  : TRect;
begin
  Result := 0;

  ppd := Pointer(GetWindowLong(hWnd, 0));

  case uMsg of

    WM_CREATE:
      begin
        pcs := PCreateStruct(lParam);
        Result := Progress_OnCreate(hWnd, pcs);
      end;

    WM_DESTROY:
      begin
        if (ppd <> nil) then
          LocalFree(HLOCAL(ppd));
      end;

    WM_SYSCOLORCHANGE:
      begin
        InvalidateRect(hWnd, nil, TRUE);
      end;
      
     WM_SETFONT:
      begin
        ppd.hfont := HFONT(wParam);
        Result := LRESULT(ppd.hfont);
      end;

    WM_LBUTTONUP:
      begin
        Result := LRESULT(ppd.hfont);
      end;

    PBM_GETPOS:
      begin
        Result := ppd.iPos;
      end;

    PBM_GETRANGE:
      begin
        if (lParam <> 0) then
          begin
            ppb := PPBRange(lParam);
            ppb.iLow  := ppd.iLow;
            ppb.iHigh := ppd.iHigh;
          end;
        if (wParam <> 0) then
          Result := ppd.iLow
        else
          Result := ppd.iHigh;
      end;

    PBM_SETRANGE:
      begin
        wParam := LoWord(lParam);
        lParam := HiWord(lParam);
        Result := LRESULT(SetRange(ppd, wParam, lParam));
      end;

    PBM_SETRANGE32:
      begin
        Result := LRESULT(SetRange(ppd, wParam, lParam));
      end;

    PBM_SETPOS:
      begin
        Result := LRESULT(UpdatePosition(ppd, Integer(wParam), FALSE));
      end;

    PBM_SETSTEP:
      begin
        x := ppd.iStep;
        ppd.iStep := Integer(wParam);
        Result := LRESULT(x);
      end;

    PBM_STEPIT:
      begin
        Result := LRESULT(UpdatePosition(ppd, ppd.iStep + ppd.iPos, TRUE));
      end;

    PBM_DELTAPOS:
      begin
        Result := LRESULT(UpdatePosition(ppd, ppd.iPos + Integer(wParam), FALSE));
      end;

    PBM_SETBKCOLOR:
      begin
        ppd.clrBk := TColorRef(lParam);
        clr := ppd.clrBk;
        InvalidateRect(hWnd, nil, TRUE);
        Result := clr;
      end;

    PBM_SETBARCOLOR:
      begin
        ppd.clrBar := TColorRef(lParam);
        clr := ppd.clrBar;
        InvalidateRect(hWnd, nil, TRUE);
        Result := clr;
      end;

    WM_PRINTCLIENT, WM_PAINT:
      begin
        ProPaint(ppd, HDC(wParam));
        Exit;
      end;

    WM_ERASEBKGND:
      begin
        if not (ppd.clrBk = CLR_DEFAULT) then
          begin
            GetClientRect(hWnd, rc);
            FillRect(HDC(wParam), rc, ppd.clrBk);
            Result := 1;
          end
        else
          Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
      end;

  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

//

function InitProgressClass(Instance: Cardinal): BOOL; stdcall;
begin
  if not GetClassInfoEx(Instance, szClassName, wc) then
    begin
      wc.lpfnWndProc   := @ProgressWndProc;
      wc.lpszClassName := szClassName;
      wc.style         := CS_GLOBALCLASS or CS_HREDRAW or CS_VREDRAW;
      wc.hInstance     := Instance;
      wc.hIcon         := 0;
      wc.hCursor       := LoadCursor(0, IDC_ARROW);
      wc.hbrBackground := HBRUSH(COLOR_BTNFACE + 1);
      wc.lpszMenuName  := nil;
      wc.cbWndExtra    := SizeOf(PPRO_DATA);
      wc.cbClsExtra    := 0;
      wc.cbSize        := SizeOf(TWndClassEx);
      Result := Boolean(RegisterClassEx(wc));
    end
  else
    Result := FALSE;
end;

//

function DeinitProgressClass(Instance: Cardinal): BOOL; stdcall;
begin
  Result := UnRegisterClass(szClassName, Instance);
end;

end.