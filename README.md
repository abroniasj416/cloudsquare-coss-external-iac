# cloudsquare-coss-external-iac

Naver Cloud Platform(NCP) 기반 External 시스템 IaC입니다.

## 목표

- `terraform -chdir=external init/plan/apply`로 External 인프라를 구성
- External UI/API 데모 서버를 Private Subnet에 배포
- Public ALB는 external-web(80) 타겟을 사용하며, HTTP(80)/HTTPS(443) 리스너를 구성
- `/api/*` 경로는 ALB 리스너 규칙이 아니라 external-web nginx 리버스 프록시로 private API 서버(8080)로 전달
- External VPC와 기존 COSS VPC 간 Peering 연결

## 고정값

- Region/Zone: `kr-1` / `KR-1`
- Rocky 이미지 번호: `107029409`
- COSS VPC No: `133450`
- COSS VPC CIDR: `10.0.0.0/16`
- External VPC CIDR: `10.10.0.0/16`
- Public Subnet: `10.10.1.0/24`
- Private Subnet: `10.10.2.0/24`

## 생성 리소스

- External VPC
- Network ACL
- Public/Private Subnet
- Public/Private Route Table
- NAT Gateway + Private 기본 경로(0.0.0.0/0)
- VPC Peering(External <-> COSS)
- ACG(ALB/WEB/API)
- Private 서버 2대
  - external-web-svr01
  - external-api-svr01
- Network Interface 2개(web/api)
- Init Script 2개(web/api)
- ALB + Web Target Group + Listener
- ALB HTTPS Listener(인증서 번호 변수 `alb_ssl_certificate_no`)
- HTTP 요청은 nginx에서 `X-Forwarded-Proto` 기반으로 HTTPS(301) 리다이렉트
- init script 기반 Docker 컨테이너 배포
  - Web: nginx 정적 페이지 + `/api/` 리버스 프록시
  - API: Node.js 단일 서버(`/api/health`, `/api/certificates`)

## 주의사항

- 일부 NCP Terraform 리소스/속성명은 provider 버전에 따라 다를 수 있습니다.
- 코드 내 `provider 문서 확인 필요` 주석이 있는 항목은 실제 사용 provider 버전에서 필드명을 확인해 주세요.
- External API의 `/api/certificates`는 `coss_api_base_url`이 비어 있으면 더미 JSON을 반환합니다.

## 변수 파일 준비

`env/terraform.tfvars.example`를 복사해 `env/terraform.tfvars`를 만든 뒤 값을 입력하세요.

TLS 적용 시 `alb_ssl_certificate_no`에 Certificate Manager 인증서 번호를 입력하세요.

## 실행

```bash
terraform -chdir=external init
terraform -chdir=external plan -var-file=../env/terraform.tfvars
terraform -chdir=external apply -var-file=../env/terraform.tfvars
```
