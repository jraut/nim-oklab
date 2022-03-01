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

proc clamp(d: float, min: float, max: float): float =
  let t = if (d < min): min else: d
  return if (t > max): max else: t


# https://stackoverflow.com/questions/34472375/linear-to-srgb-conversion?rq=1
proc rgbComponentToLinearRgb(x: float): float =
  if (x >= 0.00313066844250063):
    1.055 * pow(x, (1.0 / 2.4)) - 0.055
  else:
    12.92 * x

# https://stackoverflow.com/questions/34472375/linear-to-srgb-conversion?rq=1
proc linearRgbComponentToRgb(x: float): float =
  if x >= 0.0404482362771082:
    pow((x + 0.055) / (1.055), 2.4)
  else:
    x / 12.92

proc linearRgbToRgb(c: RGB): RGB =
  return (r: clamp(linearRgbComponentToRgb(c.r), 0.0, 1.0), g: clamp(linearRgbComponentToRgb(c.g), 0.0, 1.0), b: clamp(linearRgbComponentToRgb(c.b), 0.0, 1.0))

proc rgbToLinearRgb(c: RGB): RGB =
  return (r: clamp(rgbComponentToLinearRgb(c.r), 0.0, 1.0), g: clamp(rgbComponentToLinearRgb(c.g), 0.0, 1.0), b: clamp(rgbComponentToLinearRgb(c.b), 0.0, 1.0))
# Reference implementation taken form https://bottosson.github.io/posts/oklab/

proc linearSrgbToOklab(c: RGB): Lab =
  let l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b
  let m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b
  let s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b

  let l2 = cbrt(l)
  let m2 = cbrt(m)
  let s2 = cbrt(s)

  return (
    0.2104542553 * l2 + 0.7936177850 * m2 - 0.0040720468 * s2,
    1.9779984951 * l2 - 2.4285922050 * m2 + 0.4505937099 * s2,
    0.0259040371 * l2 + 0.7827717662 * m2 - 0.8086757660 * s2,
  )

# Reference implementation taken form https://bottosson.github.io/posts/oklab/
proc oklabToLinearSrgb(c: Lab): RGB =
  let l2 = c.l + 0.3963377774 * c.a + 0.2158037573 * c.b
  let m2 = c.l - 0.1055613458 * c.a - 0.0638541728 * c.b
  let s2 = c.l - 0.0894841775 * c.a - 1.2914855480 * c.b

  let l = l2 * l2 * l2
  let m = m2 * m2 * m2
  let s = s2 * s2 * s2

  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  )


# Implementation taken form https://bottosson.github.io/posts/oklab/
proc chroma(c: Lab): float =
  sqrt(c.a * c.a + c.b * c.b)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc hue(c: Lab): float =
  arctan2(c.b, c.a)

# Implementation taken form https://bottosson.github.io/posts/oklab/
proc lightness(c: Lab): float =
  c.l

proc aLab(cLab: float, hLab: float): float =
  cLab * cos(hLab)


proc bLab(cLab: float, hLab: float): float =
  cLab * sin(hLab)

proc setLightness(color: Lab, lightness: float): Lab =
  (lightness, color.a, color.b)

proc setHue(color: Lab, hue: float): Lab =
  let (l, _, _) = color
  let chroma = chroma(color)
  (l, aLab(chroma, hue), bLab(chroma, hue))

proc setChroma(color: Lab, chroma: float): Lab =
  let (l, _, _) = color
  let hue = hue(color)
  (l, aLab(chroma, hue), bLab(chroma, hue))

############

echo("OKlab basic implementation. Converts RGB to Oklab")

proc rgbComponentToHexString(f: float): string =
  let i = toInt(f)
  result = fmt("{i:02X}")

# helper which takes input from CLI
proc hexToLinearRgb(h: string): float =
  let n = parseFloat(h)
  rgbComponentToLinearRgb(n / 255)

proc linearRgbToHexString(c: float): string =
  rgbComponentToHexString(linearRgbComponentToRgb(c) * 255.0)

proc labToHex(c: Lab): string =
  let rgb = oklabToLinearSrgb(c)
  let srgb = linearRgbToRgb(rgb)
  "#" & rgbComponentToHexString(srgb.r * 255) & rgbComponentToHexString(srgb.g * 255) & rgbComponentToHexString(srgb.b * 255)

proc colorSchemePrint(colors: array[16, Lab]): string =
  result = result & "scheme: \"Base16-generated\"\n"
  result &= "author: \"Juho Rautioaho\"\n"
  for i in low(colors)..high(colors):
    let color = labToHex(colors[i])
    result &= fmt("base{i:02X}: {color}\n")

############


proc generateColor(color: Lab, steplength: float, i: int): Lab =
  let h = hue(color)
  setHue(color, addRadialDistance(h, steplength * float(i)))


proc generate9(color: Lab = (l: 0.7, a: 0.2, b: 0.4)): array[9, Lab] =
  const stepLength = (PI * 2) / 9 # TODO: support for narrowed scope
  for i in low(result)..high(result):
    result[i] = generateColor(color, stepLength, i)

proc generate16(color: Lab = (l: 0.7, a: 0.2, b: 0.4)): array[16, Lab] =
  const gradientStepN = 7
  const lightnessOffset = 0.6
  const chromaOffset = 0.9
  const lightnessStepLength = (1 - lightnessOffset) / (gradientStepN - 1)
  const chromaStepLength = (1 - chromaOffset) / (gradientStepN)
  var l = lightnessOffset
  var c = 1.0 - chromaOffset
  # 0-7 are same colour in 8-step gradient from dark to light (or light to dark)
  for i in 0..gradientStepN:
    result[i] = setLightness(setChroma(color, max(0.001, c)), min(1.0, l))
    l += lightnessStepLength
    c -= chromaStepLength

  result[8] = color
  c = chroma(color)
  l = lightness(color)
  let colorStepLength = (PI * 2) / 8
  # 8-15 are highlight colors, first with the requested color
  for i in 9..15: # skip the first color - it was used for background
    c = if i mod 2 == 0: 0.06 else: 0.06
    l = if i mod 2 == 0: 0.88 else: 0.98
    let granularity = int(i / 2) * 2 # this makes the color stall between colors
    result[i] = setLightness(setChroma(generateCOlor(color, colorStepLength, granularity), c), l)

############

if paramCount() < 3:
  quit("Please, input an RGB color as rgb components (0-255)")

let r = hexToLinearRgb(paramStr(1))
let g = hexToLinearRgb(paramStr(2))
let b = hexToLinearRgb(paramStr(3))

let linearRgb = (r, g, b)
let lab = linearSrgbToOklab(linearRgb)

echo("Linear rgb: ", linearRgb)
echo("Oklab: ", lab)
echo("Hex: ", labToHex(lab))

# let labLight = lightness(lab, 1.0)
# echo("Oklab values (full lightness): ", labLight)

echo("Base16 palette as Lab values:")
echo("\n\n", colorSchemePrint(generate16(lab)))
