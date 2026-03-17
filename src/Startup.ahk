#Requires AutoHotkey v2.0

class Startup {
    static _regKey  := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static _appName := "IMEGuard"

    ; 레지스트리에 시작 프로그램 등록/해제
    static Apply(enable) {
        if enable {
            ; 컴파일된 EXE면 그대로, 스크립트 실행이면 AHK 런타임 경로 포함
            exePath := A_IsCompiled
                ? '"' A_ScriptFullPath '"'
                : '"' A_AhkPath '" "' A_ScriptFullPath '"'
            RegWrite(exePath, "REG_SZ", this._regKey, this._appName)
        } else {
            try RegDelete(this._regKey, this._appName)
        }
    }

    ; 최초 실행 여부 판단 → INI 파일이 없으면 첫 실행으로 간주
    static PromptIfFirstRun() {
        if FileExist(Config.IniPath)
            return

        result := MsgBox(
            "IMEGuard를 Windows 시작 시 자동으로 실행할까요?",
            "IMEGuard 첫 실행",
            "YesNo Icon?"
        )
        Config.RunAtStartup := (result = "Yes")
        Config.Save()
        this.Apply(Config.RunAtStartup)
    }
}
