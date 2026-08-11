#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

src="$1"
out="$2"

mkdir -p "$out" "$out/blog"
# cat, not cp: store sources are read-only (0444) and we append generated themes below
cat "$src/style.css" > "$out/style.css"
[ -d "$src/assets" ] && cp -r "$src/assets" "$out/assets"

ftr="$src/templates/footer.html"

cm=(cmark-gfm --unsafe -e table -e strikethrough -e autolink -e tasklist)

srcbase="site/blog"
default_desc="madeline's blog, served off a raspberry pi zero 2w running NixOS"
baseurl="https://spellbound.sh"
feed_title="madeline's blog"

# escape title/desc for element text or a double-quoted attribute; RSS keeps raw values for xmlesc
htmlesc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

subst() {
    T="$1" S="$2" D="$3" awk '
    function lrepl(str, from, to,   pos, out) {
        out = ""
        while ((pos = index(str, from)) > 0) {
            out = out substr(str, 1, pos - 1) to
            str = substr(str, pos + length(from))
        }
        return out str
    }
    {
        line = $0
        line = lrepl(line, "@TITLE@", ENVIRON["T"])
        line = lrepl(line, "@SOURCE@", ENVIRON["S"])
        line = lrepl(line, "@DESCRIPTION@", ENVIRON["D"])
        print line
    }' "$4"
}

emit() {
    mkdir -p "$(dirname "$4")"
    subst "$1" "$3" "$5" "$hdr" > "$4"
    cat "$2" >> "$4"
    subst "$1" "$3" "$5" "$ftr" >> "$4"
}

frontmatter() {
    awk -v k="$2" '
        NR==1 && $0=="---" { fm=1; next }
        fm && $0=="---"    { exit }
        fm {
            i = index($0, ":")
            if (i > 0) {
                key = substr($0, 1, i-1); val = substr($0, i+1)
                gsub(/^[ \t]+|[ \t]+$/, "", key)
                gsub(/^[ \t]+|[ \t]+$/, "", val)
                if (key == k) { print val; exit }
            }
        }' "$1"
}

body() {
    awk '
        NR==1 && $0=="---" { fm=1; next }
        fm && $0=="---"    { fm=0; next }
        !fm { print }' "$1"
}

# themes: site/blog/themes is the single source of truth; it drives the css
# palette blocks, the picker options, and (via the rendered buttons) the set of
# themes the switcher will accept. add a theme by adding a row there, nothing else.
themes="$src/themes"

# append one generated palette block per theme to the copied stylesheet
{
    echo
    echo "/* generated from site/blog/themes; edit that file, not this block */"
    awk -F'|' '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        { for (i = 1; i <= NF; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
          pre = (++n == 1) ? ":root,\n" : ""
          printf "%s[data-theme=\"%s\"] {\n", pre, $1
          printf "    --bg: %s;\n    --fg: %s;\n    --muted: %s;\n", $3, $4, $5
          printf "    --accent: %s;\n    --border: %s;\n    --code-bg: %s;\n}\n\n", $6, $7, $8 }
    ' "$themes"
} >> "$out/style.css"

