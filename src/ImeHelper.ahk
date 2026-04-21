#Requires AutoHotkey v2.0

class ImeHelper {
    ; 자체 Send 시 vk15 훅 재진입 방지 플래그
    static Suppressing := false

    ; 내부 IME 상태 추적 (-1 미확정, 0 영문, 1 한글)
    ; Windows 11 새 Microsoft IME에서 IMM32 API가 무력화되는 경우 대비책
    static _tracked := -1

    ; 한/영 훅 디바운스 (vk15 + sc072가 같은 이벤트로 동시 매칭되는 경우 방지)
    static _lastToggleTick := 0

    ; ── 외부 API 3종 OR 질의 ─────────────────────────────────────────────────
    ; 하나라도 "한글" 신호를 주면 한글로 판정 (오판을 한글 쪽으로 기울여
    ; 의도치 않은 영문→한글 토글을 방지)
    ; 반환값: 1 = 한글(혹은 한글 가능성), 0 = 모든 API가 영문으로 일치
    static _QueryExternal() {
        focused := this._GetFocusedHwnd()
        top := WinGetID("A")

        if this._OpenStatusOf(focused)
            return 1
        if top != focused && this._OpenStatusOf(top)
            return 1
        if this._ImeWndStatusOf(top)
            return 1
        if this._ConversionNativeOf(focused)
            return 1
        return 0
    }

    static _OpenStatusOf(hwnd) {
        hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
        if !hIMC
            return 0
        s := DllCall("imm32\ImmGetOpenStatus", "Ptr", hIMC, "Int")
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
        return s
    }

    static _ImeWndStatusOf(hwnd) {
        imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
        if !imeWnd
            return 0
        ; WM_IME_CONTROL=0x283, IMC_GETOPENSTATUS=0x5
        return DllCall("SendMessage", "Ptr", imeWnd, "UInt", 0x283, "Ptr", 0x5, "Ptr", 0, "Ptr")
    }

    static _ConversionNativeOf(hwnd) {
        hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
        if !hIMC
            return 0
        conv := Buffer(4, 0)
        sent := Buffer(4, 0)
        ok := DllCall("imm32\ImmGetConversionStatus", "Ptr", hIMC, "Ptr", conv, "Ptr", sent)
        c := ok ? NumGet(conv, 0, "UInt") : 0
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
        ; IME_CMODE_NATIVE = 0x1
        return ok ? (c & 0x1) : 0
    }

    ; ── 시작 시 내부 상태 초기 동기화 ────────────────────────────────────────
    static InitState() {
        this._tracked := this._QueryExternal()
    }

    ; ── IME 상태 조회 ────────────────────────────────────────────────────────
    ; 내부 추적 우선, 미확정이면 외부 API fallback
    static GetStatus(hwnd := 0) {
        if this._tracked >= 0
            return this._tracked
        return this._QueryExternal()
    }

    ; ── 내부 추적 상태 수동 교정 ────────────────────────────────────────────
    ; 토스트가 실제와 반대로 표시될 때(시작 시 초기 동기화 실패) 한 번 호출하면 반전
    ; 반환값: 교정 후 상태 (0=영문, 1=한글)
    static CorrectState() {
        current := this._tracked >= 0 ? this._tracked : 0
        this._tracked := current ? 0 : 1
        return this._tracked
    }

    ; ── 사용자가 실제로 한/영 키를 눌렀을 때 호출 ───────────────────────────
    ; 디바운스 후 내부 상태 토글. 미확정 상태면 외부 API로 재동기화
    ; 반환값: 디바운스에 걸려 무시된 경우 false, 처리된 경우 true
    static NotifyHangulPressed() {
        now := A_TickCount
        if now - this._lastToggleTick < 80
            return false
        this._lastToggleTick := now

        if this._tracked < 0
            this._tracked := this._QueryExternal()
        else
            this._tracked := this._tracked ? 0 : 1
        return true
    }

    ; ── 영문 강제 전환 ───────────────────────────────────────────────────────
    ; 현재 상태와 무관하게 영문 고정. 한글에서 전환한 경우에만 true 반환
    static ForceEnglish() {
        current := this._tracked >= 0 ? this._tracked : this._QueryExternal()
        if !current {
            this._tracked := 0
            return false
        }
        this.Suppressing := true
        Send("{vk15}")
        this._tracked := 0
        this.Suppressing := false
        return true
    }

    ; ── IME 상태 직접 설정 (Recovery 보조용) ────────────────────────────────
    static SetStatus(hwnd, status) {
        hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
        if !hIMC
            return false
        ok := DllCall("imm32\ImmSetOpenStatus", "Ptr", hIMC, "Int", status)
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
        return ok
    }

    ; ── 터미널 IME 포커스 복구 ───────────────────────────────────────────────
    ; Windows Terminal / WSL2 / PowerShell / Warp 에서 한글 입력 불가 현상 해결
    static Recovery() {
        origHwnd := WinGetID("A")

        dummy := Gui("+AlwaysOnTop -Caption +ToolWindow", "IMEGuard_Dummy")
        dummy.BackColor := "000000"
        dummy.Show("x-300 y-300 w1 h1 NA")
        dummyHwnd := dummy.Hwnd

        Sleep(50)
        WinActivate("ahk_id " dummyHwnd)
        Sleep(80)

        this.Suppressing := true
        Send("{vk15}")
        this._tracked := 1
        this.Suppressing := false
        Sleep(80)

        WinActivate("ahk_id " origHwnd)
        Sleep(50)
        dummy.Destroy()
        return 1
    }

    ; ── 진단용 덤프 ──────────────────────────────────────────────────────────
    ; 각 API가 현재 환경에서 어떤 값을 반환하는지 확인
    static DumpDiagnostics() {
        focused := this._GetFocusedHwnd()
        top := WinGetID("A")
        title := WinGetTitle(top)
        cls := WinGetClass(top)
        a := this._OpenStatusOf(focused)
        b := this._OpenStatusOf(top)
        c := this._ImeWndStatusOf(top)
        d := this._ConversionNativeOf(focused)
        merged := this._QueryExternal()

        return Format("
        (
        Window  : [{1}] {2}
        top HWND: {3}   focused HWND: {4}
        _tracked: {5}

        ImmGetOpenStatus(focused)         = {6}
        ImmGetOpenStatus(top)             = {7}
        ImmGetDefaultIMEWnd+WM_IME_CTL    = {8}
        ImmGetConversionStatus & NATIVE   = {9}
        ---
        _QueryExternal (OR merged)        = {10}
        )",
            cls, title, top, focused, this._tracked, a, b, c, d, merged)
    }

    ; ── 포커스된 자식 컨트롤 HWND 획득 ──────────────────────────────────────
    ; 터미널 앱은 최상위 창이 아닌 자식 컨트롤에 포커스가 있음
    static _GetFocusedHwnd() {
        hwnd := WinGetID("A")
        threadId := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")

        ; GUITHREADINFO: cbSize(4) + flags(4) + hwndActive(Ptr) + hwndFocus(Ptr) + ...
        cbSize := 24 + 6 * A_PtrSize
        gi := Buffer(cbSize, 0)
        NumPut("UInt", cbSize, gi, 0)
        if !DllCall("GetGUIThreadInfo", "UInt", threadId, "Ptr", gi)
            return hwnd

        focusOffset := 8 + A_PtrSize
        focused := NumGet(gi, focusOffset, "Ptr")
        return focused ? focused : hwnd
    }
}
