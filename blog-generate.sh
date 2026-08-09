#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

src="$1"
out="$2"

mkdir -p "$out" "$out/blog"
cp "$src/style.css" "$out/style.css"

hdr="$src/templates/header.html"
ftr="$src/templates/footer.html"

cm=(cmark-gfm --unsafe -e table -e strikethrough -e autolink -e tasklist)

srcbase="site/blog"

emit() {
    mkdir -p "$(dirname "$4")"
    awk -v t="$1" -v s="$3" '{ gsub(/@TITLE@/, t); gsub(/@SOURCE@/, s) } 1' "$hdr" > "$4"
    cat "$2" >> "$4"
    awk -v t="$1" -v s="$3" '{ gsub(/@TITLE@/, t); gsub(/@SOURCE@/, s) } 1' "$ftr" >> "$4"
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

tmp=$(mktemp)
title=$(frontmatter "$src/pages/index.md" title); title=${title:-spellbound.sh}
body "$src/pages/index.md" | "${cm[@]}" > "$tmp"
emit "$title" "$tmp" "$srcbase/pages/index.md" "$out/index.html"

items=$(mktemp); : > "$items"
for f in "$src"/posts/*.md; do
    slug=$(basename "$f" .md)
    title=$(frontmatter "$f" title); title=${title:-$slug}
    date=$(frontmatter "$f" date)

    pc=$(mktemp)
    {
        echo "<article class=\"post\">"
        echo "<h1>$title</h1>"
        [ -n "$date" ] && echo "<p class=\"post-date\">$date</p>"
        body "$f" | "${cm[@]}"
        echo "</article>"
        echo "<p class=\"back\"><a href=\"/blog/\">← all posts</a></p>"
    } > "$pc"
    emit "$title" "$pc" "$srcbase/posts/$slug.md" "$out/blog/$slug/index.html"

    printf '%s\t%s\t%s\n' "${date:-0000-00-00}" "$title" "$slug" >> "$items"
done

bc=$(mktemp)
{
    echo "<h1>blog</h1>"
    echo "<ul class=\"post-list\">"
    sort -r "$items" | while IFS=$'\t' read -r date title slug; do
        echo "<li><time>$date</time><a href=\"/blog/$slug/\">$title</a></li>"
    done
    echo "</ul>"
} > "$bc"
emit "blog" "$bc" "$srcbase/posts" "$out/blog/index.html"
