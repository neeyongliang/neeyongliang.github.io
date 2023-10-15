---
title: "实践指北：019 kitty 终端模拟器"
date: "2023-08-27"
notaxonomy: false
norobots: false
nodate: false
hidemeta: false
draft: false

author: "yongliang"
keywords: ["kitty", "terminal emulator", "gpu"]
tags: ["linux", "terminal", "kitty"]
categories: ["practice"]
type: "原"
---

![kitty](../mac-kitty.webp)

官网描述中使用了“快速、功能丰富、跨平台、支持 GPU 加速”等文字来描述它，可见作者充满了骄傲。kitty 的核心使用 C 语音编写，并且有着丰富的插件系统 kitten，可以使用其他语音编写。kitten 是幼猫的意思，这里的命名也很有趣。

- 官网：<https://sw.kovidgoyal.net/kitty/>
- 项目：<https://github.com/kovidgoyal/kitty>

# 1. 安装

## 1.1. 预编译安装

常见的系统可以去 <https://github.com/kovidgoyal/kitty/releases> 下载对应启动的二进制包后安装。

## 1.2. 从源码编译

我使用的是 Ubuntu20.04，目前不在支持的列表当中（主要是 glibc 版本太低），可以选择使用 Ubuntu 22.04 中的 kitty-0.21 版本重编，可以选择从源码构建，获取最新的功能。

### 1.2.1. 准备工作

kitty 编译要求的条件中，有两项是无法在 Ubuntu 20.04 的自身源里解决的，需要借助特殊手段。

- go >= 1.20
- xxhash >= 0.8.0

前者可以使用官网脚本手动安装，后者可以使用 Ubuntu 22.04 的源重新编译。

注意⚠️：源码获取只推荐拉取 git 仓库，不推荐下载 release 页面的压缩包。

原因：github 仓库自动生成的 release 压缩包是无法拉取 git submodule 的，因此在编译时会发生 zip 错误，官网虽然说可以使用不编译 wayland 模块来绕过，但目前的版本已失效。

### 1.2.2. 构建脚本

进入 kitty 源码文件夹，创建 manual.sh，然后修改版本号，默认是 0.29.2版本，之后使用 sh ./manual.sh 进行构建。

