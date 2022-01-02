import os
import std/math
from std/strutils import parseFloat
from std/strformat import fmt

const TWO_PI = PI * 2

proc addRadialDistance(pointRad: float, lengthRad: float): float =
  let ad = PI + pointRad + lengthRad
  result = (ad mod TWO_PI) - PI

type 
  RGB = tuple
    r: float
    g: float
    b: float
  
type
  Lab = tuple
    l: float
    a: float
    b: float

# https://stackoverflow.com/questions/34472375/linear-to-srgb-conversion?rq=1
proc rgbComponentToLinearRgb(x: float): float =
  if (x >= 0.00313066844250063):
    1.055 * pow(x, (1.0 / 2.4)) - 0.055
  else:
    12.92 * x

# https://stackoverflow.com/questions/34472375/linear-to-srgb-conversion?rq=1
proc linearRgbToRgbComponent(x: float): float = 
  if x >= 0.0404482362771082:
    pow((x + 0.055) / (1.055), 2.4) 
  else:
    x / 12.92

# Reference implementation taken form https://bottosson.github.io/posts/oklab/
proc linearSrgbToOklab(c: RGB): Lab =
  let l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
  let m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
  let s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;

  let l2 = cbrt(l);
  let m2 = cbrt(m);
  let s2 = cbrt(s);

  return (
    0.2104542553 * l2 + 0.7936177850 * m2 - 0.0040720468 * s2,
    1.9779984951 * l2 - 2.4285922050 * m2 + 0.4505937099 * s2,
    0.0259040371 * l2 + 0.7827717662 * m2 - 0.8086757660 * s2,
  )

# Reference implementation taken form https://bottosson.github.io/posts/oklab/
proc oklabToLinearSrgb(c: Lab): RGB = 
    let l2 = c.l + 0.3963377774 * c.a + 0.2158037573 * c.b;
    let m2 = c.l - 0.1055613458 * c.a - 0.0638541728 * c.b;
    let s2 = c.l - 0.0894841775 * c.a - 1.2914855480 * c.b;

    let l = l2 * l2 * l2;
    let m = m2 * m2 * m2;
    let s = s2 * s2 * s2;

    return (
       4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToChroma(c: Lab): float =
  sqrt(c.a * c.a + c.b * c.b)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToHue(c: Lab): float = 
  arctan2(c.b, c.a)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToLightness(c: Lab): float = 
  c.l

proc aLab(cLab: float, hLab: float): float =
  cLab * cos(hLab)


proc bLab(cLab: float, hLab: float): float =
  cLab * sin(hLab)

proc lightness(color: Lab, lightness: float): Lab =
  (lightness, color.a, color.b)

proc hue(color: Lab, hue: float): Lab =
  let (l, _, _) = color
  let chroma = labToChroma(color)
  (l, aLab(chroma, hue), bLab(chroma, hue))

############

echo("OKlab basic implementation. Converts RGB to Oklab")

proc rgbToHexString(f: float): string =
  let i = toInt(f)
  result = fmt("{i:02X}")

# helper which takes input from CLI
proc hexToLinearRgb(h: string): float =
  let n = parseFloat(h)
  rgbComponentToLinearRgb(n / 255)

proc linearRgbToHexString(c: float): string =
  rgbToHexString(linearRgbToRgbComponent(c) * 255.0)

proc labToHex(c: Lab): string =
  let rgb = oklabToLinearSrgb(c)
  "#" & linearRgbToHexString(rgb.r) & linearRgbToHexString(rgb.g) & linearRgbToHexString(rgb.b)

############


proc generate9(color: Lab = (l: 0.7, a: 0.2, b: 0.4)): array[9, Lab] =
  const stepLength = (PI * 2) / 9 # TODO: support for narrowed scope
  var swatch = labToHue(color)
  for i in low(result)..high(result):
    result[i] = hue(color, swatch)
    swatch = addRadialDistance(swatch, stepLength)

proc generate16(color: Lab = (l: 0.7, a: 0.2, b: 0.4)): array[16, Lab] =
  const lightnessOffset = 0.1
  const stepLength = (1 - lightnessOffset * 2) / 8
  var l = lightnessOffset
  let colors = generate9()
  let bg = colors[0]
  for i in 0..8:
    result[i] = lightness(bg, l)
    l += stepLength
  var i = 8
  for c in (low(colors) + 1)..high(colors): # skip the first color - it was used for background
    result[i] = colors[c] 
    inc(i)

############

if paramCount() < 3:
  quit("Please, input an RGB color as rgb components (0-255)")


let r = hexToLinearRgb(paramStr(1))
let g = hexToLinearRgb(paramStr(2))
let b = hexToLinearRgb(paramStr(3))

let linearRgb = (r, g, b)

echo("Linear rgb values: ", linearRgb)

let lab = linearSrgbToOklab(linearRgb)

echo("Oklab values: ", lab)