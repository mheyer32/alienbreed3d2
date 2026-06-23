#!/usr/bin/env sh
set -eu

root="${1:-.}"
media="$root/media"
includes="$media/includes"
levels="$media/levels"
repo_media="$root/../media"

link_if_present() {
	src="$1"
	dst="$2"
	if [ -e "$src" ] && [ ! -e "$dst" ]; then
		ln -s "$src" "$dst"
	fi
}

lowercase_aliases() {
	dir="$1"
	[ -d "$dir" ] || return 0
	find "$dir" -maxdepth 1 -type f | while IFS= read -r file; do
		base=$(basename "$file")
		lower=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')
		if [ "$base" != "$lower" ] && [ ! -e "$dir/$lower" ]; then
			ln -s "$base" "$dir/$lower"
		fi
	done
}

move_if_present() {
	src="$1"
	dst="$2"
	if [ -f "$src" ] && [ ! -f "$dst" ]; then
		mv "$src" "$dst"
	fi
}

if [ -d "$repo_media" ]; then
	link_if_present "../media/includes" "$root/includes"
	link_if_present "../media/hqn" "$root/hqn"
	link_if_present "../media/levels" "$root/levels"
	link_if_present "../media/ab3dsfx/samples" "$root/samples"
	link_if_present "../../media/includes" "$media/includes"
	link_if_present "../../media/levels" "$media/levels"
	link_if_present "../../media/music" "$media/music"
	lowercase_aliases "$repo_media/hqn"
	lowercase_aliases "$repo_media/ab3dsfx/samples"
fi

mkdir -p "$includes" "$levels"

move_if_present "$root/includes/main.256pal" "$includes/main.256pal"
move_if_present "$root/Includes/main.256pal" "$includes/main.256pal"
move_if_present "$root/main.256pal" "$includes/main.256pal"

move_if_present "$root/includes/title.mod" "$includes/title.mod"
move_if_present "$root/Includes/title.mod" "$includes/title.mod"
move_if_present "$root/title.mod" "$includes/title.mod"

move_if_present "$root/includes/At_Dooms_Gate_E1M1.sid" "$root/ie/at_dooms_gate_e1m1.sid"
move_if_present "$root/Includes/At_Dooms_Gate_E1M1.sid" "$root/ie/at_dooms_gate_e1m1.sid"
move_if_present "$root/At_Dooms_Gate_E1M1.sid" "$root/ie/at_dooms_gate_e1m1.sid"

move_if_present "$root/includes/test.lnk" "$includes/test.lnk"
move_if_present "$root/Includes/test.lnk" "$includes/test.lnk"
move_if_present "$root/test.lnk" "$includes/test.lnk"
move_if_present "$root/TEST.LNK" "$includes/test.lnk"

find "$root" -maxdepth 2 -type f \( \
	-name '*.wad' -o -name '*.WAD' -o \
	-name '*.ptr' -o -name '*.PTR' -o \
	-name '*.256pal' -o -name '*.256PAL' \
\) | while IFS= read -r file; do
	case "$file" in
		"$includes"/*) continue ;;
	esac
	base=$(basename "$file" | tr '[:upper:]' '[:lower:]')
	if [ ! -f "$includes/$base" ]; then
		mv "$file" "$includes/$base"
	fi
done

printf '%s\n' "Normalized IE media layout under $media"
