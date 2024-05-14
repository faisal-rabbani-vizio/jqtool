include "common";
include "metadata";

def addOfferings($offerings;$contentId):
if ($offerings | length) > 0 then
        $offerings | map(
        {
          name: .brand,
          description: .price,
          image: .brandImageUrl | image({w: 114, h:86}),
          action: . | action,
          features: .capabilityImageUrls | map({image: . | image({w: 140, h: 20})}),
          "analytic" : {
            metadata: {
              item_title: .brand,
              page: "details",
              content_id: $contentId,
            }
          }
        })
        else
          []
        end
;

def detail:
.contentDetails[]
| .hasCommonSenseMedia as $hasPGTab
| .hasRottenTomatoes as $hasAboutTab
| .contentType as $contentType
| .adOfferings as $adOfferings
| .offerings as $offerings
| .id as $contentId
| {
  text: "WATCHLIST",
  action: {
    watchlist: {
      value: .inWatchlist,
      id: .id,
      type: $contentType,
      source: "content-detail"
    }
  }
} as $watchListCta
| INDEX(.supplementaryItems[]; .id) as $items
| {
  analyticPage:"details",
  heros: [{
    title: .title,
    background:.keyArtImagePath | imageNoModify,
    logo: . | heroLogo,
    fallback: (if (.keyArtImagePath | length) == 0 then .imageUrl | image({w: 390, h: 590}) else null end),
    "watch-options":( if ($adOfferings | length) > 0 then
        $adOfferings | map(
        {
          ad: true,
          name: .brand,
          description: .price,
          image: .brandImageUrl | image({w: 114, h:86}),
          action: . | action,
          features: .capabilityImageUrls[1:-1] | map({image: . | image({w: 140, h: 20})}),
          "analytic" : {
            metadata: {
              item_title: .brand,
              page: "details",
              content_id: $contentId,
            }
          }
        })
        else
          [] #we will fill in the rest further down.
        end
    ),
    meta: (
            if ($contentType != "Series") then [.releases, .duration, .suitabilityRating, (.genres | join("/"))] | del(..|select(. =="")) | join("  •  ")
            else [.releases, .suitabilityRating, (.genres[:3] | join("/"))] | del(..|select(. =="")) | join("  •  ") end
          ),
    blurb: .description,
    contentDetails: true,
    scores: [
      if .criticRating.criticRatingScore != null and .criticRating.criticRatingScore != "" and .criticRating.criticRatingScore != 0 then
        {
          icon: .criticRating.criticSourceImageUrl | "https://images.vizio.com\(.)",
          score: .criticRating.criticRatingScore,
          "rating-name": "tomatometer"
        }
      else empty end,
      if .commonSenseMedia != null and .commonSenseMedia != "" and .commonSenseMedia != 0 then
        {
          icon: "common-sense-media.astc",
          score: "Age \(.commonSenseMedia)+",
          "rating-name": "common sense media"
        }
      else empty end
    ] | map(select(.score)),
    cast: .cast | map(.fullName) | join(", "),
    director: .crew | map(select(.role == "Director") | .fullName) | join(", "),
    ctas: [$watchListCta],
    analytic: {
      metadata: {
        content_id: $contentId,
      },
      sectionName: .title,
    },
  }],
  tabs: [
    (if $items | length > 0 then
    {
      name: "DISCOVER",
      "analytic" : {
        metadata: {
          item_title: "Discover",
          page: "details",
          content_id: $contentId,
          subGroup: "Discover",
          subGroupId: .id
        }
      },
      analyticPos: {rowPosition: 4,page: "details"},
      rows: .supplementaryRows
      | map(
        select(.items | length > 0)
        | (.imagePresentation | rowType) as $rowType
        | ($rowType | tileSize) as $tileSize
        | .id as $rowId
        | {
          name: (.title // ""),
          sectionName: (.title),
          size: $rowType,
          tiles: .items | map($items[.|tostring]
          | {
              name: (.title // ""),
              id: .id,
              action: . | detailsAction($watchListCta),
              image: .imagePath | image($tileSize),
              meta: . | superMeta,
              preview: .action.info.MESSAGE,
              app: (if .badgePath then .badgePath | image({w: 70, h: 26}) else null end),
              "impression-tracking": .impressionTrackingUrls | map({url: .}),
              "click-tracking": .clickTrackingUrls | map({url: .}),
              "focus-tracking": .focusTrackingUrls | map({url: .}),
              "analytic" : {
                metadata: {
                  item_title: .title,
                  content_id: $contentId,
                  subGroup: "Discover",
                  subGroupId: .id
                },
                row_id: $rowId,
              }
            }
          )
        }
      )
    }
    else null end),
    (if $hasAboutTab then
    {
      name: "ABOUT",
      about: .id,
      "analytic" : {
        metadata: {
          item_title: "About",
          page: "details",
          content_id: $contentId,
          subGroup: "About",
          subGroupId: .id
        }
      }
    }
    else null end),
    (if $hasPGTab then
    {
      name: "PARENTAL GUIDE",
      "parental-guide": .id,
      "analytic" : {
        metadata: {
          item_title: "Parental Guide",
          page: "details",
          content_id: $contentId,
          subGroup: "Parental Guide",
          subGroupId: .id
        }
      }
    }
    else null end)
  ]
}
| .heros[]."watch-options" += addOfferings($offerings; $contentId)
| del(..|nulls);
