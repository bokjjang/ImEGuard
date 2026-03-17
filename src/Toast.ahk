#Requires AutoHotkey v2.0

class Toast {
    static _gui := ""
    static _timerFn := ""

    ; imeStatus: 1 = 한글, 0 = 영문
    static Show(imeStatus) {
        ; 기존 타이머 취소
        if this._timerFn {
            SetTimer(this._timerFn, 0)
            this._timerFn := ""
        }
        ; 기존 GUI 제거
        if this._gui {
            try this._gui.Destroy()
            this._gui := ""
        }

        text := imeStatus ? "한글" : "Eng"
        bgColor := imeStatus ? "C0392B" : "1A6BBE"

        static W := 120, H := 90   ; 토스트 크기

        mon := this._GetActiveMonitor()

        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "IMEGuard_Toast")
        g.BackColor := bgColor
        g.SetFont("s22 bold cFFFFFF", "Segoe UI")
        g.Add("Text", "x0 y12 w" W " h62 Center", text)
        ; 일단 화면 밖에 배치 후 스타일 적용
        g.Show("NA x-500 y-500 w" W " h" H)

        ; 둥근 모서리 (CreateRoundRectRgn)
        hRgn := DllCall("CreateRoundRectRgn",
            "Int", 0, "Int", 0, "Int", W + 1, "Int", H + 1,
            "Int", 18, "Int", 18, "Ptr")
        DllCall("SetWindowRgn", "Ptr", g.Hwnd, "Ptr", hRgn, "Int", true)

        ; WS_EX_LAYERED(0x80000) + WS_EX_TRANSPARENT(0x20) → 반투명 + 클릭 통과
        WinSetExStyle("+0x80020", "ahk_id " g.Hwnd)

        ; 활성 모니터 하단 중앙 배치
        x := mon.Left + (mon.Right - mon.Left - W) // 2
        y := mon.Bottom - 220
        g.Move(x, y)

        this._gui := g

        ; ── 페이드 아웃 타이머를 페이드인 전에 미리 예약 ────────────────────
        ; (페이드인 200ms + 표시 시간) 후 실행 → 중간에 return 해도 타이머 보장
        fn := ObjBindMethod(Toast, "_FadeOut")
        this._timerFn := fn
        totalMs := 200 + Round(Config.ToastDisplaySeconds * 1000)
        SetTimer(fn, -totalMs)

        ; ── 페이드 인 (0.2초) ────────────────────────────────────────────────
        WinSetTransparent(0, "ahk_id " g.Hwnd)
        loop 10 {
            if this._gui != g   ; 도중에 새 토스트가 시작되면 중단
                return
            WinSetTransparent(A_Index * 15, "ahk_id " g.Hwnd)
            Sleep(20)
        }
        if this._gui != g
            return
        WinSetTransparent(150, "ahk_id " g.Hwnd)
    }

    static _FadeOut() {
        this._timerFn := ""
        if !this._gui
            return
        g := this._gui
        ; 페이드 아웃 (0.5초)
        loop 10 {
            if this._gui != g
                return
            WinSetTransparent(150 - A_Index * 15, "ahk_id " g.Hwnd)
            Sleep(50)
        }
        if this._gui = g {
            try g.Destroy()
            this._gui := ""
        }
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
                    return { Left: mL, Top: mT, Right: mR, Bottom: mB }
            }
        }
        ; fallback: 주 모니터
        pri := MonitorGetPrimary()
        MonitorGet(pri, &mL, &mT, &mR, &mB)
        return { Left: mL, Top: mT, Right: mR, Bottom: mB }
    }
}