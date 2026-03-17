#Requires AutoHotkey v2.0

class Toast {
    ; ── 상태 변수 ─────────────────────────────────────────────────────────────
    static _gui    := ""
    static _hwnd   := 0
    static _alpha  := 0
    static _phase  := 0   ; 0=idle 1=fadein 2=visible 3=fadeout
    static _ticker := ""  ; 페이드인/아웃 반복 타이머
    static _waiter := ""  ; 표시 대기 단발 타이머

    ; imeStatus: 1 = 한글, 0 = 영문
    static Show(imeStatus) {
        ; 기존 타이머/GUI 모두 즉시 정리
        this._StopAll()

        text    := imeStatus ? "한글" : "Eng"
        bgColor := imeStatus ? "C0392B" : "1A6BBE"
        static W := 120, H := 90

        mon := this._GetActiveMonitor()
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "IMEGuard_Toast")
        g.BackColor := bgColor
        g.SetFont("s22 bold cFFFFFF", "Segoe UI")
        g.Add("Text", "x0 y12 w" W " h62 Center", text)
        g.Show("NA x-500 y-500 w" W " h" H)

        hRgn := DllCall("CreateRoundRectRgn",
            "Int", 0, "Int", 0, "Int", W+1, "Int", H+1,
            "Int", 18, "Int", 18, "Ptr")
        DllCall("SetWindowRgn", "Ptr", g.Hwnd, "Ptr", hRgn, "Int", true)
        WinSetExStyle("+0x80020", "ahk_id " g.Hwnd)

        x := mon.Left + (mon.Right - mon.Left - W) // 2
        y := mon.Bottom - 220
        g.Move(x, y)
        WinSetTransparent(0, "ahk_id " g.Hwnd)

        this._gui   := g
        this._hwnd  := g.Hwnd
        this._alpha := 0
        this._phase := 1

        ; 페이드인 시작 (20ms 간격)
        fn := ObjBindMethod(Toast, "_FadeInTick")
        this._ticker := fn
        SetTimer(fn, 20)
    }

    ; ── 페이드인 단계 (20ms마다) ──────────────────────────────────────────────
    static _FadeInTick() {
        if !this._gui || this._phase != 1 {
            SetTimer(this._ticker, 0)
            return
        }
        this._alpha += 15
        if this._alpha >= 150 {
            this._alpha := 150
            WinSetTransparent(150, "ahk_id " this._hwnd)
            SetTimer(this._ticker, 0)
            this._phase := 2
            ; 표시 시간 후 페이드아웃 예약
            fn := ObjBindMethod(Toast, "_BeginFadeOut")
            this._waiter := fn
            SetTimer(fn, -Round(Config.ToastDisplaySeconds * 1000))
        } else {
            WinSetTransparent(this._alpha, "ahk_id " this._hwnd)
        }
    }

    ; ── 페이드아웃 시작 ───────────────────────────────────────────────────────
    static _BeginFadeOut() {
        this._waiter := ""
        if !this._gui || this._phase != 2
            return
        this._phase := 3
        fn := ObjBindMethod(Toast, "_FadeOutTick")
        this._ticker := fn
        SetTimer(fn, 50)
    }

    ; ── 페이드아웃 단계 (50ms마다) ────────────────────────────────────────────
    static _FadeOutTick() {
        if !this._gui || this._phase != 3 {
            SetTimer(this._ticker, 0)
            return
        }
        this._alpha -= 15
        if this._alpha <= 0 {
            SetTimer(this._ticker, 0)
            this._ticker := ""
            this._phase  := 0
            try this._gui.Destroy()
            this._gui  := ""
            this._hwnd := 0
        } else {
            WinSetTransparent(this._alpha, "ahk_id " this._hwnd)
        }
    }

    ; ── 모든 타이머/GUI 정리 ──────────────────────────────────────────────────
    static _StopAll() {
        if this._ticker {
            SetTimer(this._ticker, 0)
            this._ticker := ""
        }
        if this._waiter {
            SetTimer(this._waiter, 0)
            this._waiter := ""
        }
        if this._gui {
            try this._gui.Destroy()
            this._gui  := ""
            this._hwnd := 0
        }
        this._phase := 0
        this._alpha := 0
    }

    ; ── 활성 모니터 영역 반환 ────────────────────────────────────────────────
    static _GetActiveMonitor() {
        try {
            hwnd := WinGetID("A")
            WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
            cx := wx + ww // 2
            cy := wy + wh // 2
            count := MonitorGetCount()
            loop count {
                MonitorGet(A_Index, &mL, &mT, &mR, &mB)
                if (cx >= mL && cx < mR && cy >= mT && cy < mB)
                    return {Left: mL, Top: mT, Right: mR, Bottom: mB}
            }
        }
        pri := MonitorGetPrimary()
        MonitorGet(pri, &mL, &mT, &mR, &mB)
        return {Left: mL, Top: mT, Right: mR, Bottom: mB}
    }
}
