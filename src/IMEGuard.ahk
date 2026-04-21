#Requires AutoHotkey v2.0
#SingleInstance Force

; 런타임 에러 다이얼로그 억제 (Return = 에러 무시 후 계속 실행)
OnError((*) => "Return")

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
ImeHelper.InitState()   ; 외부 API 1회 질의로 내부 상태 동기화

; ── 핫키 ──────────────────────────────────────────────────────────────────────

; ESC → 현재 상태와 무관하게 영문으로 고정 (토글 아님)
; ~ 접두사: ESC 키 이벤트를 앱으로 그대로 통과시킴
~Esc:: {
    if !Config.EscForceEnglish
        return
    if ImeHelper.ForceEnglish() && Config.ToastEnabled
        Toast.Show(0)   ; 0 = 영문
}

; 한/영 키 → 내부 상태 토글 후 토스트 표시
; vk15 = VK_HANGUL, sc072 = 한국어 키보드 스캔코드 (둘 다 등록, 디바운스로 중복 방지)
ShowImeToast(*) {
    if ImeHelper.Suppressing
        return
    Sleep(30)   ; IME 상태 반영 대기
    if !ImeHelper.NotifyHangulPressed()
        return  ; 디바운스에 걸림 — 이미 처리된 이벤트
    if !Config.ToastEnabled
        return
    Toast.Show(ImeHelper.GetStatus())
}
~vk15:: ShowImeToast()
~sc072:: ShowImeToast()

; IME 상태 반전: Ctrl+Alt+H
; 시작 시 한글이었는데 _tracked가 영문(0)으로 찍혀 토스트/ESC 동작이 반대일 때 한 번 누르면 복구
^!h:: {
    status := ImeHelper.CorrectState()
    if Config.ToastEnabled
        Toast.Show(status)
}

; 진단 핫키: Ctrl+Alt+F12 → 현재 앱에서 각 IME API 반환값 확인
^!F12:: {
    MsgBox(ImeHelper.DumpDiagnostics(), "IMEGuard Diagnostics", "Iconi")
}
