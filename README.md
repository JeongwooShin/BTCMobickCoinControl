# goodmorningpharmacy.runbickers.com

굿모닝약국 공식 안내용 정적 페이지입니다.

## GitHub Pages 배포

1. GitHub에 별도 공개 저장소 `goodmorningpharmacy.runbickers.com`을 만듭니다.
2. 이 폴더 안의 `index.html`과 `CNAME`을 저장소 최상단에 올립니다.
3. **Settings → Pages → Deploy from a branch → main / (root)** 를 선택합니다.
4. Pages의 Custom domain에 `goodmorningpharmacy.runbickers.com`을 입력하고 저장합니다.
5. Cloudflare DNS에서 다음 CNAME을 추가합니다.

| Type | Name | Target | Proxy | TTL |
| --- | --- | --- | --- | --- |
| CNAME | `goodmorningpharmacy` | `jeongwooshin.github.io` | DNS only | Auto |

GitHub Pages의 HTTPS 인증서가 발급된 뒤에만 Cloudflare Proxy를 켤 수 있습니다. 이 페이지는 DNS only로 두는 것이 가장 단순합니다.
