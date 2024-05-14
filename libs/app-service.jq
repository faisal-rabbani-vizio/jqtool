include "common";

def rowKey:
  if . == "AppCatalog" then
    "apps"
  else
    "tiles"
  end;

def app:
.appDetails[]
| .id as $contentId
| INDEX(.supplementaryItems[]; .id) as $items
| {
  analyticPage:"app-details",
  heros: [{
    title: .title,
    logo: . | heroLogo,
    background: .keyArtImagePath | imageNoModify,
    meta: [(.genres | join("/")), .rating, (.pricing | join("/"))] | del(..|select(. =="")) | join("  •  "),
    blurb: .description,
    features: .capabilityImageUrls | map({image: . | image({w: 140, h: 20})}),
    appDetails: true,
    analytic: {
      metadata: {
        content_id: $contentId,
      },
      sectionName: .title,
    },
    ctas: [
      {
        text: .action.text,
        action: . | action,
      },
      {
        text: "HOMESCREEN",
        action: {
          homescreen: . | appId,
          secondary_action: . | action ,
        },
      }
    ],
  }],
  tabs: [
    {
      rows: .supplementaryRows
      | map(
        select(.items | length > 0)
        | (.imagePresentation | rowType) as $rowType
        | ($rowType | tileSize) as $tileSize
        | (.imagePresentation | rowKey) as $rowKey
        | {
          name: (.title // ""),
          sectionName: (.title),
          size: $rowType,
          $rowKey: .items | map($items[.|tostring]
          | {
              name: (.title // ""),
              action: . | action,
              image: .imagePath | image($tileSize),
              description: ((. | metadata("description")) // ""),
              app: (if .badgePath then .badgePath | image({w: 70, h: 26}) else null end),
              "impression-tracking": .impressionTrackingUrls | map({url: .}),
              "focus-tracking": .focusTrackingUrls | map({url: .}),
              "click-tracking": .clickTrackingUrls | map({url: .}),
              "analytic": getAnalyticData(null)
            }
          ),
          screenshots: .items | map($items[.|tostring]
          | .action
          | select(.type == "Image")
          | .info.MESSAGE
          | image({w: 1536, h: 864})
          )
        }
      ),
      analyticPos: {rowPosition: 2},
    }
  ]
};
