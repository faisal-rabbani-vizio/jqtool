include "common";
include "metadata";

def metadataImage($field):
  . | metadata($field) as $id |
  if $id then
    "https://images.vizio.com/v4/btv/1/\($id)/1/770/220/0.jpg"
  else
    null
  end
;

def catalogHero($rowId):
  {
    title: .title,
    app: (if .badgePath then .badgePath | imageNoModify else null end),
    background: (
      (.keyArtImagePath | imageNoModify) //
      (.imagePath | image({w:992, h:558})) # Fallback
    ),
    logo: . | heroLogo,
    blurb: (if .titleArtPromoImagePath then null else (. | metadata("description")) end),
    "impression-tracking": .impressionTrackingUrls | map({url: .}),
    "focus-tracking": .focusTrackingUrls | map({url: .}),
    "click-tracking": .clickTrackingUrls | map({url: .}),
    "analytic": getAnalyticData($rowId),
    preview: . | metadata("heroVideo"),
    "expand-preview": (if (. | metadata("row_type")) == "LargerSwimlanePortrait" then true else false end),
    ctas: [
      {
        text: .subTitle,  # TODO strip
        action: . | carouselAction,
        options: . | starKeyOptions,
        analyticsType: .analyticsType,
      }
    ]
  } | del(..|nulls);


def discoverHero:
  . | metadata("description") as $blurb |
  {
    title: .title,
    background: (
      (.keyArtImagePath | imageNoModify) //
      (.imagePath | image({w:992, h:558})) # Fallback
    ),
    logo: . | heroLogo,
    # Discover heros *do not* have "app"s
    blurb: (if .titleArtPromoImagePath then null else $blurb end),
    preview: . | metadata("heroVideo"),
    "expand-preview": (if (. | metadata("row_type")) == "LargerSwimlanePortrait" then true else false end),
    meta: (if .titleArtPromoImagePath then null else (. | metadata("cast")) end),
    "analytic": getAnalyticData(null),
    scores: [
      {
        icon: ((. | formattedMetadata("rotten_tomatoes_image_url"; "https://images.vizio.com\(.)"))|tostring),
        score: (. | formattedMetadata("rotten_tomatoes_score"; "\(.)%"))
      },
      {
        icon: "common-sense-media.astc",
        score: (. | formattedMetadata("common_sense_media_rating"; "Age \(.)+"))
      }
    ] | map(select(.score))
  } | del(..|nulls);

