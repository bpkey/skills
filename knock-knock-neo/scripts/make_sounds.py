#!/usr/bin/env python3
"""Generate the skill's .wav sound assets into ../assets/. Stdlib only — no numpy.

Run once when tweaking the sound design:  python3 make_sounds.py
The generated wavs are committed; neo.py only plays them (afplay).
"""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")


def write_wav(name, samples, peak=None):
    """peak=None: only normalize DOWN if clipping; peak=x: normalize to exactly x."""
    os.makedirs(OUT, exist_ok=True)
    top = max(1e-9, max(abs(s) for s in samples))
    target = peak if peak is not None else min(0.9, top)
    norm = target / top
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * norm)) * 32767))
            for s in samples))
    print(f"wrote {path} ({len(samples)/SR:.2f}s)")


def silence(sec):
    return [0.0] * int(SR * sec)


def env_exp(n, decay):
    return [math.exp(-decay * i / SR) for i in range(n)]


def key_click(seed):
    """Movie-style terminal tick: a dry, sharp data-click — no keyboard thock.

    Very short (~22 ms), all high-mid energy: high-passed noise snap plus a
    bright resonance, decaying almost instantly. Four seeds give four
    slightly different pitches so rapid typing doesn't sound machine-gun.
    """
    rng = random.Random(seed)
    n = int(SR * 0.022)
    f1 = rng.uniform(3100, 5200)          # bright click resonance
    f2 = f1 * rng.uniform(1.9, 2.3)       # faint upper partial
    out, hp, prev = [], 0.0, 0.0
    for i in range(n):
        t = i / SR
        e = math.exp(-380 * t)
        noise = rng.uniform(-1, 1)
        hp = 0.65 * (hp + noise - prev)   # crude high-pass on the noise
        prev = noise
        tone = math.sin(2 * math.pi * f1 * t) + 0.35 * math.sin(2 * math.pi * f2 * t)
        out.append((0.5 * hp + 0.7 * tone) * e)
    return out


def knock_rap(rng, strength=1.0, detune=1.0):
    """One rap on a hollow wooden door: knuckle thwack + ringing panel modes."""
    n = int(SR * 0.55)
    modes = [(66 * detune, 22, 1.0), (109 * detune, 28, 0.75), (172 * detune, 36, 0.5),
             (243 * detune, 48, 0.35), (327 * detune, 60, 0.22)]
    out, lp = [], 0.0
    for i in range(n):
        t = i / SR
        s = 0.0
        for f, d, a in modes:
            s += a * math.sin(2 * math.pi * f * t) * math.exp(-d * t)
        noise = rng.uniform(-1, 1)
        lp += 0.25 * (noise - lp)
        s += 1.6 * lp * math.exp(-90 * t)             # knuckle impact thwack
        out.append(strength * 0.5 * s)
    return out


def door_knock():
    """Three quick knuckle-raps on an apartment door, with room reflections."""
    rng = random.Random(7)
    raps = [(0.0, 1.0), (0.165, 0.92), (0.335, 1.05)]  # quick knock-knock-knock
    total = int(SR * 1.5)
    dry = [0.0] * total
    for at, strength in raps:
        rap = knock_rap(rng, strength, detune=rng.uniform(0.96, 1.04))
        o = int(SR * at)
        for i, s in enumerate(rap):
            if o + i < total:
                dry[o + i] += s
    out = dry[:]
    for delay, gain in ((0.021, 0.30), (0.043, 0.22), (0.071, 0.15), (0.113, 0.09)):
        d = int(SR * delay)
        for i in range(d, total):
            out[i] += gain * dry[i - d]
    return out


def drone(sec):
    """Low ominous pad: detuned sines + slow shimmer, fades in and out."""
    n = int(SR * sec)
    out = []
    for i in range(n):
        t = i / SR
        fade = min(1.0, t / 2.5, (sec - t) / 2.0)
        s = (math.sin(2 * math.pi * 55 * t)
             + 0.8 * math.sin(2 * math.pi * 55.7 * t)
             + 0.35 * math.sin(2 * math.pi * 110.3 * t)
             + 0.15 * math.sin(2 * math.pi * 220 * t + 2 * math.sin(2 * math.pi * 0.13 * t)))
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 0.21 * t)
        out.append(0.28 * s * trem * fade)
    return out


def glitch():
    """Digital dissolve: descending granular zipper."""
    rng = random.Random(3)
    out = []
    steps = 22
    for k in range(steps):
        f = 2400 * (1 - k / steps) + 180
        n = int(SR * 0.028)
        for i in range(n):
            e = math.exp(-60 * i / SR)
            s = math.sin(2 * math.pi * f * i / SR) + 0.4 * rng.uniform(-1, 1)
            out.append(0.5 * s * e * (1 - k / (steps + 4)))
    return out


def rabbit():
    """Soft bright ping for the white-rabbit prompt."""
    n = int(SR * 0.9)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-4 * t)
        out.append(0.5 * (math.sin(2 * math.pi * 880 * t)
                          + 0.5 * math.sin(2 * math.pi * 1320 * t)) * e)
    return out


if __name__ == "__main__":
    for i in range(4):
        write_wav(f"key{i}.wav", key_click(seed=11 + i), peak=0.5)
    write_wav("knock.wav", door_knock(), peak=0.9)
    write_wav("drone.wav", drone(12.0))
    write_wav("glitch.wav", glitch())
    write_wav("rabbit.wav", rabbit())
