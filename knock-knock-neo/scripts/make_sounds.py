#!/usr/bin/env python3
"""Generate the skill's .wav sound assets into ../assets/. Stdlib only — no numpy.

Run once when tweaking the sound design:  python3 make_sounds.py
The generated wavs are committed; neo.py only plays them (afplay).
"""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = 0.9 / peak if peak > 0.9 else 1.0
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
    """Mechanical keyboard clack: filtered noise burst + tiny resonant ping."""
    rng = random.Random(seed)
    n = int(SR * 0.055)
    freq = rng.uniform(1800, 2600)
    out, lp = [], 0.0
    for i, e in enumerate(env_exp(n, 90)):
        noise = rng.uniform(-1, 1)
        lp += 0.45 * (noise - lp)                      # crude low-pass on the noise
        ping = 0.35 * math.sin(2 * math.pi * freq * i / SR)
        out.append((0.8 * lp + ping) * e)
    # bottom-out thock
    for i, e in enumerate(env_exp(int(SR * 0.03), 140)):
        out[i] += 0.5 * math.sin(2 * math.pi * 160 * i / SR) * e
    return out


def knock():
    """Deep knuckles-on-wood: low damped thump + short knock transient."""
    n = int(SR * 0.35)
    rng = random.Random(7)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-18 * t)
        body = math.sin(2 * math.pi * 82 * t * (1 - 0.3 * t)) * e      # pitch droops
        wood = 0.4 * math.sin(2 * math.pi * 190 * t) * math.exp(-30 * t)
        crack = 0.5 * rng.uniform(-1, 1) * math.exp(-220 * t)
        out.append(body + wood + crack)
    return out


def double_knock():
    return knock() + silence(0.28) + knock()


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
        write_wav(f"key{i}.wav", key_click(seed=11 + i))
    write_wav("knock.wav", double_knock())
    write_wav("drone.wav", drone(12.0))
    write_wav("glitch.wav", glitch())
    write_wav("rabbit.wav", rabbit())
