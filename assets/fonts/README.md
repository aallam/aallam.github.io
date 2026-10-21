# Web fonts

These WOFF2 files are unchanged copies of the Google Fonts assets previously
loaded by the shared page layout. All existing language subsets are retained;
the browser downloads only faces needed by the current page. Normal Latin
Newsreader and Source Sans 3 are preloaded for above-the-fold text.

| Family | Google Fonts version | License |
| --- | --- | --- |
| Newsreader | v26 | [SIL OFL 1.1](newsreader-OFL.txt) |
| Source Sans 3 | v20 | [SIL OFL 1.1](sourcesans3-OFL.txt) |
| JetBrains Mono | v24 | [SIL OFL 1.1](jetbrainsmono-OFL.txt) |

The file names record family, version, style, and language subset. Face declarations
and Unicode ranges are in `_includes/fonts.scss`; weight declarations share the
same variable font files rather than duplicating downloads. Newsreader retains
its optical-size axis. Keep the licenses when updating these assets.

Source: [Google Fonts CSS API](https://developers.google.com/fonts/docs/css2).
