def getYear:
  . | strptime("%M/%d/%Y") | mktime | strftime("%Y");

def metadata(f):
  .metadata | map(select(.key == f))[0].value;

def duration:
  .
  | ((. / 60) % 60) as $m
  | ((. / 3600) % 1000) as $h
  | if $h > 0 then "\($h)h " else "" end + "\($m)m";

def meta:
  [
   (. | metadata("release_date") | if . == null then null else . | getYear end),
   (. | metadata("production_rating")),
   (. | metadata("duration_in_seconds") | if . == null then null else . | tonumber | duration end )
  ]
  | del(..|nulls)
  | map(select(length > 0))
  | join("  •  ");

def superMeta:
. | (.subTitle // (. | meta | if . == "" then null else . end) // "");

