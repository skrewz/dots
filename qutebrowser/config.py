# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

config.load_autoconfig()
config.set('url.searchengines', {
    "DEFAULT": "https://duckduckgo.com/?q={}", 
    "wk": "https://www.wiktionary.org/search-redirect.php?family=wiktionary&language=en&search={}&go=Go",
    "wp": "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go"
})

# Privacy centric stuff:
#
# Also spawn with: `--qt-flag disable-reading-from-canvas`
# And to get private tabs "by default", `--target window ':open -p duckduckgo.com'` does the tric.
# Cf. https://github.com/qutebrowser/qutebrowser/issues/2235
config.set('content.headers.accept_language','en-US,en;q=0.5')
config.set('content.headers.custom',{"accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})


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

config.bind('<Ctrl-l>', 'spawn --userscript qute-pass')

config.bind(',<Left>', 'set tabs.position left')
config.bind(',<Up>'  , 'set tabs.position top')
