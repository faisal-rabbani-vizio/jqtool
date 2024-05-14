include "common";

def promo:
.campaign |
{
  background: .images[].uri,
  "partner-logo": "",
  status: .status,
  "promo-header": (reduce .headings[] as $head (""; . += " " + $head.value)),
  "promo-body": .body[].value,
  "promo-legal": .legalText[].value,
  "promo-qr-code":.promotionQrCode,
  "promo-display-code":.promotionCode,
  "promo-display-url":.promotionEndpoint
};
