param([string]$OutputRoot = "")

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $projectRoot "assets\audio" }
$ambientPath = Join-Path $OutputRoot "ambience\shop"
$sfxPath = Join-Path $OutputRoot "sfx"
New-Item -ItemType Directory -Force -Path $ambientPath, $sfxPath | Out-Null

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;

public static class MoonmartShopAudio {
  const int Rate = 44100;
  static double Sine(double hz, double t) { return Math.Sin(2.0 * Math.PI * hz * t); }
  static double Bell(double hz, double t, double decay, double phase) {
    return Math.Exp(-t / decay) * (0.78 * Sine(hz, t + phase) + 0.18 * Sine(hz * 2.73, t + phase) + 0.08 * Sine(hz * 5.41, t + phase));
  }
  static double Tick(double t) {
    if (t < 0 || t > 0.12) return 0;
    double attack = Math.Min(1.0, t / 0.0007);
    return attack * Math.Exp(-t / 0.016) * (0.72 * Sine(2450, t) + 0.28 * Sine(1420, t));
  }
  static double EventCar(double t, double center, double duration, double pan, double time) {
    double x = (time - center) / duration;
    if (Math.Abs(x) > 1.0) return 0;
    double envelope = Math.Pow(Math.Max(0.0, Math.Cos(x * Math.PI / 2.0)), 1.8);
    double low = 0.68 * Sine(63.0 + 3.0 * x, t) + 0.23 * Sine(126.0 + 5.0 * x, t) + 0.09 * Sine(189.0 + 7.0 * x, t);
    double filtered = 0.08 * Sine(420.0 + 40.0 * x, t) + 0.04 * Sine(690.0 + 70.0 * x, t);
    return envelope * (low + filtered) * (0.88 + 0.12 * pan);
  }
  static double Sample(string kind, double t, double duration) {
    if (kind == "refrigerator_hum") {
      return 0.70 * Sine(60, t) + 0.20 * Sine(120, t + 0.002) + 0.08 * Sine(180, t + 0.006) + 0.035 * Sine(3.0, t) * Sine(60, t);
    }
    if (kind == "clock_tick") return 0.72 * Tick(t % 2.0);
    if (kind == "distant_cars") {
      return EventCar(t, 5.2, 4.4, -0.35, t) + EventCar(t, 13.8, 5.0, 0.48, t) + EventCar(t, 23.0, 4.2, 0.15, t) + EventCar(t, 29.0, 3.0, -0.1, t);
    }
    if (kind == "miso_purr") {
      double pulse = 0.70 + 0.30 * Math.Cos(2.0 * Math.PI * 2.5 * t);
      double rumble = 0.62 * Sine(31.25, t) + 0.24 * Sine(62.5, t + 0.004) + 0.10 * Sine(125, t + 0.007) + 0.04 * Sine(250, t);
      return pulse * rumble;
    }
    if (kind == "footstep") {
      double a = Math.Exp(-Math.Max(0, t) / 0.085) * Math.Max(0, 1.0 - t / 0.19);
      double thump = t >= 0 ? a * (0.62 * Sine(78, t) + 0.22 * Sine(156, t)) : 0;
      double scuffT = t - 0.028;
      double scuff = scuffT >= 0 ? Math.Exp(-scuffT / 0.035) * 0.16 * (Sine(480, scuffT) + 0.55 * Sine(760, scuffT)) : 0;
      return thump + scuff;
    }
    if (kind == "ceramic_cup") {
      return (t >= 0 ? 0.56 * Bell(712, t, 0.39, 0.0) : 0)
        + (t >= 0.19 ? 0.42 * Bell(967, t - 0.19, 0.28, 0.01) : 0)
        + (t >= 0.47 ? 0.20 * Bell(584, t - 0.47, 0.31, 0.0) : 0);
    }
    return 0;
  }
  public static void Write(string path, string kind, double seconds, double targetPeak) {
    int frames = (int)Math.Round(seconds * Rate);
    double[] left = new double[frames], right = new double[frames];
    double peak = 0;
    for (int i = 0; i < frames; i++) {
      double t = (double)i / Rate;
      double value = Sample(kind, t, seconds);
      double l = value, r = value;
      if (kind == "distant_cars") {
        l = Sample(kind, t, seconds) * 0.96;
        r = Sample(kind, t + 0.011, seconds) * 0.90;
      } else if (kind == "ceramic_cup") {
        l = value * (0.98 + 0.02 * Math.Sin(2.0 * Math.PI * 1.7 * t));
        r = value * (0.94 + 0.06 * Math.Sin(2.0 * Math.PI * 1.3 * t + 0.4));
      }
      left[i] = l; right[i] = r;
      peak = Math.Max(peak, Math.Max(Math.Abs(l), Math.Abs(r)));
    }
    if (peak < 1e-8) throw new Exception("Synthesis produced silence: " + kind);
    double gain = targetPeak / peak;
    using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write))
    using (BinaryWriter w = new BinaryWriter(fs)) {
      int bytes = frames * 4;
      w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + bytes); w.Write(Encoding.ASCII.GetBytes("WAVE"));
      w.Write(Encoding.ASCII.GetBytes("fmt ")); w.Write(16); w.Write((short)1); w.Write((short)2);
      w.Write(Rate); w.Write(Rate * 4); w.Write((short)4); w.Write((short)16);
      w.Write(Encoding.ASCII.GetBytes("data")); w.Write(bytes);
      for (int i = 0; i < frames; i++) {
        w.Write((short)Math.Round(Math.Max(-1, Math.Min(1, left[i] * gain)) * 32767));
        w.Write((short)Math.Round(Math.Max(-1, Math.Min(1, right[i] * gain)) * 32767));
      }
    }
  }
}
'@

$assets = @(
  @{ Path = $ambientPath; Name = "refrigerator_hum.wav"; Kind = "refrigerator_hum"; Seconds = 8.0; Peak = 0.11 },
  @{ Path = $ambientPath; Name = "clock_tick.wav"; Kind = "clock_tick"; Seconds = 4.0; Peak = 0.18 },
  @{ Path = $ambientPath; Name = "distant_cars.wav"; Kind = "distant_cars"; Seconds = 32.0; Peak = 0.12 },
  @{ Path = $ambientPath; Name = "miso_purr.wav"; Kind = "miso_purr"; Seconds = 2.4; Peak = 0.14 },
  @{ Path = $sfxPath; Name = "moonmart_footstep.wav"; Kind = "footstep"; Seconds = 0.24; Peak = 0.30 },
  @{ Path = $sfxPath; Name = "moonmart_ceramic_cup.wav"; Kind = "ceramic_cup"; Seconds = 1.35; Peak = 0.30 }
)
foreach ($asset in $assets) {
  $path = Join-Path $asset.Path $asset.Name
  [MoonmartShopAudio]::Write($path, $asset.Kind, $asset.Seconds, $asset.Peak)
  [pscustomobject]@{ file = $path.Substring($projectRoot.Length + 1); sample_rate_hz = 44100; channels = 2; bit_depth = 16; duration_seconds = $asset.Seconds; source_model = $asset.Kind; peak = $asset.Peak }
}