```sh
#!/bin/bash

##########################################################
# Description: build kitty from source in Ubuntu20.04
#   kitty is a greate cross-platform terminal emulator
# Author:
#   yongliang <neeyongliang@gmail.com>
# Changelog:
#   2023.08.27 First release
##########################################################

echo "Press Ctrl+C anytime if you want interrupt..."
sleep 5

if [ ! -d Workspace ]; then
    mkdir Workspace
fi

version="0.29.2"
currArch="$(uname -m)"
distroVer="ubuntu20.04"
currArch="$(dpkg-architecture -q DEB_BUILD_ARCH_CPU)"

# set 0 if you go version uppper 1.20
goInstall=1
goVersion="1.21.0"
# set
xxhashInstall=1
xxhashVer="0.8.1-1"

cd Workspace || exit 1
if [ ! -f kitty-dep-xxhash ] && [ $xxhashInstall -eq 1 ]; then
    # build xxhash
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_"$xxhashVer".dsc
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_0.8.1.orig.tar.gz
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_"$xxhashVer".debian.tar.xz
    touch kitty-dep-xxhash
fi
sudo apt-get update
sudo apt install -y git dpkg-dev debhelper vim

if [ ! -f libxxhash0_"$xxhashVer"_"$currArch".deb ]; then
    # xxhash not build last time
    rm -rf xxhash-0.8.1
    dpkg-source -x xxhash_"$xxhashVer".dsc
    cd xxhash-0.8.1/ || exit 2
    sed -i 's/\= 13/\= 12/g' debian/control
    sleep 1
    dpkg-buildpackage -b
    cd ..
    sudo dpkg -i libxxhash0_"$xxhashVer"_*.deb libxxhash-dev_"$xxhashVer"_*.deb
fi

if [ $goInstall -eq 1 ] && [ ! -f go"$goVersion".linux-"$currArch".tar.gz ]; then
    # install go
    wget https://golang.google.cn/dl/go"$goVersion".linux-"$currArch".tar.gz
    sudo tar -C /usr/local -xzf go"$goVersion".linux-"$currArch".tar.gz
fi
export PATH=$PATH:/usr/local/go/bin
go version

if [ ! -f "kitty-dep-installed" ]; then
sudo apt-get install -y libgl1-mesa-dev libxi-dev libxrandr-dev \
  libxinerama-dev ca-certificates libxcursor-dev libxcb-xkb-dev libdbus-1-dev \
  libxkbcommon-dev libharfbuzz-dev libx11-xcb-dev zsh libpng-dev liblcms2-dev \
  libfontconfig-dev libxkbcommon-x11-dev libcanberra-dev uuid-dev \
  libssl-dev python3-dev python3-pip fonts-roboto
  touch kitty-dep-installed
fi

# for Chinese mirrors
if [ "$LANG" = "zh_CN.UTF-8" ]; then
  go env -w GO111MODULE=on
  go env -w GOPROXY=https://goproxy.cn,direct
  pip3 config set global.index-url https://mirrors.ustc.edu.cn/pypi/web/simple
fi

if [ ! -f kitty-dep-sphinx ]; then
    sudo pip3 install Sphinx sphinx-copybutton sphinx-inline-tabs sphinxext-opengraph furo
    touch kitty-dep-sphinx
fi

# clone source
# set following config if occur 'The TLS connection was non-properly terminated'
# git config --global --unset https.https://github.com.proxy
# git config --global --unset http.https://github.com.proxy

if [ ! -d kitty ]; then
    git clone https://github.com/kovidgoyal/kitty.git --depth=1 --progress
fi
cd kitty || exit 3
# fix optimize, tuple cannot compare with int type
sed -i 's/optimize=(0, 1, 2)/optimize=0/g' setup.py

# for build
make linux-package
gzip -fk linux-package/share/man/man1/kitty.1 > linux-package/share/man/man1/kitty.1.gz
rm -rf kitty_"$version"_"$distroVer"_"$currArch"
mkdir kitty_"$version"_"$distroVer"_"$currArch"
cd kitty_"$version"_"$distroVer"_"$currArch" || exit 1
mkdir DEBIAN etc usr
cp -a ../linux-package/* usr/
mkdir -p etc/xdg/kitty/
echo "update_check_interval 0" > etc/xdg/kitty/kitty.conf
touch DEBIAN/postinst DEBIAN/prerm DEBIAN/control
cat <<EOF > DEBIAN/control
Package: kitty
Version: $version-$distroVer
Architecture: $(dpkg-architecture -q DEB_BUILD_ARCH_CPU)
Maintainer: yongliang <neeyongliang@gmail.com>
Depends: python3 (<< 3.9),
  python3 (>= 3.8~),
  python3.8,
  python3:any,
  libc6 (>= 2.29),
  libcanberra0 (>= 0.29),
  libdbus-1-3 (>= 1.9.14),
  libfontconfig1 (>= 2.12.6),
  libfreetype6 (>= 2.6),
  libharfbuzz0b (>= 2.2.0),
  liblcms2-2 (>= 2.2+git20110628),
  libpng16-16 (>= 1.6.2-1),
  libpython3.8 (>= 3.8~),
  librsync2 (>= 2.0.0),
  libwayland-client0 (>= 1.9.91),
  libx11-6 (>= 2:1.2.99.901),
  libx11-xcb1 (>= 2:1.6.9),
  libxkbcommon-x11-0 (>= 0.5.0),
  libxkbcommon0 (>= 0.5.0),
  openssl (>= 1.1.1),
  zlib1g (>= 1:1.1.4)
Recommends: libcanberra0
Suggests: imagemagick
Provides: x-terminal-emulator
Section: x11
Priority: optional
Homepage: https://sw.kovidgoyal.net/kitty/
Description: fast, featureful, GPU based terminal emulator
 Kitty supports modern terminal features like: graphics, unicode,
 true-color, OpenType ligatures, mouse protocol, focus tracking, and
 bracketed paste.
 .
 Kitty has a framework for "kittens", small terminal programs that can be used
 to extend its functionality.
Original-Maintainer: James McCoy <jamessan@debian.org>
EOF

chmod 775 DEBIAN/postinst DEBIAN/prerm
cat <<EOF > DEBIAN/postinst
#!/bin/sh
set -e

case "$1" in
  configure)
    update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator \
        /usr/bin/kitty 20 --slave /usr/share/man/man1/x-terminal-emulator.1.gz \
        x-terminal-emulator.1.gz /usr/share/man/man1/kitty.1.gz
    ;;
esac

# Automatically added by dh_python3:
if which py3compile >/dev/null 2>&1; then
    py3compile -p kitty /usr/lib/kitty -V 3.8
fi
if which pypy3compile >/dev/null 2>&1; then
    pypy3compile -p kitty /usr/lib/kitty -V 3.8 || true
fi

# End automatically added section

exit 0
EOF

cat <<EOF > DEBIAN/prerm
#!/bin/sh
set -e

rm -rf /usr/lib/kitty/shell-integration

case "$1" in
  remove|deconfigure)
    rm -rf /usr/lib/kitty
    update-alternatives --remove x-terminal-emulator /usr/bin/kitty
    ;;
esac

#DEBHELPER#

exit 0
EOF

mkdir -p usr/share/applications
cat <<EOF > usr/share/applications/kitty.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, feature-rich, cross-platform, GPU based terminal
TryExec=kitty
Exec=kitty
Icon=kitty
Categories=System;TerminalEmulator;
EOF

mkdir -p usr/share/icons/hicolor/256x256/apps
cp ../logo/kitty.png usr/share/icons/hicolor/256x256/apps/

mkdir -p usr/share/python3/runtime.d
cat <<EOF > usr/share/python3/runtime.d/kitty.rtupdate
#! /bin/sh
set -e

if [ "$1" = rtupdate ]; then
    py3clean -p kitty /usr/lib/kitty
    py3compile -p kitty -V 3.8 /usr/lib/kitty
fi
EOF
chmod 775 usr/share/python3/runtime.d/kitty.rtupdate

cd ..
dpkg -b kitty_"$version"_"$distroVer"_"$currArch"

exit 0
```

