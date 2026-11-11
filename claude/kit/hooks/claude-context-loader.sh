#!/usr/bin/env bash
# SessionStart hook: walks from $PWD up to $HOME (or /), collecting every
# claude-context/*.md file at each level, and injects them as additional
# context. Parent-level files appear first so project-level context is read
# last (most-specific wins by convention).

ancestors() {
  local cur="$1" out=()
  while :; do
    out=("$cur" ${out[@]+"${out[@]}"})
    [ "$cur" = "$HOME" ] && break
    [ "$cur" = "/" ] && break
    local parent
    parent="$(dirname "$cur")"
    [ "$parent" = "$cur" ] && break
    cur="$parent"
  done
  printf '%s\n' "${out[@]}"
}

dirs=()
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ -n "$common" ] && [ "$(basename "$common")" = ".git" ]; then
  main="$(dirname "$common")"
  case "$PWD/" in
    "$main/"*) ;;
    *) while IFS= read -r d; do dirs+=("$d"); done < <(ancestors "$main") ;;
  esac
fi
while IFS= read -r d; do
  seen=false
  for x in ${dirs[@]+"${dirs[@]}"}; do [ "$x" = "$d" ] && seen=true && break; done
  $seen || dirs+=("$d")
done < <(ancestors "$PWD")

shopt -s nullglob
content=""
for d in "${dirs[@]}"; do
  files=("$d/claude-context"/*.md)
  (( ${#files[@]} > 0 )) || continue
  for f in "${files[@]}"; do
    label="${f#$HOME/}"
    content+="=== ${label} ===
$(cat "$f")

"
  done
done

[ -n "$content" ] || exit 0
jq -n --arg ctx "$content" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
