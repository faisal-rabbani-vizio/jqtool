include "common";

def htmldecode:
  def unhex:
    if 48 <= . and . <= 57 then . - 48 elif 65 <= . and . <= 70 then . - 55 else . - 87 end;

  def bytes:
    def loop($i):
      if $i >= length then empty else 10 * (.[$i+2] | unhex) + (.[$i+3] | unhex), loop($i+5) end;
    [loop(0)];

  def codepoints:
    def loop($i):
      if $i >= length then empty
      elif .[$i] >= 240 then (.[$i+3]-128) + 64*(.[$i+2]-128) + 4096*(.[$i+1]-128) + 262144*(.[$i]-240), loop($i+4)
      elif .[$i] >= 224 then (.[$i+2]-128) + 64*(.[$i+1]-128) + 4096*(.[$i]-224), loop($i+3)
      elif .[$i] >= 192 then (.[$i+1]-128) + 64*(.[$i]-192), loop($i+2)
      else .[$i], loop($i+1)
      end;
    [loop(0)];

  gsub("(?<m>(?:&#[0-9a-fA-F]{2};)+)"; .m | explode | bytes | codepoints | implode) | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&apos;"; "'") | gsub("&quot;"; "\"") | gsub("&amp;"; "&")
;

def searchYT2024($isVoice):
  .shelves[0].nextPageToken as $token 
  | {
      rows: [
        {
          layout: "carousel",
          name: "YouTube",
          size: "16x9_small",
          tiles: (.shelves[0].shelfItems 
            | map({
                name: .title,
                app:"", 
                image: ( .images | first(.[] | select(.resolution == "mq") | .uri) // null),
                analytic: {
                  metadata: {
                    itemTitle: (.title )
                  }
                },
                action: {
                launch: {
                  id:"1",
                  ns:"5",
                  url: (if ($isVoice == false) then  
                    ("https://www.youtube.com/tv?v=" + .uriParameters.v + "&launch=search") 
                  else 
                    ("https://www.youtube.com/tv?v=" + .uriParameters.v + "&launch=search&launch_tag=voice&vs=0")
                  end)
                }
              }
             }
             ) +
          if $token then [{
            "view-more-yt":true,
             action: {
               youtube:true
             }
          }] else empty end
             )

      }
    ]
  }
;
