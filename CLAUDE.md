# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ImEGuard** — AutoHotkey v2 기반 프로젝트. VSCode + Claude Code 환경에서 개발.

## Development Environment

- **언어**: AutoHotkey v2 (`.ahk`)
- **에디터**: VSCode
- **버전 관리**: GitLab (`git@gitlab.com:myprojects0824/imeguard.git`)

## Running / Testing

```bash
# 스크립트 실행 (AutoHotkey v2 설치 필요)
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" Main.ahk
```

스크립트를 더블클릭하거나 AutoHotkey v2로 직접 실행합니다.

## Code Architecture

코드베이스가 성장하면 주요 구조를 여기에 문서화하세요.

## AHK v2 Conventions

- 함수명: `PascalCase`
- 변수명: `camelCase`
- 클래스명: `PascalCase`
- `#Requires AutoHotkey v2.0` 을 모든 주 스크립트 상단에 선언
- `#SingleInstance Force` 를 일반적으로 Main 스크립트에 포함
