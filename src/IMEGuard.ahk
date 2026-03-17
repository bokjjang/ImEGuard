#Requires AutoHotkey v2.0
#SingleInstance Force

; ── 모듈 로드 ─────────────────────────────────────────────────────────────────
#Include Config.ahk
#Include ImeHelper.ahk
#Include Toast.ahk
#Include Startup.ahk
#Include Tray.ahk

; ── 초기화 ────────────────────────────────────────────────────────────────────
Config.Load()
Startup.PromptIfFirstRun()
Tray.Build()

; ── 핫키 ──────────────────────────────────────────────────────────────────────

; ESC → 한글 모드일 때 영문으로 전환 후 ESC 전달
; ~ 접두사: ESC 키 이벤트를 앱으로 그대로 통과시킴
~Esc:: {
    if !Config.EscForceEnglish
        return
    if ImeHelper.ForceEnglish() && Config.ToastEnabled
        Toast.Show(0)   ; 0 = 영문
}

; 한/영 키 → 전환 후 토스트 표시
; vk15 = VK_HANGUL, sc072 = 한국어 키보드 스캔코드 (둘 다 등록)
ShowImeToast(*) {
    if !Config.ToastEnabled || ImeHelper.Suppressing
        return
    Sleep(30)   ; IME 상태 반영 대기
    Toast.Show(ImeHelper.GetStatus())
}
~vk15:: ShowImeToast()
~sc072:: ShowImeToast()