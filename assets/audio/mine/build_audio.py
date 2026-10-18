"""Authored, deterministic mine Foley and seamless atmospheric beds.

Layered filtered noise, sampled impacts and inharmonic struck resonances. No
third-party recordings; rerunning this file reproduces every shipped WAV.
"""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parent
TAU = math.tau


def save(name, data, peak=.76, loop=False):
    if loop:
        # Equal-power wrap makes both random beds and reverb tails seam-free.
        fade = int(RATE * .8)
        tail, head = data[-fade:], data[:fade]
        data = data[:-fade]
        for i in range(fade):
            x = i / fade
            data[i] = tail[i] * math.cos(x * math.pi / 2) + head[i] * math.sin(x * math.pi / 2)
    maximum = max(abs(v) for v in data) or 1
    pcm = b''.join(struct.pack('<h', round(max(-1, min(1, x / maximum * peak)) * 32767)) for x in data)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as target:
        target.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        target.writeframes(pcm)


def foley(name, duration, seed):
    rng = random.Random(seed)
    result, low, medium = [], 0., 0.
    for i in range(int(duration * RATE)):
        t = i / RATE
        p = t / duration
        noise = rng.uniform(-1, 1)
        low += (noise - low) * .035
        medium += (noise - medium) * .22
        grit = noise - medium
        attack = min(1, t / .007)
        if name in ('mineralize', 'resonance'):
            bloom = math.sin(math.pi * p) ** 1.1 * math.exp(-p * 2.2)
            chime = sum(math.sin(TAU * f * t) * math.exp(-t * d) for f, d in ((293.66, 4), (440.3, 5), (628.2, 6), (951.7, 8)))
            value = (medium * 1.5 + low * 2.2) * bloom + chime * .12 * attack * math.exp(-t * 4)
        elif name == 'crystal_break':
            crunch = (.65 * grit + medium) * attack * math.exp(-t * 12)
            crystals = sum(math.sin(TAU * f * t) * math.exp(-t * d) for f, d in ((1237, 19), (1861, 24), (2603, 30), (3407, 35)))
            value = crunch + crystals * .09 * attack
            for moment in (.06, .13, .22):
                if t > moment:
                    value += grit * .24 * math.exp(-(t - moment) * 65)
        elif name == 'warning':
            value = (grit * .18 + medium * .14) * attack * math.exp(-t * 40)
            value += sum(math.sin(TAU * f * t) for f in (1107, 1583, 2377)) * .065 * math.exp(-t * 27) * attack
        elif name in ('valve', 'lever'):
            clunk = math.sin(TAU * 83 * t) * math.exp(-t * 22) + low * 3 * math.exp(-t * 13)
            hiss = medium * math.sin(math.pi * p) * .8
            ratchet = grit * (.35 if math.sin(t * 310) > .8 else .03) * math.exp(-t * 6)
            metal = sum(math.sin(TAU * f * t) * math.exp(-t * 35) for f in (347, 597, 1109)) * .10
            value = (clunk + hiss + ratchet + metal) * attack
        elif name == 'acid':
            bubbles = abs(math.sin(t * 43 + math.sin(t * 21))) ** 14
            value = (low * 3.5 + medium * .6 + grit * .08) * math.sin(math.pi * p) ** .6
            value += bubbles * math.sin(TAU * (180 - p * 110) * t) * .22 * (1 - p)
        elif name in ('jump', 'double_jump'):
            whoosh = math.sin(math.pi * p) ** 1.4
            value = (medium * .85 + low * 2.2) * whoosh
            value += grit * .19 * math.exp(-t * 52) * attack
            if name == 'double_jump':
                value += sum(math.sin(TAU * f * t) for f in (587.3, 882.6, 1318.1)) * .04 * attack * math.exp(-t * 16)
        elif name in ('land', 'footstep'):
            value = (low * 3.8 + medium * .35 + grit * .11) * attack * math.exp(-t * 32)
            value += math.sin(TAU * 94 * t) * .19 * attack * math.exp(-t * 40)
        elif name == 'hurt':
            value = (low * 2.5 + medium * .5 + grit * .22) * attack * math.exp(-t * 16)
            value += math.sin(TAU * (87 - t * 25) * t) * .22 * attack * math.exp(-t * 17)
        else:  # Exit: resolving, naturally decaying crystal interval.
            value = sum(math.sin(TAU * f * t) * math.exp(-t * d) for f, d in ((293.66, 2), (440, 2.5), (587.33, 3), (880, 4))) * .15 * min(1, t / .03)
            value += medium * .06 * math.exp(-t * 5)
        result.append(value * min(1, (duration - t) / .025))
    # Short physical room reflections, kept below the dry sound.
    original = result[:]
    for seconds, amount in ((.039, .15), (.083, .085), (.137, .04)):
        delay = int(seconds * RATE)
        for i in range(delay, len(result)):
            result[i] += original[i - delay] * amount
    save(name, result)


def atmosphere():
    rng = random.Random(1932)
    duration = 16.8
    result, low, lower = [], 0., 0.
    for i in range(int(duration * RATE)):
        t = i / RATE
        n = rng.uniform(-1, 1)
        low += (n - low) * .011
        lower += (n - lower) * .002
        wind = low * (1 + math.sin(t * .63) * .25) + lower * 3
        machine = math.sin(TAU * 47 * t + .15 * math.sin(t * .8)) * .025
        machine += math.sin(TAU * 71 * t) * .014 * (1 + math.sin(t * 5.4) * .4)
        # Sparse pipe drops with water and hollow-metal partials.
        drip = 0
        for start in (1.4, 4.6, 8.7, 12.1, 15.3):
            dt = t - start
            if 0 < dt < .65:
                drip += (math.sin(TAU * 821 * dt) * .014 + math.sin(TAU * 1277 * dt) * .008) * math.exp(-dt * 14)
        result.append(wind * .55 + machine + drip)
    save('mine_ambience', result, .43, True)


def score():
    duration = 24.8
    result = [0.] * int(duration * RATE)
    # Slow bowed-mineral harmony with enough space for wind, feet and mechanics.
    notes = [(0, 146.83), (3, 220), (6, 174.61), (9, 261.63), (12, 196), (15, 293.66), (18, 164.81), (21, 220)]
    for start, frequency in notes:
        for i in range(int(5.0 * RATE)):
            at = int(start * RATE) + i
            if at >= len(result): break
            t = i / RATE
            env = min(1, t / .85) * math.exp(-t * .7) * min(1, (5 - t) / .5)
            sample = 0
            for ratio, weight in ((1, .18), (2.002, .055), (3.01, .022), (5.017, .01)):
                sample += math.sin(TAU * frequency * ratio * t + .12 * math.sin(t * 4.3)) * weight
            result[at] += sample * env
    save('mine_score', result, .31, True)


if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    for index, (name, duration) in enumerate((('mineralize', .62), ('resonance', .46), ('crystal_break', .36), ('warning', .14), ('valve', .64), ('lever', .42), ('acid', .55), ('jump', .20), ('double_jump', .24), ('land', .18), ('footstep', .1), ('hurt', .24), ('clear', 1.7))):
        foley(name, duration, 400 + index)
    atmosphere()
    score()
    print('Built 13 layered mine Foley cues and two seamless atmospheric loops.')