# 2. 配置

## 2.1. 全局配置

kitty 作者虽然反对终端复用器，但是作为用户还是要有自己的倔强，可以将快捷键绑定为 tmux 兼容模式。

主题可以选择任意喜欢的类型，使用 kitty +kitten theme 可以直接选择。

```sh
# vim:fileencoding=utf-8:foldmethod=marker

###############################################
# File:
#   kitty for myself.
# Usage:
#   mkdir -p $HOME/.config/kitty/
#   cp -a kitty.conf $HOME/.config/kitty/
# Author:
#   yongliang <neeyongliang@gmail.com>
# Changelog:
#   2022.12.10 First release
#   2022.12.28 Update keymaps
###############################################

#: Fonts {{{
font_family      Cascadia Code
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 15.0
force_ltr no

# symbol_map U+E0A0-U+E0A3,U+E0C0-U+E0C7 PowerlineSymbols
# narrow_symbols U+E0A0-U+E0A3,U+E0C0-U+E0C7 1
disable_ligatures always
font_features none
box_drawing_scale 0.001, 1, 1.5, 2
#: }}}

#: Cursor customization {{{
cursor #cccccc
cursor_text_color #111111
# Shape can be: block, beam, underline
cursor_shape block
cursor_beam_thickness 1.5
cursor_underline_thickness 2.0
cursor_blink_interval -1
cursor_stop_blinking_after 30.0
#: }}}

#: Scrollback {{{
scrollback_lines 20000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
scrollback_pager_history_size 20
scrollback_fill_enlarged_window no
wheel_scroll_multiplier 5.0
wheel_scroll_min_lines 1
touch_scroll_multiplier 1.0

#: }}}

#: Mouse {{{
mouse_hide_wait 3.0
url_color #0087bd
# style can be: none, straight, double, curly, dotted, dashed.
url_style curly
open_url_with default
url_prefixes file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh
detect_urls yes

# url_excluded_characters
copy_on_select a1
map ctrl+shift+v paste_from_buffer a1
paste_actions quote-urls-at-prompt
strip_trailing_spaces never
select_by_word_characters @-./_~?&=%+#

# select_by_word_characters_forward
click_interval -1.0
focus_follows_mouse yes

# shape can be: arrow, beam and hand
pointer_shape_when_grabbed hand
default_pointer_shape arrow
pointer_shape_when_dragging hand

#: Mouse actions {{{
#: Format => mouse_map button-name event-type modes action
clear_all_mouse_actions no
mouse_map left click ungrabbed mouse_handle_click selection link prompt
mouse_map shift+left click grabbed,ungrabbed mouse_handle_click selection link prompt
mouse_map ctrl+shift+left release grabbed,ungrabbed mouse_handle_click link
mouse_map ctrl+shift+left press grabbed discard_event
mouse_map middle release ungrabbed paste_from_selection
mouse_map left press ungrabbed mouse_selection normal
mouse_map ctrl+alt+left press ungrabbed mouse_selection rectangle
mouse_map left doublepress ungrabbed mouse_selection word
mouse_map left triplepress ungrabbed mouse_selection line
mouse_map ctrl+alt+left triplepress ungrabbed mouse_selection line_from_point
mouse_map right press ungrabbed mouse_selection extend
mouse_map shift+middle release ungrabbed,grabbed paste_selection
mouse_map shift+middle press grabbed discard_event
mouse_map shift+left press ungrabbed,grabbed mouse_selection normal
mouse_map ctrl+shift+alt+left press ungrabbed,grabbed mouse_selection rectangle
mouse_map shift+left doublepress ungrabbed,grabbed mouse_selection word
mouse_map shift+left triplepress ungrabbed,grabbed mouse_selection line
mouse_map ctrl+shift+alt+left triplepress ungrabbed,grabbed mouse_selection line_from_point
mouse_map shift+right press ungrabbed,grabbed mouse_selection extend
mouse_map ctrl+shift+right press ungrabbed mouse_show_command_output
#: }}}
#: Mouse actions end
#: }}}
#: Mouse end

#: Performance tuning {{{
repaint_delay 10
input_delay 3
sync_to_monitor yes
#: }}}

#: Terminal bell {{{
enable_audio_bell no
visual_bell_duration 0.0
visual_bell_color none
window_alert_on_bell yes
bell_on_tab "🔔 "
command_on_bell none
bell_path none
#: }}}

#: Window layout {{{
remember_window_size  yes
initial_window_width  800
initial_window_height 600
enabled_layouts splits,stack,grid
map f7 layout_action rotate
map ctrl+a>space layout_action rotate
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 5
placement_strategy center
active_border_color #00ff00
inactive_border_color #cccccc
bell_border_color #ff5a00
inactive_text_alpha 1.0
hide_window_decorations no
window_logo_path none
window_logo_position bottom-right
window_logo_alpha 0.5
resize_debounce_time 0.1
resize_in_steps no
visual_window_select_characters 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ
confirm_os_window_close -1
#: }}}

#: Tab bar {{{
tab_bar_edge top
tab_bar_margin_width 0.0
tab_bar_margin_height 0.0 0.0
# style can be: fade, slant, separator, powerline, custom, hidden
tab_bar_style powerline
tab_bar_align center
tab_bar_min_tabs 2
tab_switch_strategy previous
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
# powerline style can be: angled, slanted, round
tab_powerline_style slanted
tab_activity_symbol none
tab_title_template "Tab.{index}"
active_tab_title_template none
active_tab_foreground   #000
active_tab_background   #eee
active_tab_font_style   bold-italic
inactive_tab_foreground #444
inactive_tab_background #999
inactive_tab_font_style normal
tab_bar_background none
tab_bar_margin_color none
#: }}}

#: Color scheme {{{
foreground #dddddd
background #000000
background_opacity 1
#: bg image can be: tiled, mirror-tiled, scaled, clamped or centered
background_image none
background_image_layout scaled
background_image_linear no
dynamic_background_opacity no
background_tint 0.0
dim_opacity 0.75
selection_foreground #000000
selection_background #fffacd

#: The color table {{{
#: The 256 terminal colors. There are 8 basic colors, each color has a
#: dull and bright version, for the first 16 colors. You can set the
#: remaining 240 colors as color16 to color255.
#: black
color0 #000000
color8 #767676
#: red
color1 #cc0403
color9 #f2201f
#: green
color2  #19cb00
color10 #23fd00
#: yellow
color3  #cecb00
color11 #fffd00
#: blue
color4  #0d73cc
color12 #1a8fff
#: magenta
color5  #cb1ed1
color13 #fd28ff
#: cyan
color6  #0dcdcd
color14 #14ffff
#: white
color7  #dddddd
color15 #ffffff
#: Color for marks of type 1 (light steel blue)
mark1_foreground black
mark1_background #98d3cb
#: Color for marks of type 2 (beige)
mark2_foreground black
mark2_background #f2dcd3
#: Color for marks of type 3 (violet)
mark3_foreground black
mark3_background #f274bc
#: }}} color tab end
#: }}} Color scheme end

#: Advanced {{{
shell .
editor .
close_on_child_death no
allow_remote_control yes
listen_on none
# env
# watcher
# exe_search_path
#:  exe_search_path /some/prepended/path
#:  exe_search_path +/some/appended/path
#:  exe_search_path -/some/excluded/path
update_check_interval 24
startup_session none
clipboard_control write-clipboard write-primary read-clipboard read-primary
clipboard_max_size 64
# file_transfer_confirmation_bypass
allow_hyperlinks yes
shell_integration enabled
allow_cloning ask
clone_source_strategies venv,conda,env_var,path
term xterm-256color
#: }}}

#: OS specific tweaks {{{
wayland_titlebar_color system
macos_titlebar_color system
macos_option_as_alt no
macos_hide_from_tasks no
macos_quit_when_last_window_closed no
macos_window_resizable yes
macos_thicken_font 0
macos_traditional_fullscreen no
macos_show_window_title_in all
macos_menubar_title_max_length 0
macos_custom_beam_cursor no
macos_colorspace srgb
linux_display_server auto
#: }}}

#: Keyboard shortcuts {{{
kitty_mod ctrl+shift
clear_all_shortcuts no
#: Clipboard {{{
#: Copy to clipboard
map kitty_mod+c copy_to_clipboard
#: Paste from clipboard
map kitty_mod+v paste_from_clipboard
#: Paste from selection
map kitty_mod+s  paste_from_selection
map shift+insert paste_from_selection
#: Pass selection to program
map kitty_mod+o pass_selection_to_program
#: }}}

#: Scrolling {{{
#: Scroll line up
map kitty_mod+up    scroll_line_up
map kitty_mod+k     scroll_line_up
map cmd+up          scroll_line_up
#: Scroll line down
map kitty_mod+down    scroll_line_down
map kitty_mod+j       scroll_line_down
map cmd+down          scroll_line_down
#: Scroll page up
map kitty_mod+page_up scroll_page_up
map cmd+page_up       scroll_page_up
#: Scroll page down
map kitty_mod+page_down scroll_page_down
map cmd+page_down       scroll_page_down
#: Scroll to top
map kitty_mod+home scroll_home
map cmd+home       scroll_home
#: Scroll to bottom
map kitty_mod+end scroll_end
map cmd+end       scroll_end
#: Scroll to previous shell prompt
map kitty_mod+z scroll_to_prompt -1
#: Scroll to next shell prompt
map kitty_mod+x scroll_to_prompt 1
#: Browse scrollback buffer in pager
map kitty_mod+h show_scrollback
map kitty_mod+g show_last_command_output
#: }}}

#: Window management {{{
#: New window
map f4              launch --location=split
# create new window with current directory
map kitty_mod+enter launch --cwd=current
# create new vertical window
map ctrl+a>|        launch --location=vsplit
map ctrl+a>%        launch --location=vsplit
map ctrl+a>v        launch --location=vsplit
# create new horizontal window
map ctrl+a>_        launch --location=hsplit
map ctrl+a>"        launch --location=hsplit
map ctrl+a>h        launch --location=hsplit
#: New OS window
map kitty_mod+n new_os_window
#: Close window
map kitty_mod+w close_window
map ctrl+a>x close_window
#: Move window
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window
# move neighboring window
map ctrl+left    neighboring_window left
map ctrl+right   neighboring_window right
map ctrl+up      neighboring_window up
map ctrl+down    neighboring_window down
# move window
map kitty_mod+f  move_window_forward
map kitty_mod+b  move_window_backward
map kitty_mod+`  move_window_to_top
map shift+up     move_window up
map ctrl+a>k     move_window up
map shift+left   move_window left
map ctrl+a>h     move_window left
map shift+right  move_window right
map ctrl+a>l     move_window right
map shift+down   move_window down
map ctrl+a>j     move_window down
#: Start resizing window
map kitty_mod+r  start_resizing_window
map cmd+r        start_resizing_window
map alt+right    resize_window narrower
map alt+left     resize_window wider
map alt+up       resize_window taller
map alt+plus     resize_window taller
map alt+down     resize_window shorter 3
map alt+minus    resize_window shorter 3
map ctrl+home    resize_window reset
#: Index window
map kitty_mod+1 first_window
map kitty_mod+2 second_window
map kitty_mod+3 third_window
map kitty_mod+4 fourth_window
map kitty_mod+5 fifth_window
map kitty_mod+6 sixth_window
map kitty_mod+7 seventh_window
map kitty_mod+8 eighth_window
map kitty_mod+9 ninth_window
map kitty_mod+0 tenth_window
#: Visually select and focus window
map kitty_mod+f7 focus_visible_window
map ctrl+a>q focus_visible_window
#: Visually swap window with another
map kitty_mod+f8 swap_with_window
#: }}}

