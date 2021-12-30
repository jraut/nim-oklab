import os
import std/math
from std/parseUtils import parseHex
from std/strutils import parseFloat

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
      +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToChroma(c: Lab): float =
  cbrt(c.a * c.a + c.b * c.b)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToHue(c: Lab): float = 
  arctan2(c.b, c.a)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc labToLightness(c: Lab): float = 
  1 / (labToChroma(c) * labToHue(c))

echo("OKlab basic implementation. Converts RGB to Oklab")

# helper which takes input from CLI
proc hexToLinearRgb(h: string): float =
  rgbComponentToLinearRgb(parseFloat(h) / 255)

if paramCount() < 3:
  quit("Please, input an RGB color as rgb components (0-255)")


let r = hexToLinearRgb(paramStr(1))
let g = hexToLinearRgb(paramStr(2))
let b = hexToLinearRgb(paramStr(3))

let linearRgb = (r, g, b)

echo("Linear rgb values: ", linearRgb)

let lab = linearSrgbToOklab(linearRgb)

echo("Oklab values: ", lab)