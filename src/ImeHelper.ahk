#Requires AutoHotkey v2.0

class ImeHelper {
    ; 한/영 키 전송 시 토스트 중복 방지 플래그
    static Suppressing := false

    ; ── IME 상태 확인 ─────────────────────────────────────────────────────────
    ; ImmGetDefaultIMEWnd + DllCall SendMessage 방식
    ; 반환값: 1 = 한글, 0 = 영문
    static GetStatus(hwnd := 0) {
        if !hwnd
            hwnd := WinGetID("A")
        imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
        if !imeWnd
            return 0
        ; WM_IME_CONTROL=0x283, IMC_GETOPENSTATUS=0x5
        return DllCall("SendMessage", "Ptr", imeWnd, "UInt", 0x283, "Ptr", 0x5, "Ptr", 0, "Ptr")
    }

    ; ── 영문 강제 전환 ────────────────────────────────────────────────────────
    ; 한글 모드일 때 실제 한/영 키(vk15)를 전송하여 전환
    ; 한글 모드였을 경우 true 반환
    static ForceEnglish() {
        if !this.GetStatus(WinGetID("A"))
            return false
        ; vk15(한/영 키) 전송 → ShowImeToast 중복 방지
        this.Suppressing := true
        Send("{vk15}")
        this.Suppressing := false
        return true
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

        ; 더미 창에서 한글 IME 강제 활성화 후 복귀
        this.Suppressing := true
        Send("{vk15}")
        this.Suppressing := false
        Sleep(80)

        WinActivate("ahk_id " origHwnd)
        Sleep(50)
        dummy.Destroy()

        return this.GetStatus(origHwnd)
    }
}