#: Tab management {{{
#: Next tab
map kitty_mod+right next_tab
map ctrl+tab        next_tab
map ctrl+a>n        next_tab
#: Previous tab
map kitty_mod+left  previous_tab
map ctrl+shift+tab  previous_tab
map ctrl+a>p        next_tab
#: New tab
map kitty_mod+t     new_tab
map cmd+t           new_tab
map ctrl+a>c        new_tab
#: Close tab
map kitty_mod+q     close_tab
map cmd+w           close_tab
#: Close OS window
map shift+cmd+w close_os_window
map ctrl+q close_os_window
#: Move tab forward
map kitty_mod+. move_tab_forward
#: Move tab backward
map kitty_mod+, move_tab_backward
#: Set tab title
map kitty_mod+alt+t set_tab_title
map ctrl+a>,        set_tab_title
#: Go to tab index
map ctrl+1       goto_tab 1
map ctrl+a>1     goto_tab 1
map ctrl+2       goto_tab 2
map ctrl+a>2     goto_tab 2
map ctrl+3       goto_tab 3
map ctrl+a>3     goto_tab 3
map ctrl+4       goto_tab 4
map ctrl+a>4     goto_tab 4
map ctrl+5       goto_tab 5
map ctrl+a>5     goto_tab 5
map ctrl+6       goto_tab 6
map ctrl+a>6     goto_tab 6
map ctrl+7       goto_tab 7
map ctrl+a>7     goto_tab 7
map ctrl+8       goto_tab 8
map ctrl+a>8     goto_tab 8
map ctrl+9       goto_tab 9
map ctrl+a>9     goto_tab 9
map ctrl+0       goto_tab 10
map ctrl+a>0     goto_tab 10
#: }}}

