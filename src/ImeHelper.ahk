#Requires AutoHotkey v2.0

class ImeHelper {
    ; ── IME 상태 확인 ─────────────────────────────────────────────────────────
    ; ImmGetDefaultIMEWnd + SendMessage 방식 (모던 앱/터미널 포함 호환)
    ; 반환값: 1 = 한글, 0 = 영문
    static GetStatus(hwnd := 0) {
        if !hwnd
            hwnd := WinGetID("A")
        imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
        if !imeWnd
            return 0
        ; WM_IME_CONTROL=0x283, IMC_GETOPENSTATUS=0x5
        ; 4번째=Control(생략), 5번째=WinTitle
        return SendMessage(0x283, 0x5, 0, , "ahk_id " imeWnd)
    }

    ; ── IME 상태 설정 ─────────────────────────────────────────────────────────
    ; status: 1 = 한글, 0 = 영문
    static SetStatus(hwnd, status) {
        imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
        if !imeWnd
            return
        ; WM_IME_CONTROL=0x283, IMC_SETOPENSTATUS=0x6
        SendMessage(0x283, 0x6, status, , "ahk_id " imeWnd)
    }

    ; ── 영문 강제 전환 ────────────────────────────────────────────────────────
    ; 한글 모드였을 경우 true 반환
    static ForceEnglish() {
        hwnd := WinGetID("A")
        if this.GetStatus(hwnd) {
            this.SetStatus(hwnd, 0)
            return true
        }
        return false
    }

    ; ── 터미널 IME 포커스 복구 ────────────────────────────────────────────────
    ; Windows Terminal / WSL2 / PowerShell / Warp 에서 한글 입력 불가 현상 해결
    ; 반환값: 복구 후 IME 상태 (1=한글, 0=영문)
    static Recovery() {
        origHwnd := WinGetID("A")

        ; 오프스크린에 더미 GUI 생성 → IME 포커스를 잠깐 가져옴
        dummy := Gui("+AlwaysOnTop -Caption +ToolWindow", "IMEGuard_Dummy")
        dummy.BackColor := "000000"
        dummy.Show("x-300 y-300 w1 h1 NA")
        dummyHwnd := dummy.Hwnd

        Sleep(50)
        WinActivate("ahk_id " dummyHwnd)
        Sleep(80)

        ; 더미 창에서 한글 IME 강제 활성화
        this.SetStatus(dummyHwnd, 1)
        Sleep(80)

        ; 원래 창으로 포커스 복귀
        WinActivate("ahk_id " origHwnd)
        Sleep(50)

        dummy.Destroy()

        return this.GetStatus(origHwnd)
    }
}