def backsplash($title; $sectionName):
  {
    title: $title,
    sectionName:$sectionName,
    background: (
      (.keyArtImagePath | imageNoModify) //
      (.imagePath | image({w:992, h:558})) # Fallback
    ),
    contentTitle: (.title // ""),
    partner: (. | metadata("partner") // ""),
    logo: . | heroLogo,
    "impression-tracking": .impressionTrackingUrls | map({url: .}),
    "focus-tracking": .focusTrackingUrls | map({url: .}),
    "click-tracking": .clickTrackingUrls | map({url: .}),
    "analytic": getAnalyticData(null),
    preview: . | metadata("heroVideo"),
    "expand-preview": (if (. | metadata("row_type")) == "LargerSwimlanePortrait" then true else false end),
    cta: (if ((.subTitle // "") != "") then {
      text: .subTitle | ascii_upcase,  # TODO strip
      action: . | action
    } else null end),
  } | del(..|nulls);


def hubHeader($title; $sectionName):
  {
    background: (
      (.keyArtImagePath | imageNoModify) //
      (.imagePath | image({w:992, h:558})) # Fallback
    ),
    sectionName:$sectionName,
    "impression-tracking": .impressionTrackingUrls | map({url: .}),
    "focus-tracking": .focusTrackingUrls | map({url: .}),
    "click-tracking": .clickTrackingUrls | map({url: .}),
    "analytic": getAnalyticData(null),
    cta: (if ((.subTitle // "") != "") then {
      text: .subTitle,  # TODO strip
      action: . | action,
    } else null end),
  } | del(..|nulls);


def rowKey:
  if . == "TopTen" then
    "top-10"
  elif . == "AppCatalog" then
    "apps"
  elif . == "AppCatalogGrid" then
    "apps"
  else
    "tiles"
  end;

def rows($rows; $items):
map($rows[.|tostring] | .id as $rowId | .title as $rowTitle |
select(.id != 7216) | # Collections row is moved to browse tab. Filter out until we get new home catalog.
select(.imagePresentation != "FullBleedHero" and .imagePresentation != "Banner" and .imagePresentation != "CategoryTakeover" and .imagePresentation != "CategoryTakeoverSmall" and .imagePresentation != "SecondaryNavigation" and .imagePresentation != "HubBackground") |
select(.items | length > 0 or $rowTitle == "My Watchlist" or $rowTitle == "Movies on My Watchlist" or $rowTitle == "Shows on My Watchlist") |
if (.id == 9 or .imagePresentation == "AppsRow") then
{
  name: (.title // ""),
  sectionName: (.title),
  "homescreen-apps": true,
  "analytic": INDEX(.items[] | $items[.|tostring] | getAnalyticData($rowId) + {
  "impression-tracking": .impressionTrackingUrls | map({url: .}),
  "focus-tracking": .focusTrackingUrls | map({url: .}),
  "click-tracking": .clickTrackingUrls | map({url: .}),
  }; "\(.appInfo.app_namespace)-\(.appInfo.app_id)"),
}
elif (.id == 7555 or .id == 7604 or .id == 7605) then
{
  name: (.title // ""),
  sectionName: (.title),
  size: .imagePresentation | rowType,
  id: .id,
  "watchlist-row": true,
}
elif (.imagePresentation == "AspectRatio1X1NoText") then
(.imagePresentation | rowType | tileSize) as $tileSize |
{
  name: (.title // ""),
  apps: .items | map($items[.|tostring] |
    {
      name: (.title // ""),
      sectionName: (.title),
      action: . | action,
      image: .imagePath | image($tileSize),
      "impression-tracking": .impressionTrackingUrls | map({url: .}),
      "focus-tracking": .focusTrackingUrls | map({url: .}),
      "click-tracking": .clickTrackingUrls | map({url: .}),
      "analytic": getAnalyticData($rowId),
    }
  )
}
else
(.imagePresentation == "Discover") as $isDiscover |
(.imagePresentation | rowKey) as $rowKey |
(.imagePresentation | rowType) as $rowType |
($rowType | tileSize) as $tileSize |
(.title == "Movies on My Watchlist") as $isMoviesWatchlist |
(.title == "Shows on My Watchlist") as $isShowsWatchlist |
{
  name: (.title // ""),
  sectionName: (.title),
  size: $rowType,
  layout: .imagePresentation | layout,
  "show-info": .imagePresentation | layout | showInfo,
  ($rowKey): .items | map($items[.|tostring] |
    if ($isMoviesWatchlist and (. | metadata("item_content_type") != "movie")) then
      # Drop everything except movies for movies watchlist
      empty
    elif ($isShowsWatchlist and (. | metadata("item_content_type") != "show")) then
      # Drop everything except shows for shows watchlist
      empty
    else
      {
        name: (.title // ""),
        action: . | action,
        collection: (.action.type == "Overflow" and (. | metadata("has_badge") == "true")),
        image: .imagePath | image($tileSize),
        meta: . | superMeta,
        description: (( .| metadata("description")) // .subTitle // ""),
        app: (if .badgePath then .badgePath | image({w: 70, h: 26}) else null end),
        preview: (if $isDiscover then null else . | metadata("heroVideo") end),
        "expand-preview": (if (. | metadata("row_type")) == "LargerSwimlanePortrait" then true else false end),
        takeover: (. | metadata("isAppAd") == "true"),
        "view-more": (if . | metadata("item_title") == "view more" then true else false end),
        "impression-tracking": .impressionTrackingUrls | map({url: .}),
        "focus-tracking": .focusTrackingUrls | map({url: .}),
        "click-tracking": .clickTrackingUrls | map({url: .}),
        "analytic": getAnalyticData($rowId),
        options: . | starKeyOptions,
        analyticsType: .analyticsType
      } +
      if $isDiscover then
        {hero: . | discoverHero}
      else
        {}
      end
    end
  )
}
end
);

def page:
(.catalogs[0].title) as $title |
(.catalogs[0].type) as $type |
INDEX(.items[]; .id) as $items |
INDEX(.rows[]; .id) as $rows |
.catalogs as $catalogs |
{
  heros: .catalogs[].rows |
    map($rows[.|tostring] |
    select(.imagePresentation == "FullBleedHero" or .imagePresentation == "Banner") |
    .id as $rowId  |
    .items | map($items[.|tostring] | catalogHero($rowId))
  ) | flatten,

  sectionName: [.catalogs[].rows[] |
    $rows[.|tostring] |
    select(.imagePresentation == "FullBleedHero" or .imagePresentation == "Banner") |
    .title, ""] | .[0],

  title: $title,
  analyticPage: (if $type == "overflow" then ("catalog") elif $title == "App Catalog" then ("apps") else ($title) end),

  "partner-logo": [
    .catalogs[].rows[]
    | $rows[.|tostring]
    | select(.imagePresentation == "CategoryTakeoverSmall")
    | .items[]
    | $items[.|tostring]
    | .imagePath | image({w: 500, h: 34})
    , ""
    ] | .[0],

  backsplash: [
    .catalogs[].rows[]
    | $rows[.|tostring]
    | select(.imagePresentation == "CategoryTakeover")
    | .title as $sectionName
    | .items[]
    | $items[.|tostring]
    | backsplash($title;$sectionName)
    , {}
    ] | .[0],

  "hub-header": [
    .catalogs[].rows[]
    | $rows[.|tostring]
    | select(.imagePresentation == "HubBackground")
    | .title as $sectionName
    | .items[]
    | $items[.|tostring]
    | hubHeader($title;$sectionName)
    , {}
    ] | .[0],

  tabs:
   [
  .catalogs[].rows[]?
  | $rows[.|tostring]
  | .id as $rowId
  | .title as $sectionName
  | select(.imagePresentation == "SecondaryNavigation")
  | .items[]
  | $items[.|tostring]
  | getAnalyticData($rowId) as $analytic
  | {
    name: .title,
    "analytic": getAnalyticData($rowId),
    "tabSectionName":$sectionName,
    "analyticSubgroupData": {
      subGroup: ($analytic | .metadata.item_title),
      subGroupId: ($analytic | .metadata.item_id),
      rowPosition: 3,
      page: (if $type == "overflow" then ("catalog") elif $title == "App Catalog" then ("apps") else ($title) end),
    }
    } +
    if (. | metadata("client_action_override") == "manageHomescreen") then
      { "app-reorder": true }
    elif (. | metadata("client_action_override") == "appSearch") then
      { "app-search": true }
    else
      {"overflow-id":
        (if .action.type == "Overflow" then
          ("c-" + (.action.info.id | tostring))
        elif .action.type == "OverflowRow" then
          ("r-" + (.action.info.id | tostring))
        else null
        end),
      }
    end
  ] | (if (length > 0) then . else
  [
    {
      rows: $catalogs[].rows | rows($rows; $items),
      analyticPos: {
        rowPosition: 2,
        page: (if $type == "overflow" then ("catalog") elif $title == "App Catalog" then ("apps") else ($title) end),
      }
    }
  ] end),
  "all-apps": INDEX(.catalogs[].rows[]
      | select(. == 9)
      | $rows[.|tostring]
      | .items
      | to_entries
      | .[]
      | .key as $key
      | $items[.value|tostring]
      | select(.action.info.APP_ID != null)
      | {
        name: .title,
        id: .action.info.APP_ID,
        cid: .id,
        ns: .action.info.NAME_SPACE,
        url: .action.info.MESSAGE,
        image: .imagePath | imageNoModify,
        index: $key,
        restricted: (try (. | metadata("restricted") | fromjson) catch null),
        maxIndex: (try (. | metadata("maxIndex") | fromjson | tonumber) catch null),
        options: . | starKeyOptions,
        analyticsType: .analyticsType

      } | del(..|nulls)
    ; .cid) | map_values(del(.cid)),

    "all-apps-button": INDEX(.catalogs[].rows[]
      | select(. == 9)
      | $rows[.|tostring]
      | .items
      | to_entries
      | .[]
      | .key as $key
      | $items[.value|tostring]
      | select(.action.info.APP_ID == null)
      | {
        name: .metadata[1].value,
        shortenedName: .metadata[1].value | gsub(" ";""),
        landingPageID: .metadata[0].value
      } | del(..|nulls)
    ; .shortenedName),

    "all-apps-analytics": INDEX(.catalogs[].rows[]
      | select(. == 9)
      | $rows[.|tostring]
      | .id as $rowId
      | .items[] | $items[.|tostring] | getAnalyticData($rowId) + {
        "impression-tracking": .impressionTrackingUrls | map({url: .}),
        "focus-tracking": .focusTrackingUrls | map({url: .}),
        "click-tracking": .clickTrackingUrls | map({url: .}),
        }; "\(.appInfo.app_namespace)-\(.appInfo.app_id)")
};
