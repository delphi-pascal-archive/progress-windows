unit D_Window;

interface

uses
  Windows, Messages, CommCtrl, F_Constants, F_SysPrgBar;

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin
  Result := FALSE;
  case uMsg of

    {}
    WM_INITDIALOG:
      begin
        //
        hApp := hWnd;
        //
        SendMessage(GetDlgItem(hApp, IDC_TRACKBAR), TBM_SETRANGE, 0, MAKELONG(0, 100));
        //
        SendMessage(GetDlgItem(hApp, IDC_PROGHORZ), PBM_SETRANGE, 0, MAKELPARAM(0, 100));
        SendMessage(GetDlgItem(hApp, IDC_PROGVERT), PBM_SETRANGE, 0, MAKELPARAM(0, 100));
        SendMessage(GetDlgItem(hApp, IDC_PROGHORZ), PBM_SETSTEP, 0, 0);
        SendMessage(GetDlgItem(hApp, IDC_PROGVERT), PBM_SETSTEP, 0, 0);
        //
        SetFocus(hApp);
      end;

    {}
    WM_HSCROLL:
      case LoWord(wParam) of
        TB_PAGEUP, TB_LINEUP, TB_LINEDOWN, TB_PAGEDOWN, TB_TOP, TB_BOTTOM, TB_ENDTRACK, TB_THUMBPOSITION, TB_THUMBTRACK:
           begin
             pPos := SendMessage(GetDlgItem(hApp, IDC_TRACKBAR), TBM_GETPOS, 0, 0);
             SendMessage(GetDlgItem(hApp, IDC_PROGHORZ), PBM_SETPOS, pPos, 0);
             SendMessage(GetDlgItem(hApp, IDC_PROGVERT), PBM_SETPOS, pPos, 0);
             //SendMessage(hApp, WM_SETTEXT, 0, Integer(PAnsiChar(IntToStr(pPos))));
           end;
      end;

    {}
    WM_DESTROY, WM_CLOSE:
      begin
        DeinitProgressClass(hInstance);
        PostQuitMessage(0);
      end;

  end;
end;

end.