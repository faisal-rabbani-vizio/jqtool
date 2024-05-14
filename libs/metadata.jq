def getYear:
  . | tostring | strptime("%M/%d/%Y") | mktime | strftime("%Y");

def metadata(f):
  .metadata | map(select(.key == f))[0].value;

def duration:
  .
  | ((. / 60) % 60) as $m
  | ((. / 3600) % 1000) as $h
  | if $h > 0 then "\($h)h " else "" end + "\($m)m";

def meta:
  [
   (. | metadata("release_date")? | getYear),
   (. | metadata("production_rating")),
   (. | metadata("duration_in_seconds")? | tonumber | duration)
  ]
  | del(..|nulls)
  | map(select(length > 0))
  | join("  •  ");

def superMeta:
. | (.subTitle // (. | tostring | if . == "" then null else "????" end) // "");

