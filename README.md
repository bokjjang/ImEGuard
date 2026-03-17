# IMEGuard

Windows 환경에서 한/영 IME 불편함을 해소하는 AutoHotkey v2 트레이 유틸리티.

## 주요 기능

| 기능 | 설명 |
|------|------|
| **ESC 영문 고정** | ESC 키 입력 시 한글 → 영문 자동 전환. Vim, 터미널 등에서 유용 |
| **IME 상태 토스트** | 한/영 전환 시 현재 상태를 화면에 1.5초간 표시 |
| **IME 포커스 복구** | 터미널에서 한글 입력이 안 될 때 트레이 클릭 한 번으로 복구 |
| **시작 프로그램 등록** | Windows 시작 시 자동 실행 등록/해제 |

## 지원 터미널

Windows Terminal / WSL2 / PowerShell / Warp

## 다운로드 및 실행

1. [Releases](https://gitlab.com/myprojects0824/imeguard/-/releases) 에서 `IMEGuard.exe` 다운로드
2. 원하는 폴더에 저장 후 더블클릭 실행
3. AutoHotkey 설치 불필요 (단일 EXE)
4. 최초 실행 시 시작 프로그램 등록 여부 선택

## 트레이 메뉴

시스템 트레이 아이콘 우클릭:

```
IME 포커스 복구        ← 터미널 한글 입력 불가 시 클릭
────────────────────
✅ ESC 영문 고정       ← ON/OFF 토글
✅ 토스트 표시         ← ON/OFF 토글
────────────────────
✅ 시작시 자동 실행    ← ON/OFF 토글
────────────────────
설정...               ← IMEGuard.ini를 메모장으로 열기
────────────────────
종료
```

## 설정 파일

`%AppData%\IMEGuard\IMEGuard.ini`

```ini
[Features]
EscForceEnglish=1
ToastEnabled=1

[Toast]
DisplaySeconds=1.5

[System]
RunAtStartup=1
```

## 직접 빌드

**스크립트 실행** (AutoHotkey v2 필요)
```
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" src\IMEGuard.ahk
```

**EXE 컴파일**
```
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" ^
  /in src\IMEGuard.ahk ^
  /out build\IMEGuard.exe ^
  /icon assets\IMEGuard.ico ^
  /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
```

**아이콘 재생성**
```
powershell -ExecutionPolicy Bypass -File assets\make_icon.ps1
```

## 요구사항

- Windows 10 / 11
- 스크립트 실행 시: AutoHotkey v2
- EXE 실행 시: 별도 설치 불필요

## 프로젝트 구조

```
src/
├── IMEGuard.ahk   ← 진입점 (핫키 정의)
├── Config.ahk     ← 설정 로드/저장
├── ImeHelper.ahk  ← IME API 제어 및 포커스 복구
├── Toast.ahk      ← 토스트 팝업 GUI
├── Tray.ahk       ← 시스템 트레이 메뉴
└── Startup.ahk    ← 시작 프로그램 등록
assets/
├── IMEGuard.ico   ← 트레이/EXE 아이콘
└── make_icon.ps1  ← 아이콘 생성 스크립트
build/             ← 컴파일된 EXE 출력 (gitignore)
```
