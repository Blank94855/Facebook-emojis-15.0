#####################################
#     Android Emoji Changer
#                By
# Khun Htetz Naing (t.me/HtetzNaing)
#####################################

# Paths and configurations
FONT_DIR="$MODPATH/system/fonts"
MAIN_FONT_NAME='NotoColorEmoji.ttf'
MAIN_FONT_FILE="$FONT_DIR/$MAIN_FONT_NAME"

# Load utils script
. "$MODPATH/const.sh"

replace_fb_app_emojis() {
    local PKG="$1"
    local NAME="$2"
    local DIR="/data/data/$PKG/app_ras_blobs"
    local FONT_FILE="FacebookEmoji.ttf"

    ui_print "[!] $NAME 📱"

    if package_installed "$PKG"; then
        if rm -rf "$DIR" && mkdir -p "$DIR" && cd "$DIR"; then
            set_perm "$DIR" 0 0 0755
            if cp "$MAIN_FONT_FILE" "$FONT_FILE"; then
                set_perm "$FONT_FILE" 0 0 700
                ui_print "[+] $NAME Emojis ✅"
            else
                ui_print "[-] $NAME Emojis ❎"
            fi
        else
            ui_print "[-] Cannot navigate to $DIR ❌"
        fi
    else
        ui_print "[-] $NAME NOT installed ℹ️"
    fi
}

gb_emoji() {
    local GB_FONTS_DIR="/data/data/com.google.android.gms/files/fonts/opentype"
    local GBOARD_DATA_DIR="/data/data/com.google.android.inputmethod.latin"
    local CACHE_PATH_PATTERN="*inputmethod.latin*/*cache*"

    ui_print "[!] GBoard ⌨️"

    if [ -d "$GB_FONTS_DIR" ]; then
        cd "$GB_FONTS_DIR" || { ui_print "[-] Cannot navigate to $GB_FONTS_DIR"; return; }
        for file in Noto_Color_Emoji_Compat*.ttf; do
            if [ -e "$file" ]; then
                if cp "$MAIN_FONT_FILE" "$file"; then
                    set_perm "$file" 0 0 700
                    ui_print "[+] GBoard Emojis ✅"
                else
                    ui_print "[-] GBoard Emojis ❎"
                fi
            fi
        done
    fi

    if [ -d "$GBOARD_DATA_DIR" ]; then
        ui_print "[-] Clearing GBoard caches..."
        find /data -type d -path "$CACHE_PATH_PATTERN" -exec rm -rf {} + && am force-stop com.google.android.inputmethod.latin
    else
        ui_print "[-] GBoard is not installed or no cache to clear."
    fi
}

system_emoji() {
    ui_print "[!] System Emojis ⚙️"
    ui_print "[+] $MAIN_FONT_NAME ✅"
    for font in $VARIANTS; do
      local mirror="$FONT_DIR/$font"
      local system="/system/fonts/$font"
      if [ -f "$system" ] && [ ! -f "$mirror" ]; then
          if cp "$MAIN_FONT_FILE" "$mirror"; then
            ui_print "[+] $font ✅"
          else
            ui_print "[-] $font ❎"
          fi
      fi
    done
}

disable_conflict_modules() {
  local modules
  modules=$(get_conflict_font_modules)
  if [ -n "$modules" ]; then
      ui_print ""
      ui_print " ℹ️ Conflicts font modules ⚔️"
      ui_print "******************************"
      local conflict_count=0
      for id in $modules; do
        local full_path="$MODULES_DIR/$id"
        name=$(grep_prop name "$full_path/module.prop")
        if [ "$id" == "$MODID" ]; then
          rm -f "$full_path"/{disable,remove}
        else
          conflict_count=$((conflict_count+1))
          if is_magisk; then
            if disable_module "$id"; then
              ui_print "$conflict_count. $name [DISABLED]"
            else
              ui_print "$conflict_count. $name [CANNOT DISABLE]"
            fi
          else
            ui_print "$conflict_count. $name [PLZ DISABLE]"
          fi
        fi
      done
      if [ $conflict_count != 0 ]; then
        ui_print ""
        ui_print "*IMPORTANT: Make sure to disable other font modules to ensure this one works!!"
      fi
  fi
}

kernelSU() {
    if [ -f /data/adb/ksud ]; then
        ui_print ""
        ui_print " ℹ️ KernelSU ✨"
        ui_print "****************"
        if mv -f "$MODPATH/ksu.sh" "$MODPATH/post-fs-data.sh"; then
            ui_print "[+] post-fs-data.sh ✅"
        else
            ui_print "[-] post-fs-data.sh ❎"
        fi
    fi
}

credits() {
    ui_print ""
    ui_print " Credits & Thanks 🙏"
    ui_print "*********************"
    ui_print "- killgmsfont | @MrCarb0n"
}

# Main script execution
system_emoji
replace_fb_app_emojis "com.facebook.orca" "Messenger"
replace_fb_app_emojis "com.facebook.katana" "Facebook"
gb_emoji
kernelSU
disable_conflict_modules
credits