#: Font sizes {{{
map kitty_mod+equal  change_font_size all +2.0
map kitty_mod+plus   change_font_size all +2.0
map kitty_mod+kp_add change_font_size all +2.0
map kitty_mod+minus       change_font_size all -2.0
map kitty_mod+kp_subtract change_font_size all -2.0
#: Reset font size
map kitty_mod+backspace change_font_size all 0
#: }}}

#: Select and act on visible text {{{
#: Open URL
map kitty_mod+e open_url_with_hints
#: Insert selected path
map kitty_mod+p>f kitten hints --type path --program -
map kitty_mod+p>shift+f kitten hints --type path
map kitty_mod+p>l kitten hints --type line --program -
map kitty_mod+p>w kitten hints --type word --program -
map kitty_mod+p>h kitten hints --type hash --program -
#: Open the selected file at the selected line
map kitty_mod+p>n kitten hints --type linenum
#: Open the selected hyperlink
map kitty_mod+p>y kitten hints --type hyperlink
#: Miscellaneous {{{
#: Show documentation
map kitty_mod+f1 show_kitty_doc overview
#: Toggle fullscreen
map kitty_mod+f11 toggle_fullscreen
#: Toggle maximized
map kitty_mod+f10 toggle_maximized
#: Toggle macOS secure keyboard entry
map opt+cmd+s toggle_macos_secure_keyboard_entry
#: Unicode input
map kitty_mod+u kitten unicode_input
#: Edit config file
map kitty_mod+f2 edit_config_file
#: Open the kitty command shell
map kitty_mod+escape kitty_shell window
map kitty_mod+a>m set_background_opacity +0.1
map kitty_mod+a>l set_background_opacity -0.1
#: Make background fully opaque
map kitty_mod+a>1 set_background_opacity 1
#: Reset background opacity
map kitty_mod+a>d set_background_opacity default
#: Reset the terminal
map kitty_mod+delete clear_terminal reset active
#: Clear up to cursor line
map cmd+k clear_terminal to_cursor active
#: Reload kitty.conf
map kitty_mod+f5 load_config_file
#: Debug
map kitty_mod+f6 debug_config
#: Open kitty Website
map shift+cmd+/ open_url https://sw.kovidgoyal.net/kitty/
#: }}}
#: }}}

