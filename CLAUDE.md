# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**IMEGuard** — Windows 환경 한/영 IME 불편함을 해소하는 AutoHotkey v2 트레이 유틸리티.
- ESC 키 입력 시 IME를 영문으로 자동 전환
- 한/영 전환 시 토스트 팝업으로 현재 상태 표시
- 터미널(Windows Terminal / WSL2 / PowerShell / Warp) IME 포커스 오류 복구

## Development Environment

- **언어**: AutoHotkey v2 (`.ahk`)
- **에디터**: VSCode + AHK v2 Language Support 확장
- **버전 관리**: GitLab (`git@gitlab.com:myprojects0824/imeguard.git`)

## Running

```bash
# AHK v2 설치 경로 기준으로 직접 실행
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" src\IMEGuard.ahk

# 또는 src\IMEGuard.ahk 파일을 더블클릭
```

## Building (EXE 컴파일)

```bash
# Ahk2Exe 사용 (AutoHotkey 설치 시 포함)
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in src\IMEGuard.ahk /out build\IMEGuard.exe
```

컴파일 결과물은 `build/` 폴더에 생성 (gitignore 처리됨).

## Project Structure

```
src/
├── IMEGuard.ahk   ← 진입점: #Include 및 핫키 정의
├── Config.ahk     ← 설정 로드/저장 (%AppData%\IMEGuard\IMEGuard.ini)
├── ImeHelper.ahk  ← IME API DllCall 래퍼, 포커스 복구 로직
├── Toast.ahk      ← 토스트 팝업 GUI (페이드 인/아웃, 다중 모니터 대응)
├── Tray.ahk       ← 시스템 트레이 메뉴 빌드 및 토글 핸들러
└── Startup.ahk    ← 레지스트리 시작 프로그램 등록/해제
```

## Architecture Notes

- **Config**: 모든 설정은 `%AppData%\IMEGuard\IMEGuard.ini`에 저장. EXE 위치 무관.
- **ImeHelper**: `ImmGetContext` / `ImmGetOpenStatus` / `ImmSetOpenStatus` DllCall로 IME 직접 제어. 터미널은 최상위 HWND가 아닌 `GetGUIThreadInfo`로 얻은 포커스 컨트롤 HWND를 사용해야 정확함.
- **Toast**: `WS_EX_LAYERED + WS_EX_TRANSPARENT`로 반투명 + 클릭 통과. `ObjBindMethod`로 페이드아웃 타이머 바인딩.
- **IME 포커스 복구**: 오프스크린 더미 GUI로 포커스를 잠깐 가져와 한글 IME 강제 활성화 후 원래 창 복귀.

## AHK v2 Conventions

- 함수명 / 클래스명: `PascalCase`
- 변수명: `camelCase`
- 모든 파일 상단에 `#Requires AutoHotkey v2.0` 선언
- `#SingleInstance Force`는 `IMEGuard.ahk`(진입점)에만 선언
