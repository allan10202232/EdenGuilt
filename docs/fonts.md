# UI fonts

The shared UI theme requests **Andale Mono Regular** for English subtitles,
menus, labels and carbon readings. The opening uses the same theme.

Andale Mono is resolved from the local system, rather than copying its font
binary into the repository. Install Andale Mono on each development/playtest
machine to reproduce the intended typography. Consolas / Courier New are
monospaced fallbacks if it is absent.

Chinese glyphs use Microsoft YaHei, Noto Sans CJK SC or SimSun as available.
Keep these fallbacks so switching language does not produce missing glyphs.

Font information: https://learn.microsoft.com/en-us/typography/font-list/andale-mono
Original corefonts distribution: https://corefonts.sourceforge.net/
