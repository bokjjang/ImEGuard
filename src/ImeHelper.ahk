#Requires AutoHotkey v2.0

class ImeHelper {
    ; ── IME 상태 확인 ─────────────────────────────────────────────────────────
    ; 반환값: 1 = 한글, 0 = 영문
    static GetStatus(hwnd := 0) {
        if !hwnd
            hwnd := this._GetFocusedHwnd()
        hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
        if !hIMC
            return 0
        status := DllCall("imm32\ImmGetOpenStatus", "Ptr", hIMC, "Int")
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
        return status
    }

    ; ── IME 상태 설정 ─────────────────────────────────────────────────────────
    ; status: 1 = 한글, 0 = 영문
    static SetStatus(hwnd, status) {
        hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
        if !hIMC
            return
        DllCall("imm32\ImmSetOpenStatus", "Ptr", hIMC, "Int", status)
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
    }

    ; ── 영문 강제 전환 ────────────────────────────────────────────────────────
    ; 한글 모드였을 경우 true 반환 (토스트 표시 여부 판단용)
    static ForceEnglish() {
        hwnd := this._GetFocusedHwnd()
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

        ; 복구 후 실제 IME 상태 반환
        return this.GetStatus(this._GetFocusedHwnd())
    }

    ; ── 포커스된 자식 컨트롤 HWND 획득 ─────────────────────────────────────
    ; 터미널 앱은 최상위 창이 아닌 자식 컨트롤에 포커스가 있어
    ; ImmGetContext에 올바른 핸들을 넘겨야 IME 상태를 정확히 가져올 수 있음
    static _GetFocusedHwnd() {
        hwnd := WinGetID("A")
        threadId := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")

        ; GUITHREADINFO 구조체
        ; cbSize(4) + flags(4) + hwndActive(Ptr) + hwndFocus(Ptr) + ...
        cbSize := 24 + 6 * A_PtrSize
        gi := Buffer(cbSize, 0)
        NumPut("UInt", cbSize, gi, 0)

        if !DllCall("GetGUIThreadInfo", "UInt", threadId, "Ptr", gi)
            return hwnd

        ; hwndFocus: cbSize(4) + flags(4) + hwndActive(A_PtrSize) 이후
        focusOffset := 8 + A_PtrSize
        focused := NumGet(gi, focusOffset, "Ptr")
        return focused ? focused : hwnd
    }
}
