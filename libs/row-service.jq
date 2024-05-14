include "common";
include "metadata";

def row:
. |
INDEX(.items[]; .id) as $items |
(.rows[].imagePresentation | rowType) as $rowKey |
($rowKey | tileSize) as $tileSize | .rows[].id as $rowId |

    {
      name: .rows[].title,
      sectionName:.rows[].title,
      size: $rowKey,
      tiles: $items |
      map({ name: (.title // ""),
          action: . | action,
          image: .imagePath | image($tileSize),
          meta: . | superMeta,
          watchlistId: .action.info.id,
          analytic: getAnalyticData($rowId),
          options: . | starKeyOptions,
          analyticsType: .analyticsType
      })
    }

  ;
