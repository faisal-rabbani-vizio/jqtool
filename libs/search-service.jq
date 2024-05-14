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

def imageNoModify:
  if (. == null) then
    null
  else
    "https://images.vizio.com\(.)"
  end;

def rowKey:
  if . == "TopTen" then
    "top-10"
  else
    "tiles"
  end;

def search:
(.searchResults.title) as $title |
INDEX(.searchResults.items[]; .id) as $items |
{ 
    title: ($title // ""),
    rows: .searchResults.rows |
      map(
      select(.items | length > 0) |
      if (.imagePresentation == "AppsRowSearch") then
      (.imagePresentation | rowType | tileSize) as $tileSize |
      {
        name: (.title // ""),
        apps: .items | map($items[.|tostring] | 
          {
            name: (.title // ""),
            action: . | action,
            image: .imagePath | image($tileSize),
            "analytic": getAnalyticData(null),
            options: . | starKeyOptions,
            analyticsType: .analyticsType
          }
        )
      }
      else
      (.imagePresentation | rowKey) as $rowKey |
      (.imagePresentation | rowType) as $rowType |
      ($rowType | tileSize) as $tileSize |
      {
        name: (.title // ""),
        size: $rowType,
        layout: .imagePresentation | layout,
        "show-info": .imagePresentation | layout | showInfo,
        $rowKey: .items | map($items[.|tostring] | 
          {
            name: (.title // ""),
            action: . | action,
            image: .imagePath | image($tileSize),
            meta: . | superMeta,
            app: (if .badgePath then .badgePath | image({w: 70, h: 26}) else null end),
            "analytic": getAnalyticData(null),
            options: . | starKeyOptions,
            analyticsType: .analyticsType
          }
        )
      }
      end
    )
};

def avodRow:
INDEX(.rows[].items[]; .id) as $items | 
{
  rows:[
    {
      name: "Free on WatchFree+", 
      sectionName: "Free on WatchFree+", 
      size: "2x3_small",
      layout: "carousel",
      tiles: $items | 
      map({
            name: (.title // ""),
            action: {
              launch: {
                id: "145",
                ns: 2,
                url: ("https://wfplusavod.smartcasttv.com/0.0.12/index.html#/details/" + .id + "&autoplay=false")
              }
            }, 
            image: .imagePath,
            "analytic": {
              metadata: {
                itemTitle: (.title // "")
              }
            },
            options: . | starKeyOptions,
            analyticsType: .analyticsType
          })
    }
  ]
} |

  (if (.rows[].tiles | length) > 0 then . else null end)
;
