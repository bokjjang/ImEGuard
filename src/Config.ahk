#Requires AutoHotkey v2.0

class Config {
    static _dir := A_AppData . "\IMEGuard"
    static IniPath := A_AppData . "\IMEGuard\IMEGuard.ini"

    ; ── Defaults ──────────────────────────────────────────────────────────────
    static EscForceEnglish := true
    static ToastEnabled := true
    static RunAtStartup := false
    static ToastDisplaySeconds := 1.5

    static Load() {
        DirCreate(this._dir)
        this.EscForceEnglish := IniRead(this.IniPath, "Features", "EscForceEnglish", 1) = "1"
        this.ToastEnabled := IniRead(this.IniPath, "Features", "ToastEnabled", 1) = "1"
        this.RunAtStartup := IniRead(this.IniPath, "System", "RunAtStartup", 0) = "1"
        this.ToastDisplaySeconds := Float(IniRead(this.IniPath, "Toast", "DisplaySeconds", 1.5))
    }

    static Save() {
        DirCreate(this._dir)
        IniWrite(this.EscForceEnglish ? 1 : 0, this.IniPath, "Features", "EscForceEnglish")
        IniWrite(this.ToastEnabled ? 1 : 0, this.IniPath, "Features", "ToastEnabled")
        IniWrite(this.RunAtStartup ? 1 : 0, this.IniPath, "System", "RunAtStartup")
        IniWrite(this.ToastDisplaySeconds, this.IniPath, "Toast", "DisplaySeconds")
    }

    static OpenInNotepad() {
        if !FileExist(this.IniPath)
            this.Save()
        Run('notepad.exe "' . this.IniPath . '"')
    }
}