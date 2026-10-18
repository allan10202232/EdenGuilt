"""Deterministic layered combat Foley: filtered noise, transients and resonances."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 44100
OUTPUT = Path(__file__).resolve().parent


def render(name, duration, weight, seed):
    rng = random.Random(seed)
    samples = []
    low = 0.0
    phase = 0.0
    swing = name.startswith("slash")
    landing = name == "land"
    for index in range(int(duration * RATE)):
        t = index / RATE
        p = t / duration
        noise = rng.uniform(-1.0, 1.0)
        low += (noise - low) * (0.13 if swing else 0.045)
        high = noise - low
        if swing:
            envelope = math.sin(math.pi * p) ** 1.5 * (1.0 - p) ** 0.45
            frequency = (1100.0 - p * 780.0) / weight
            phase += math.tau * frequency / RATE
            value = (high * 0.60 + low * 1.2 + math.sin(phase) * 0.08) * envelope
        else:
            attack = min(1.0, t / 0.0015)
            envelope = attack * math.exp(-t * (21.0 if landing else 29.0) / weight)
            body = math.sin(math.tau * (82.0 / weight) * t) * math.exp(-t * 18.0)
            metal = (math.sin(math.tau * 1283 * t) + math.sin(math.tau * 1931 * t) * .4) * math.exp(-t * 48)
            value = (low * 2.5 + high * (0.35 if landing else 0.65) + body * .7 + metal * (0.0 if landing else .17)) * envelope
            if name == "enemy_break":
                value += high * math.exp(-t * 9.0) * (0.1 + 0.3 * abs(math.sin(t * 43)))
        samples.append(value)
    peak = max(abs(value) for value in samples)
    pcm = b"".join(struct.pack("<h", round(value / peak * 25000)) for value in samples)
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as target:
        target.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        target.writeframes(pcm)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for arguments in [
        ("slash_close", .16, .85, 11), ("slash_reach", .24, 1.25, 12),
        ("impact_light", .18, .85, 21), ("impact_heavy", .28, 1.35, 22),
        ("enemy_break", .32, 1.1, 31), ("land", .15, .8, 41),
    ]:
        render(*arguments)
    print("Built six mono PCM combat sounds (44.1 kHz, peak below clipping).")
