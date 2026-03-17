#Requires AutoHotkey v2.0

class Tray {
    static Build() {
        A_IconTip := "IMEGuard"
        menu := A_TrayMenu
        menu.Delete()

        menu.Add("IME 포커스 복구", (*) => this._OnRecovery())
        menu.Add()
        menu.Add("ESC 영문 고정",    (*) => this._ToggleEsc())
        menu.Add("토스트 표시",      (*) => this._ToggleToast())
        menu.Add()
        menu.Add("시작시 자동 실행", (*) => this._ToggleStartup())
        menu.Add()
        menu.Add("설정...",          (*) => Config.OpenInNotepad())
        menu.Add()
        menu.Add("종료",             (*) => ExitApp())

        menu.Default := "IME 포커스 복구"
        this.Refresh()
    }

    ; 체크 상태를 현재 Config 값에 맞게 갱신
    static Refresh() {
        menu := A_TrayMenu
        this._SetCheck(menu, "ESC 영문 고정",    Config.EscForceEnglish)
        this._SetCheck(menu, "토스트 표시",      Config.ToastEnabled)
        this._SetCheck(menu, "시작시 자동 실행", Config.RunAtStartup)
    }

    ; ── 핸들러 ────────────────────────────────────────────────────────────────
    static _OnRecovery() {
        status := ImeHelper.Recovery()
        if Config.ToastEnabled
            Toast.Show(status)
    }

    static _ToggleEsc() {
        Config.EscForceEnglish := !Config.EscForceEnglish
        Config.Save()
        this.Refresh()
    }

    static _ToggleToast() {
        Config.ToastEnabled := !Config.ToastEnabled
        Config.Save()
        this.Refresh()
    }

    static _ToggleStartup() {
        Config.RunAtStartup := !Config.RunAtStartup
        Config.Save()
        Startup.Apply(Config.RunAtStartup)
        this.Refresh()
    }

    ; ── 유틸 ──────────────────────────────────────────────────────────────────
    static _SetCheck(menu, item, state) {
        if state
            menu.Check(item)
        else
            menu.Uncheck(item)
    }
}
