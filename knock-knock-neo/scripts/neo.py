#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""The Matrix — wake up sequence. Runs fullscreen in a terminal."""
import curses, random, time, os, sys, subprocess

GLYPHS = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇ0123456789Z:・.\"=*+-<>¦｜"

def knock(n=2):
    for _ in range(n):
        subprocess.Popen(["afplay", "/System/Library/Sounds/Bottle.aiff"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.45)

def rain(stdscr, seconds, fade_in=False):
    h, w = stdscr.getmaxyx()
    cols = [random.randint(-h, 0) for _ in range(w)]
    speed = [random.choice([1, 1, 1, 2]) for _ in range(w)]
    start = time.time()
    stdscr.nodelay(True)
    while time.time() - start < seconds:
        for x in range(w - 1):
            if fade_in and random.random() > min(1.0, (time.time()-start)/2.0):
                continue
            y = cols[x]
            try:
                if 0 <= y < h:
                    stdscr.addstr(y, x, random.choice(GLYPHS), curses.color_pair(2) | curses.A_BOLD)
                if 0 <= y - 1 < h:
                    stdscr.addstr(y - 1, x, random.choice(GLYPHS), curses.color_pair(1))
                tail = y - random.randint(6, 14)
                if 0 <= tail < h:
                    stdscr.addstr(tail, x, " ")
            except curses.error:
                pass
            cols[x] += speed[x]
            if cols[x] - 14 > h:
                cols[x] = random.randint(-20, 0)
                speed[x] = random.choice([1, 1, 1, 2])
        stdscr.refresh()
        if stdscr.getch() != -1:
            break
        time.sleep(0.045)
    stdscr.nodelay(False)

def ghost_type(stdscr, text, y=2, x=2, cps=(0.09, 0.22)):
    stdscr.erase(); stdscr.refresh()
    time.sleep(1.2)
    for i, ch in enumerate(text):
        stdscr.addstr(y, x + i, ch, curses.color_pair(2) | curses.A_BOLD)
        # blinking block cursor after the char
        stdscr.addstr(y, x + i + 1, "█", curses.color_pair(1))
        stdscr.refresh()
        time.sleep(random.uniform(*cps))
        stdscr.addstr(y, x + i + 1, " ")
    # blink cursor a few times
    for _ in range(4):
        stdscr.addstr(y, x + len(text), "█", curses.color_pair(1)); stdscr.refresh(); time.sleep(0.4)
        stdscr.addstr(y, x + len(text), " "); stdscr.refresh(); time.sleep(0.35)

def dissolve(stdscr, text, y=2, x=2):
    idx = list(range(len(text)))
    random.shuffle(idx)
    for i in idx:
        stdscr.addstr(y, x + i, " ")
        stdscr.refresh()
        time.sleep(0.03)

def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)   # dim trail / cursor
    curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)   # bright head
    stdscr.bkgd(" ", curses.color_pair(1))
    stdscr.erase(); stdscr.refresh()

    # cold open: silence, then faint rain builds
    time.sleep(1.5)
    rain(stdscr, 7, fade_in=True)

    lines = [
        "Wake up, Neo...",
        "The Matrix has you...",
        "Follow the white rabbit.",
    ]
    for ln in lines:
        ghost_type(stdscr, ln)
        time.sleep(1.4)
        dissolve(stdscr, ln)
        time.sleep(0.8)

    # the knock
    stdscr.erase(); stdscr.refresh()
    time.sleep(1.5)
    knock(2)
    ghost_type(stdscr, "Knock, knock, Neo.", cps=(0.12, 0.26))
    time.sleep(2.2)

    # rabbit + choice
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    msg = "🐇  follow the white rabbit — press any key"
    try:
        stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg, curses.color_pair(2) | curses.A_BOLD)
    except curses.error:
        pass
    stdscr.refresh()
    stdscr.getch()

    # swallowed back into the matrix
    rain(stdscr, 6)
    stdscr.erase()
    bye = "There is no spoon."
    try:
        stdscr.addstr(h // 2, max(0, (w - len(bye)) // 2), bye, curses.color_pair(2) | curses.A_BOLD)
    except curses.error:
        pass
    stdscr.refresh()
    time.sleep(3)

if __name__ == "__main__":
    os.environ.setdefault("TERM", "xterm-256color")
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass
    print("\033[32mWake up.\033[0m")
