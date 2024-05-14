def metadata(f):
  .metadata | map(select(.key == f))[0].value;

def formattedMetadata(f; format):
  . | metadata(f) as $v |
  if $v then $v | format else null end;


def image($tileSize): "https://images.vizio.com\(.)";


def imageNoModify:
  if (. == null) then
    null
  elif (. == "") then
    null
  else
    "https://images.vizio.com\(.)"
  end;

def min(b): if . < b then . else b end;

def heroLogo:
  if (.titleArtPromoImagePath // "") != "" then
    {
      url: .titleArtPromoImagePath | imageNoModify,
      w: .titleArtPromoImageWidth | min(770),
      h: .titleArtPromoImageHeight | min(250),
    }
  elif (.titleArtImagePath // "") != "" then
    {
      url: .titleArtImagePath | imageNoModify,
      w: .titleArtImageWidth | min(600),
      h: .titleArtImageHeight | min(130),
    }

  else null end;

def simpleAction:
  if .type == "Overflow" then
    if .info.id == 2337 then
      {nav: "search"}
    else
      {page: ("c-" + (.info.id | tostring))}
    end
  elif .type == "ContentDetails" then
    {page: ("d-" + (.info.id | tostring))}
  elif .type == "AppDetails" then
    {page: ("a-" + (.info.id | tostring))}
  elif .type == "SctvRedirect" then
    {page: ("c-" + (.info.MESSAGE | split("=") | .[1]))}
  elif .type == "CustomizeAppRow" then
    {"app-reorder": true}
  else null end;

def trailerAction($url; $cta):
  {
    trailer: {
      url: $url,
      ctas: (if $cta then [$cta] else [] end),
      "video-tracking": .videoTrackingUrls,
    }
  }
;

def action:
  if .action.type == "AppLaunch" then
    # Save a possible video url
    (try (.action.info.MESSAGE | fromjson | .CAST_MESSAGE.media.contentId) catch "") as $url |
    if (.action.info.MESSAGE |tostring| startswith("http://127.0.0.1:12345/scfs/sctv/main.html#/promo/")) then
      {promo: ltrimstr("http://127.0.0.1:12345/scfs/sctv/main.html#/promo/")}
    elif ($url | endswith(".mp4")) then
      trailerAction($url; null)
    else
      .action | {launch: {url: (.info.MESSAGE // ""), id: .info.APP_ID, ns: .info.NAME_SPACE}}
    end
  elif .action.type == "PlayerLaunch" then
    trailerAction(.action.info.MESSAGE; null)
  elif (.action.info.MESSAGE |tostring| contains("/promo/")) then
    {promo: (.action.info.MESSAGE / "/" | .[-1])}
  elif .action.type == "AddToWatchList" then
    {watchlist:{id: (.action.info.id | tostring), type: .action.info.contentType, method: "PUT", source: "star-key-watchlist"}}
  elif .action.type == "RemoveFromWatchList" then
    {watchlist:{id: (.action.info.id | tostring), type: .action.info.contentType, method: "DELETE", source: "star-key-watchlist"}}
  else .action | simpleAction end
;

def carouselAction:
  metadata("cta_video_url") as $url
  | if $url != null then
    trailerAction($url; {text: metadata("cta_video_label") , action: . | action}) * {trailer: {logo: . | heroLogo}}
  else . | action end;

def detailsAction($cta):
  if .action.type == "PlayerLaunch" then
    trailerAction(.action.info.MESSAGE; $cta)
  else . | action end;

def getAnalyticData(rowId):
  {
    metadata: (
      .metadata
      | map(if .key == "item_data_handle" then {key: .key, value: .value | fromjson} else . end)
      | from_entries
    ),
    appInfo: (
      .action | if .type == "AppLaunch" then {app_id: .info.APP_ID, app_namespace: .info.NAME_SPACE} else {} end
    ),
    row_id: (rowId),
    channel:{"airingsKey":
    (
      .action |
      if .type == "AppLaunch" then
      (if (.info.MESSAGE | type == "string") then
      .info.MESSAGE |
      (if test("watchfreeplus") then match(".*/([^?]+)") |
      .captures[].string else "" end) else "" end) else "" end
    ) }
  };

def tileSize:
  if . == "2x3_small" then
    {w: 250, h:375}
  elif . == "2x3_large" then
    {w: 348, h:522}
  elif . == "16x9_tiny" then
    {w: 114, h:86}
  elif . == "16x9_small" then
    {w: 320, h:180}
  elif . == "16x9_large" then
    {w: 544, h:306}
  elif . == "16x9_xlarge" then
    {w: 848, h:477}
  elif . == "banner_short" then
    {w: 1720, h:200}
  elif . == "banner_tall" then
    {w: 1720, h:360}
  elif . == "3up_banner" then
    {w: 560, h:315}
  else
    {w: 250, h:375}
  end;

# https://github.com/BuddyTV/vizio-services-CatalogService/blob/master/Vizio.Services.Catalog.ItemService/ItemService.cs#L160
def rowType:
  if . == "AspectRatio16X9" then
    "16x9_small"
  elif . == "AspectRatio1X1" then
    "16x9_tiny"
  elif . == "AspectRatio1X1NoText" then
    "16x9_tiny"
  elif . == "AppsRow" then
    "16x9_tiny"
  elif . == "AppCatalog" then
    "16x9_tiny"
  elif . == "AspectRatio16X9TextAlignCenter" then
    "16x9_small"
  elif . ==  "AspectRatio16X9HalfScreenWidth" then
    "16x9_xlarge"
  elif . ==  "AspectRatio16X9ThirdScreenWidth" then
    "16x9_large"
  elif . ==  "AspectRatio16X9Tall" then
    "16x9_large"
  elif . ==  "LandscapeExtraLarge" then
    "16x9_xlarge"
  elif . ==  "LandscapeLarge" then
    "16x9_large"
  elif . == "AspectRatio2X3" then
    "2x3_small"
  elif . == "AspectRatio2X3Tall" then
    "2x3_large"
  elif . == "AspectRatio2X3_Large" then
    "2x3_large"
  elif . == "TopTen" then
    "2x3_large"
  elif . == "LargerSwimlanePortrait" then
    "2x3_large"
  elif . == "Grid16X9Small" then
    "16x9_small"
  elif . == "SingleBannerTall" then
    "banner_tall"
  elif . == "BannerTallTwoUp" then
    "16x9_xlarge"
  elif . == "TwoUpBanner" then
    "16x9_xlarge"
  elif . == "ThreeUpBanner" then
    "3up_banner"
  elif . == "BannerTallThreeUp" then
    "3up_banner"
  elif . == "AspectRatio2X3TextAlignCenter" then
    "2x3_small"
  elif . == "AspectRatio21x5" then
    "banner_tall"
  elif . == "AspectRatio21x5TextAlignCenter" then
    "banner_tall"
  elif . == "BannerFullTall" then
    "banner_tall"
  elif . == "BannerFull" then
    "banner_short"
  elif . == "BannerFullScreenWidth" then
    "banner_short"
  elif . == "BannerHalfScreenWidth" then
    "16x9_large"
  elif . == "BannerThirdScreenWidth" then
    "16x9_large"
  elif . == "Discover" then
    "16x9_small"
  elif . == "AspectRatio16X9_XLarge" then
    "16x9_xlarge"
  elif . == "MediumSquare" then
    "1x1_large"
  elif . == "LandscapeGrid" then
    "16x9_small"
  else "16x9_small" end;


def layout:
  if . == "AspectRatio16X9" then
    "carousel"
  elif . == "AspectRatio1X1" then
    "carousel"
  elif . == "AspectRatio1X1NoText" then
    "carousel"
  elif . == "AppsRow" then
    "carousel"
  elif . == "AppCatalog" then
    "carousel"
  elif . == "AppCatalogGrid" then
    "grid"
  elif . == "AspectRatio16X9TextAlignCenter" then
    "carousel"
  elif . ==  "AspectRatio16X9HalfScreenWidth" then
    "banner"
  elif . ==  "AspectRatio16X9ThirdScreenWidth" then
    "banner"
  elif . ==  "AspectRatio16X9Tall" then
    "carousel"
  elif . ==  "LandscapeExtraLarge" then
    "carousel"
  elif . ==  "LandscapeLarge" then
    "carousel"
  elif . == "AspectRatio2X3" then
    "carousel"
  elif . == "AspectRatio2X3Tall" then
    "carousel"
  elif . == "AspectRatio2X3_Large" then
    "carousel"
  elif . == "TopTen" then
    "carousel"
  elif . == "LargerSwimlanePortrait" then
    "carousel"
  elif . == "Grid16X9Small" then
    "grid"
  elif . == "SingleBannerTall" then
    "banner"
  elif . == "BannerTallTwoUp" then
    "banner"
  elif . == "TwoUpBanner" then
    "banner"
  elif . == "ThreeUpBanner" then
    "banner"
  elif . == "BannerTallThreeUp" then
    "banner"
  elif . == "AspectRatio2X3TextAlignCenter" then
    "carousel"
  elif . == "AspectRatio21x5" then
    "carousel"
  elif . == "AspectRatio21x5TextAlignCenter" then
    "banner"
  elif . == "BannerFullScreenWidth" then
    "carousel"
  elif . == "BannerHalfScreenWidth" then
    "banner"
  elif . == "BannerThirdScreenWidth" then
    "banner"
  elif . == "BannerFullTall" then
    "banner"
  elif . == "BannerFull" then
    "banner"
  elif . == "Discover" then
    "carousel"
  elif . == "AspectRatio16X9_XLarge" then
    "carousel"
  elif . == "LandscapeGrid" then
    "grid"
  else "carousel" end;

def appId: "\(.action.info.NAME_SPACE)-\(.action.info.APP_ID)";

def showInfo:
  if . == "grid" then
    "always"
  else
    "focused"
  end;

def starKeyOptions:
  if .menuActions then
    [ .menuActions.items[] |
        {
          text: .text,
          icon: ("https://images.vizio.com" + .image),
          action: . | action,
          actionType: 
            (if .action.type == "ContentDetails" then
              "contentAggregate"
            elif .action.type == "AppDetails" then
              "appDetails"
            elif .action.type == "AppLaunch" then
              "appLaunch"
            elif .action.type == "AddToWatchList" then
              "manageWatchlist"
            elif .action.type == "RemoveFromWatchList" then
              "manageWatchlist"
            elif .action.type == "CustomizeAppRow" then
              "manageHomeApps"
            else "" end)
        }
    ]
  else [] end;
