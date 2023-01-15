# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

config.load_autoconfig()
config.set('url.searchengines', {
    "DEFAULT": "https://duckduckgo.com/?q={}", 
    "wk": "https://en.wiktionary.org/wiki/Special:Search?search={}&go=Go",
    "wp": "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go",
    "youtube": "https://www.youtube.com/results?search_query={}",
})
config.set('url.start_pages','https://dashboards.skrewz.net/newtab')

#config.set('ui.default-zoom',1.2)

# Privacy centric stuff:
#
# Also spawn with: `--qt-flag disable-reading-from-canvas`
# And to get private tabs "by default", `--target window ':open -p duckduckgo.com'` does the tric.
# Cf. https://github.com/qutebrowser/qutebrowser/issues/2235
config.set('content.headers.accept_language','en-US,en;q=0.5')
config.set('content.headers.custom',{"accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})


# Background tabs:
config.set('tabs.background',True)
config.set('tabs.tree_tabs',True)
config.set('tabs.position','left')
config.set('tabs.max_width',300)
config.set('tabs.min_width',200)
config.set('colors.tabs.bar.bg','#000000')
config.set('colors.tabs.even.bg','#111111')
config.set('colors.tabs.odd.bg','#222222')
config.set('colors.tabs.selected.even.bg','#bbbbbb')
config.set('colors.tabs.selected.odd.bg','#aaaaaa')
# Private is the default; highlight whenever non-private
config.set('colors.statusbar.private.bg','black')
config.set('colors.statusbar.normal.bg','red')
config.set('downloads.location.directory',"/tmp/")
config.set('content.autoplay',False)

# /usr/share/qutebrowser/scripts/dictcli.py install en-GB
config.set('spellcheck.languages',["en-GB","da-DK"])


# Dvorak right hand-friendly scroll controls:
config.bind('h', 'scroll-page -0.3 0')
config.bind('t', 'scroll-page 0 0.3')
config.bind('n', 'scroll-page 0 -0.3')
config.bind('s', 'scroll-page 0.3 0')

# History in an easy place:
config.bind('H', 'back')
config.bind('S', 'forward')

# Dvorak binds necessitate rebinding search traversal keys:
config.bind('m', 'search-next')
config.bind('M', 'search-prev')

config.bind('O', 'set-cmd-text -s :open {url}')
config.bind('T', 'set-cmd-text -s :open -t')
config.bind('pt', 'open -t {primary}')

# These sit awkwardly close to each other on Dvorak, and J sits to the left of
# K. So inverting this default binding:
config.bind('j', 'tab-prev')
config.bind('k', 'tab-next')

############################################################
# Hints stuff
############################################################
config.set('fonts.hints','7pt default_family')
config.set('hints.auto_follow_timeout',100)
# Set hints chars for Dvorak users:
config.set('hints.mode',"letter")
config.set('hints.chars',"huetonaspgid")
# Trying hint mode with Dvorak-friendly word list:
#config.set('hints.mode',"word")
#config.set('hints.dictionary',str(config.configdir / 'words'))

# Get-rid-of-habit-binds
config.bind('<Ctrl-f>', 'nop')
config.bind('<Ctrl-t>', 'nop')
config.bind('<Ctrl-0>', 'nop')

# Convenience binds
config.bind('<Ctrl-l>b', 'spawn --userscript qute-pass')
config.bind('<Ctrl-l>b', 'spawn --userscript qute-pass', mode='insert')
config.bind('<Ctrl-l>b', 'spawn --userscript qute-pass', mode='prompt')
config.bind('<Ctrl-l>u', 'spawn --userscript qute-pass --username-only')
config.bind('<Ctrl-l>u', 'spawn --userscript qute-pass --username-only', mode='insert')
config.bind('<Ctrl-l>u', 'spawn --userscript qute-pass --username-only', mode='prompt')
config.bind('<Ctrl-l>p', 'spawn --userscript qute-pass --password-only')
config.bind('<Ctrl-l>p', 'spawn --userscript qute-pass --password-only', mode='insert')
config.bind('<Ctrl-l>p', 'spawn --userscript qute-pass --password-only', mode='prompt')
config.bind(',v', 'spawn mpv --pause --osd-level=3 --ytdl-format="bestvideo[height<=1080]+bestaudio/best[height<=1080]" --force-window=immediate {url}')
config.bind(',q', 'spawn --userscript ~/.config/qutebrowser/show-qr-in-display {url}')

config.bind(',<Left>', 'set tabs.position left')
config.bind(',<Up>'  , 'set tabs.position top')
config.bind(',n', 'config-cycle content.user_stylesheets ~/repos/solarized-everything-css/css/solarized-dark/solarized-dark-all-sites.css ""')
#config.bind(',n','set ui user-stylesheet ~/repos/solarized-everything-css/css/solarized-all-sites-dark.css "" ;; reload')

# colours:


