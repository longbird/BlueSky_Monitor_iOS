# SysManager 모니터링 기능 분리 iOS 앱

아래 문서는 **SysManager의 모니터링 기능만 iOS 앱으로 분리**하기 위한 **API 설계안**과 **단계별 실행 계획**입니다.

---

# ✅ API 설계안 (모니터링 전용)

## 0) 공통
- Base URL: `https://your-api.domain/api/v1`
- 인증: `Authorization: Bearer <token>` (기존 방식 사용)

---

## 1) 모니터링 요약 목록 (메인 리스트)
**GET** `/monitor/summary`

**Query**
- `centerId` (optional): 센터 필터
- `status` (optional): good|normal|bad|offline|unused
- `page`, `limit` (optional)

**Response**
```json
{
  "timestamp": "2026-02-26T02:10:00Z",
  "items": [
    {
      "centerId": "01",
      "centerName": "서울센터",
      "connect": true,
      "sysCpu": 12.3,
      "sysMem": 45.8,
      "storageUsedPercent": 71.2,
      "netRxBytes": 123456789,
      "netTxBytes": 987654321,
      "ipPbxIp": "10.0.0.12",
      "status": "good"
    }
  ]
}
```

**데이터 소스**
- DB SP: `dbo.sys_monitor_s_1`
- 필드 매핑:  
  `sys_cpu`, `sys_mem`, `storage_usedpercent`, `network_rx_bytes`, `network_tx_bytes`, `ip_pbx_ip`, `call_center_cd`, `call_center_nm`, `call_center_connect`

---

## 2) 모니터링 상세 (더블클릭 상세 화면 대응)
**GET** `/monitor/detail`

**Query**
- `centerId` (required)

**Response**
```json
{
  "centerId": "01",
  "centerName": "서울센터",
  "servers": [
    {
      "serverId": "cmd",
      "host": "10.0.0.10",
      "port": 1234,
      "status": "ok",
      "cpu": 15.1,
      "mem": 62.3,
      "disk": 80.4,
      "rxBps": 123456,
      "txBps": 654321,
      "lastUpdated": "2026-02-26T02:10:00Z"
    }
  ]
}
```

**데이터 소스**
- DB + 기존 소켓 통신 결과 (CMD/DB 서버 상태)

---

## 3) 서버 상태 체크 (수동 갱신용)
**POST** `/monitor/ping`

**Body**
```json
{ "host": "10.0.0.10", "port": 1234, "type": "cmd" }
```

**Response**
```json
{ "status": "ok", "latencyMs": 42 }
```

---

## 4) 모니터링 차트 데이터
**GET** `/monitor/chart`

**Query**
- `centerId`
- `metric` = cpu|mem|disk|rx|tx
- `range` = 1h|6h|24h|7d

**Response**
```json
{
  "metric": "cpu",
  "points": [
    { "t": "2026-02-26T01:00:00Z", "v": 12.3 },
    { "t": "2026-02-26T01:05:00Z", "v": 15.1 }
  ]
}
```

---

## 5) 서버 목록/설정 (관리 메뉴 대응)
**GET** `/monitor/servers`

```json
[
  { "centerId": "01", "host": "10.0.0.10", "port": 1234, "type": "cmd" }
]
```

---

# ✅ 단계별 실행 계획서

## 1단계: 기존 모니터링 구조 파악
- SP 사용: `dbo.sys_monitor_s_1`
- 소켓 통신: CMD/DB 서버 상태 체크
- 사용되는 포트/프로토콜 확인

✅ Output: “데이터 정의서 (필드 목록 + 의미)”

---

## 2단계: REST API 구현
- `/monitor/summary` 구현
- `/monitor/detail` 구현
- `/monitor/chart` (필요 시)
- `/monitor/ping` (소켓 대체 API)

✅ Output: Swagger/OpenAPI 문서

---

## 3단계: iOS 앱 MVP
- 목록 화면
- 상세 화면
- 상태 필터
- 자동 갱신 (30~60초)

✅ Output: SwiftUI 기반 1차 앱

---

## 4단계: 성능/보안
- 인증 토큰 만료 처리
- 서버 상태 캐시 (5~10초)
- API Rate Limit 적용

---

## 5단계: UI 마감
- 상태 색상/아이콘
- 차트/그래프
- 알림 (offline 감지 시 Push)

---

# ✅ 추가 확인 필요 사항
1) 기존 REST 서버 인증 방식? (JWT/세션/API키)
2) DB 접근은 API 서버가 직접 가능한가?
3) 소켓 프로토콜을 서버에서 재구현할 수 있는지?
4) 실제 모니터링 화면의 모든 항목이 필요한지?

---

원하면 위 설계안을 **OpenAPI 스펙**으로 변환해드릴 수 있습니다.