# render the picker options once, then bake them into a working header template
theme_options=$(awk -F'|' '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    { for (i = 1; i <= NF; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      printf "<li><button type=\"button\" data-theme-set=\"%s\"><span class=\"swatch\" style=\"--sw-bg:%s;--sw-ac:%s\"></span>%s</button></li>\n", $1, $3, $6, $1 }
' "$themes")

hdr=$(mktemp)
OPTS="$theme_options" awk '
    function lrepl(str, from, to,   pos, out) {
        while ((pos = index(str, from)) > 0) {
            out = out substr(str, 1, pos - 1) to
            str = substr(str, pos + length(from))
        }
        return out str
    }
    { print lrepl($0, "@THEME_OPTIONS@", ENVIRON["OPTS"]) }
' "$src/templates/header.html" > "$hdr"

for f in "$src"/pages/*.md; do
    slug=$(basename "$f" .md)
    title=$(frontmatter "$f" title); title=${title:-$slug}
    desc=$(frontmatter "$f" description); desc=${desc:-$default_desc}
    etitle=$(printf '%s' "$title" | htmlesc)
    edesc=$(printf '%s' "$desc" | htmlesc)

    pc=$(mktemp)
    body "$f" | "${cm[@]}" > "$pc"

    if [ "$slug" = "index" ]; then
        emit "$etitle" "$pc" "$srcbase/pages/index.md" "$out/index.html" "$edesc"
    else
        emit "$etitle" "$pc" "$srcbase/pages/$slug.md" "$out/$slug/index.html" "$edesc"
    fi
done

items=$(mktemp); : > "$items"
for f in "$src"/posts/*.md; do
    slug=$(basename "$f" .md)
    title=$(frontmatter "$f" title); title=${title:-$slug}
    date=$(frontmatter "$f" date)
    desc=$(frontmatter "$f" description); desc=${desc:-$default_desc}
    etitle=$(printf '%s' "$title" | htmlesc)
    edesc=$(printf '%s' "$desc" | htmlesc)

    pc=$(mktemp)
    {
        echo "<article class=\"post\">"
        echo "<h1>$etitle</h1>"
        [ -n "$date" ] && echo "<p class=\"post-date\">$date</p>"
        body "$f" | "${cm[@]}"
        echo "</article>"
        echo "<p class=\"back\"><a href=\"/blog/\">← all posts</a></p>"
    } > "$pc"
    emit "$etitle" "$pc" "$srcbase/posts/$slug.md" "$out/blog/$slug/index.html" "$edesc"

    printf '%s\t%s\t%s\n' "${date:-0000-00-00}" "$title" "$slug" >> "$items"
done

bc=$(mktemp)
{
    echo "<h1>blog</h1>"
    echo "<ul class=\"post-list\">"
    sort -r "$items" | while IFS=$'\t' read -r date title slug; do
        echo "<li><time>$date</time><a href=\"/blog/$slug/\">$(printf '%s' "$title" | htmlesc)</a></li>"
    done
    echo "</ul>"
} > "$bc"
emit "blog" "$bc" "$srcbase/posts" "$out/blog/index.html" "$default_desc"

# ---- RSS 2.0 feed (built from the same date-sorted post list) ----
xmlesc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
# frontmatter dates are YYYY-MM-DD; RSS wants RFC-822. LC_ALL=C keeps day/month names English.
rfc822() { LC_ALL=C date -u -d "$1" +'%a, %d %b %Y %H:%M:%S +0000' 2>/dev/null; }

# lastBuildDate = newest post's date (deterministic; avoids build-time clock churn)
newest=$(sort -r "$items" | sed -n '1p' | cut -f1)
build_date=$(rfc822 "$newest"); build_date=${build_date:-$(rfc822 "1970-01-01")}

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">'
    echo '<channel>'
    printf '<title>%s</title>\n' "$(printf '%s' "$feed_title" | xmlesc)"
    printf '<link>%s/</link>\n' "$baseurl"
    printf '<description>%s</description>\n' "$(printf '%s' "$default_desc" | xmlesc)"
    echo '<language>en</language>'
    printf '<lastBuildDate>%s</lastBuildDate>\n' "$build_date"
    printf '<atom:link href="%s/feed.xml" rel="self" type="application/rss+xml"/>\n' "$baseurl"

    sort -r "$items" | while IFS=$'\t' read -r date title slug; do
        f="$src/posts/$slug.md"
        desc=$(frontmatter "$f" description); desc=${desc:-$default_desc}
        link="$baseurl/blog/$slug/"
        # escape any literal ]]> so it can't close the CDATA section early
        html=$(body "$f" | "${cm[@]}" | sed 's/]]>/]]]]><![CDATA[>/g')
        echo '<item>'
        printf '<title>%s</title>\n' "$(printf '%s' "$title" | xmlesc)"
        printf '<link>%s</link>\n' "$link"
        printf '<guid isPermaLink="true">%s</guid>\n' "$link"
        pd=$(rfc822 "$date"); [ -n "$pd" ] && printf '<pubDate>%s</pubDate>\n' "$pd"
        printf '<description>%s</description>\n' "$(printf '%s' "$desc" | xmlesc)"
        printf '<content:encoded><![CDATA[%s]]></content:encoded>\n' "$html"
        echo '</item>'
    done
    echo '</channel>'
    echo '</rss>'
} > "$out/feed.xml"