#: Theme {{{
map ctrl+a>t kitten themes
include current-theme.conf
#: }}}
```

## 2.2. 插件配置

kitty 的 Session 其实跟 tmux 的 Session 不是一回事，它只是一种“固定的模版打开”的形式，比如设置上下分栏，7:3 比例，那么没事使用这个 Session 打开的都是这种布局，但是无法 attach 或者 dettach。

其他的图片查看、diff 等使用，可以查看官网，我还是比较喜欢使用独立的工具。

## 2.3. 输入法配置

kitty 不支持 fcitx4，即使是 fcitx5，配置里也是 ibus，参考 <https://github.com/kovidgoyal/kitty/issues/469>。

```sh
GLFW_IM_MODULE=ibus kitty
```

# 3. 感受

我一直在寻找一款使用顺手的现代化终端模拟器，不可否认传承至今的“老朋友们”依然稳定可靠，坚如磐石，但一些功能的缺失让人总是在一些地方很遗憾，比如多路复用，比如不支持 openGL…

我知道有很多方法解决上面的问题，但那是设计之初就存在的问题，在我可以预见的时间里，那些特性是不可能加入的，比较“稳”太重要了（笑）。在我搜寻范围内，可以很好支持 GPU 的终端主要有三款：alacritty、wezterm 和 kitty。

这几款我都试用过一段时间，总的来说各自有各自的问题，alacritty 速度快但功能单一，wezterm 功能丰富但内存占用，kitty 不支持 fcitx4 ，作者宣称讨厌所有终端复用器，但又还没有做出类似 tmux 的原生功能。综合考虑几款终端，我认为 kitty 是综合实力最优秀的。

# 4. 参考

- https://sw.kovidgoyal.net/kitty/build/#build-from-source
- https://ttys3.dev/blog/kitty