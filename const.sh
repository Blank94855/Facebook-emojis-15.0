#!/bin/bash

VARIANTS='SamsungColorEmoji.ttf AndroidEmoji-htc.ttf ColorUniEmoji.ttf DcmColorEmoji.ttf CombinedColorEmoji.ttf HTC_ColorEmoji.ttf LGNotoColorEmoji.ttf NotoColorEmojiLegacy.ttf'
MODULES_DIR="/data/adb/modules"
MODULES_UPDATE_DIR="/data/adb/modules_update"

read_emoji_names(){
  local FONT_XML="$1"
  # Extract font file names for emoji fonts from fonts.xml
  sed -ne '/<family lang="und-Zsye".*>/,/<\/family>/ {s/.*<font weight="400" style="normal">\([^<]*\)<\/font>.*/\1/p;}' "$FONT_XML"
}

get_emoji_names(){
  # Define paths and attempt to replace fonts from XML
  FONT_XML_PATH="/system/etc/fonts.xml"
  MIRROR_PATH="/sbin/.core/mirror$FONT_XML_PATH"
  LIST=$(read_emoji_names "$FONT_XML_PATH")
  if [ -f "$MIRROR_PATH" ]; then
      LIST2=$(read_emoji_names "$FONT_XML_PATH")
      LIST="${LIST} ${LIST2}"
  fi
  echo "$LIST"
}

is_conflict() {
    local system_font="$1/system/fonts"
    if [ -d "$system_font" ] && cd "$system_font"; then
        for file in *; do
            if echo "$VARIANTS" | grep -q "$(basename "$file")"; then
                return 0
            fi
        done
    fi
    return 1
}

is_magisk() {
    if [ "$KSU" != true ] && [ "$APATCH" != true ] && command -v magisk &> /dev/null; then
        return 0
    else
        return 1
    fi
}

str_trim(){
  input="$1"
  # Trim leading and trailing whitespace
  input="${input#"${input%%[![:space:]]*}"}"
  input="${input%"${input##*[![:space:]]}"}"
  echo "$input"
}

get_conflict_font_modules() {
    local conflict_modules=""
    if [ -d "$MODULES_DIR" ] && cd "$MODULES_DIR"; then
        if [ "$(ls -A "$MODULES_DIR")" ]; then
            for id in *; do
                local full_path="$MODULES_DIR/$id"
                local upd_path="$MODULES_UPDATE_DIR/$id"
                if is_conflict "$full_path" || is_conflict "$upd_path"; then
                    local disable_path="$full_path/disable"
                    [ ! -f "$disable_path" ] && conflict_modules="$conflict_modules $id"
                fi
            done
        fi
    fi

    # Print the conflicting modules
    str_trim "$conflict_modules"
}

disable_module() {
    id="$1"
    if is_magisk; then
        local full_path="$MODULES_DIR/$id/disable"
        touch "$full_path"
        return $?
    else
        ksud module disable "$id" || apd module disable "$id"
        return $?
    fi
}

uninstall_module() {
    id="$1"
    if is_magisk; then
        local full_path="$MODULES_DIR/$id/remove"
        touch "$full_path"
        return $?
    else
        ksud module uninstall "$id" || apd module uninstall "$id"
        return $?
    fi
}

fix_conflicts(){
  current="$1"
  local conflict_count=0
  for id in $(get_conflict_font_modules); do
    conflict_count=$((conflict_count+1))
    if [ "$id" != "$current" ]; then
      # echo "$conflict_count. Disable $id"
      if disable_module "$id"; then
        echo "$conflict_count. $id [DISABLED]"
      else
        echo "$conflict_count. $id [CANNOT DISABLE]"
      fi
    fi
  done
}

read_module_prop(){
  cat "$MODULES_DIR/$1/module.prop"
}

package_installed() {
    pm path "$1" > /dev/null
    return $?
}

flash_module(){
  zip="$1"
  magisk --install-module "$zip" || ksud module install "$zip" || apd module install "${zip.path}"
}

# Append variants from fonts.xml
VARIANTS="${VARIANTS} $(get_emoji_names)"