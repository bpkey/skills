#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""The Matrix — wake up sequence. Runs fullscreen in a terminal."""
import curses, random, time, os, sys, subprocess

GLYPHS = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇ0123456789Z:・.\"=*+-<>¦｜"
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

def play(name, blocking=False):
    """Play a bundled wav asset via afplay; silently no-op if unavailable."""
    path = os.path.join(ASSETS, name)
    if not os.path.exists(path):
        return None
    try:
        p = subprocess.Popen(["afplay", path],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if blocking:
            p.wait()
        return p
    except Exception:
        return None

def knock():
    play("knock.wav")

def rain(stdscr, seconds, fade_in=False, skippable=True):
    stdscr.nodelay(True)
    while stdscr.getch() != -1:
        pass  # drain stale input (key repeats, queued presses, old resizes)
    h, w = stdscr.getmaxyx()
    cols = [random.randint(-h, 0) for _ in range(w)]
    speed = [random.choice([1, 1, 1, 2]) for _ in range(w)]
    start = time.time()
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
        ch = stdscr.getch()
        if ch == curses.KEY_RESIZE:
            # window resized (e.g. fullscreen transition) — adapt, never skip
            try:
                curses.update_lines_cols()
            except Exception:
                pass
            h, w = stdscr.getmaxyx()
            while len(cols) < w:
                cols.append(random.randint(-h, 0))
                speed.append(random.choice([1, 1, 1, 2]))
            stdscr.erase()
        elif ch != -1 and skippable:
            break
        time.sleep(0.045)
    stdscr.nodelay(False)

def ghost_type(stdscr, text, y=2, x=2, cps=(0.09, 0.22), blinks=4):
    stdscr.erase(); stdscr.refresh()
    time.sleep(1.2)
    for i, ch in enumerate(text):
        if ch != " ":
            play("key%d.wav" % random.randint(0, 3))
        try:
            stdscr.addstr(y, x + i, ch, curses.color_pair(2) | curses.A_BOLD)
            # blinking block cursor after the char
            stdscr.addstr(y, x + i + 1, "█", curses.color_pair(1))
        except curses.error:
            pass
        stdscr.refresh()
        time.sleep(random.uniform(*cps))
        try:
            stdscr.addstr(y, x + i + 1, " ")
        except curses.error:
            pass
    # blink cursor a few times
    for _ in range(4):
        try:
            stdscr.addstr(y, x + len(text), "█", curses.color_pair(1))
        except curses.error:
            pass
        stdscr.refresh(); time.sleep(0.4)
        try:
            stdscr.addstr(y, x + len(text), " ")
        except curses.error:
            pass
        stdscr.refresh(); time.sleep(0.35)

def dissolve(stdscr, text, y=2, x=2):
    play("glitch.wav")
    idx = list(range(len(text)))
    random.shuffle(idx)
    for i in idx:
        try:
            stdscr.addstr(y, x + i, " ")
        except curses.error:
            pass
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

    # cold open: silence, then faint rain builds under a low drone
    time.sleep(1.5)
    ambient = play("drone.wav")
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

    # the knock — the screen calls it, then reality answers
    stdscr.erase(); stdscr.refresh()
    time.sleep(1.5)
    ghost_type(stdscr, "Knock, knock, Neo.", cps=(0.12, 0.26), blinks=2)
    knock()
    time.sleep(2.6)

    # rabbit + choice (re-center on resize; only a fresh, real key advances)
    stdscr.nodelay(True)
    while stdscr.getch() != -1:
        pass  # drain queued input so a stray earlier keypress can't dismiss the rabbit
    stdscr.nodelay(False)
    play("rabbit.wav")
    msg = "🐇  follow the white rabbit — press any key"
    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        try:
            stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg, curses.color_pair(2) | curses.A_BOLD)
        except curses.error:
            pass
        stdscr.refresh()
        if stdscr.getch() != curses.KEY_RESIZE:
            break

    # swallowed back into the matrix — the finale always plays out
    ambient = play("drone.wav")
    rain(stdscr, 6, skippable=False)
    if ambient:
        ambient.terminate()
    stdscr.erase()
    h, w = stdscr.getmaxyx()
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
