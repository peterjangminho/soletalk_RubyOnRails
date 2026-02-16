# Asset & Icon Parity Gap Analysis: Project_B vs Project_A

**Status**: [Done]
**Created**: 2026-02-16
**Related**: `20260216_01_particle_sphere_ui_parity_master_plan.md`

---

## Gap Analysis Summary

| # | 항목 | Project_B | Project_A (이전) | Project_A (완료) | 심각도 |
|---|------|-----------|-----------------|-----------------|--------|
| 1 | PWA Manifest 색상 | N/A | `theme_color: "red"` placeholder | `#21203A` / `#1A1A2E` | Critical |
| 2 | Favicon SVG | 로고 벡터 드로어블 | 빨간 원 placeholder | 마이크 아이콘 + 브랜드 그라디언트 | Critical |
| 3 | Google OAuth 버튼 아이콘 | 멀티컬러 G SVG (LoginPage.tsx) | 텍스트만 | Google G SVG + i18n 텍스트 | Medium |
| 4 | 내비게이션 아이콘 | Lucide (Cog, FileText, ArrowLeft 등 15개) | 텍스트만 | Lucide SVG inline (icon partial) | Medium |
| 5 | Loading Spinner | SVG + role="status" + animate-spin | 없음 | spinner partial + CSS animation | Medium |
| 6 | Android colors.xml | 14 색상 (브랜드 팔레트 전체) | 없음 | 16 색상 (Project_B 동일 + brand_cyan/green 추가) | Medium |
| 7 | Android themes.xml | Material Components 확장 (8 항목) | 빈 스타일 1줄 | Project_B 동일 (colors 참조) | Medium |
| 8 | Android Drawable | ic_launcher_foreground + ic_notification | 없음 | 동일 XML 벡터 드로어블 복사 | Medium |
| 9 | Android Mipmap Icons | 5밀도 × 2변형 = 10 PNG | 없음 | Project_B에서 복사 (10 PNG) | Medium |
| 10 | Meta theme-color | N/A (네이티브 앱) | 없음 | `#21203A` + apple status bar | Low |
| 11 | Quicksand 300 weight | 300,400,500 | 400,500,600,700 | 300,400,500,600,700 | Low |
| 12 | Google 버튼 i18n | N/A (단일 언어) | 하드코딩 "Continue with Google" | `t("home.sign_in.cta")` | Low |

## 파일 변경 내역

### 신규 파일
| 파일 | 내용 |
|------|------|
| `app/views/shared/_icon.html.erb` | Lucide 아이콘 공유 partial (15종) |
| `app/views/shared/_google_icon.html.erb` | Google G 멀티컬러 SVG |
| `app/views/shared/_spinner.html.erb` | 접근성 지원 로딩 스피너 |
| `mobile/android/.../values/colors.xml` | Android 브랜드 색상 팔레트 |
| `mobile/android/.../drawable/ic_launcher_foreground.xml` | 앱 아이콘 전경 벡터 |
| `mobile/android/.../drawable/ic_notification.xml` | 알림 마이크 아이콘 벡터 |
| `mobile/android/.../mipmap-*/ic_launcher*.png` | 5밀도 런처 아이콘 (10 PNG) |

### 수정 파일
| 파일 | 변경 내용 |
|------|-----------|
| `app/assets/stylesheets/application.css` | icon/spinner/nav-icon/btn-google CSS, Quicksand 300 추가 |
| `app/views/home/index.html.erb` | Google 버튼에 SVG 아이콘 추가, i18n 적용 |
| `app/views/shared/_top_nav.html.erb` | 내비 링크에 Lucide 아이콘 추가 |
| `app/views/settings/show.html.erb` | Back 버튼에 arrow-left 아이콘 |
| `app/views/insights/index.html.erb` | Back 버튼에 arrow-left 아이콘 |
| `app/views/subscription/show.html.erb` | Back 버튼에 arrow-left 아이콘 |
| `app/views/layouts/application.html.erb` | meta theme-color, apple status bar |
| `app/views/pwa/manifest.json.erb` | 색상 수정, SVG 아이콘 추가, 이름/설명 업데이트 |
| `public/icon.svg` | 빨간 원 → 마이크 아이콘 + 브랜드 그라디언트 |
| `mobile/android/.../values/themes.xml` | Material Components 색상 참조 확장 |

## 아이콘 시스템 설계

### 공유 partial 패턴
```erb
<%# 사용법 %>
<%= render "shared/icon", name: "cog", size: 18 %>
<%= render "shared/google_icon" %>
<%= render "shared/spinner", size: 16 %>
```

### 지원 아이콘 목록 (Lucide 기반)
| 아이콘 | 이름 | 사용처 |
|--------|------|--------|
| Mic | `mic` | 마이크 버튼 (Phase 3에서 직접 사용) |
| MicOff | `mic-off` | 음소거 상태 |
| ArrowLeft | `arrow-left` | 뒤로가기 버튼 |
| Cog | `cog` | 설정 내비게이션 |
| FileText | `file-text` | 세션 내비게이션 |
| LogOut | `log-out` | 로그인 링크 |
| Link | `link` | 인사이트 내비게이션 |
| Download | `download` | 다운로드 |
| Trash | `trash` | 삭제 |
| ShieldAlert | `shield-alert` | 보안 경고 |
| UploadCloud | `upload-cloud` | 파일 업로드 |
| X | `x` | 닫기/제거 |
| ExternalLink | `external-link` | 외부 링크 |
| Square | `square` | 정지 버튼 |

### 접근성
- 모든 아이콘: `aria-hidden="true"` (장식용)
- 스피너: `role="status"` + `aria-label="Loading"`
- 아이콘 버튼: 부모에 `aria-label` 제공

## 테스트 결과
- JS 테스트: 77/77 통과
- Rails 테스트: 109/109 통과
- i18n 테스트: Google 버튼 한국어 번역 확인 (3/3)
