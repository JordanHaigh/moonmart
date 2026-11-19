param(
    [string]$OutputDirectory = "assets/audio/ambience/locations"
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
using System.Globalization;

public static class MoonmartLocationAmbienceBuilder
{
    private const int Rate = 44100, Frames = Rate * 32, Channels = 2;
    private sealed class Track { public string Id, Title, Description; public int Kind, Seed; }
    private static readonly Track[] Tracks = new Track[] {
        new Track { Id="bellwether_night", Title="Bellwether Night Street", Kind=0, Seed=12017,
            Description="soft distant town bed with low filtered air, slow far-off tonal swells and occasional muted high harmonics" },
        new Track { Id="whisperwood_night", Title="Whisperwood Night", Kind=1, Seed=24821,
            Description="soft leaf-like filtered rustle with rare delicate two-note night-bird calls" },
        new Track { Id="moonwater_harbour", Title="Moonwater Harbour", Kind=2, Seed=37003,
            Description="gentle water-like rolling filtered noise with occasional soft rope creak and distant buoy resonance" },
        new Track { Id="midnight_air", Title="Midnight Between Air", Kind=3, Seed=49109,
            Description="very soft airy evolving noise and warm high haze, without a pulse, impacts or ominous tones" }
    };

    public static string Build(string directory)
    {
        Directory.CreateDirectory(directory);
        StringBuilder json = new StringBuilder();
        json.AppendLine("{"); json.AppendLine("  \"schema_version\": 1,");
        json.AppendLine("  \"sample_rate\": 44100,"); json.AppendLine("  \"channels\": 2,");
        json.AppendLine("  \"bits_per_sample\": 16,"); json.AppendLine("  \"duration_seconds\": 32,");
        json.AppendLine("  \"tracks\": [");
        for (int k = 0; k < Tracks.Length; k++)
        {
            Track t = Tracks[k]; string path = Path.Combine(directory, t.Id + ".wav");
            double peak = Render(t, path);
            byte[] hash; using (SHA256 sha = SHA256.Create()) using (FileStream fs = File.OpenRead(path)) hash = sha.ComputeHash(fs);
            string hex = BitConverter.ToString(hash).Replace("-", "");
            json.AppendLine("    {");
            json.AppendLine("      \"id\": \"" + t.Id + "\",");
            json.AppendLine("      \"title\": \"" + t.Title + "\",");
            json.AppendLine("      \"path\": \"" + t.Id + ".wav\",");
            json.AppendLine("      \"description\": \"" + t.Description + "\",");
            json.AppendLine("      \"peak_dbfs\": " + (20.0 * Math.Log10(Math.Max(peak, 0.000001))).ToString("F2", CultureInfo.InvariantCulture) + ",");
            json.AppendLine("      \"bytes\": " + new FileInfo(path).Length + ",");
            json.AppendLine("      \"sha256\": \"" + hex + "\"");
            json.Append("    }"); json.AppendLine(k == Tracks.Length - 1 ? "" : ",");
        }
        json.AppendLine("  ]"); json.AppendLine("}");
        File.WriteAllText(Path.Combine(directory, "metadata.json"), json.ToString(), new UTF8Encoding(false));
        return "Built four original 32-second location ambience loops at 44.1 kHz stereo PCM.";
    }

    private static double Render(Track t, string path)
    {
        double[] l = new double[Frames], r = new double[Frames];
        uint state = (uint)t.Seed;
        double low = 0.0, mid = 0.0, high = 0.0, slow = 0.0;
        for (int i = 0; i < Frames; i++)
        {
            double sec = i / (double)Rate;
            state = 1664525u * state + 1013904223u;
            double n = (state / 4294967295.0) * 2.0 - 1.0;
            low += 0.0018 * (n - low);
            mid += 0.035 * (n - mid);
            high += 0.24 * (n - high);
            slow += 0.00013 * (n - slow);
            double left = 0.0, right = 0.0;
            double broad = 0.78 + 0.15 * Math.Sin(2 * Math.PI * 0.037 * sec + 0.3) + 0.07 * Math.Sin(2 * Math.PI * 0.071 * sec + 1.7);
            if (t.Kind == 0) // distant, soft town ambience
            {
                double texture = 0.0036 * low + 0.0011 * mid + 0.00013 * high;
                double distant = 0.00035 * Math.Sin(2 * Math.PI * 110.0 * sec + 0.1 * Math.Sin(sec * 0.23))
                    + 0.00018 * Math.Sin(2 * Math.PI * 164.8 * sec + 0.4);
                double stereo = 0.00025 * (mid - slow);
                left = texture * broad + distant + stereo;
                right = texture * broad + distant - stereo;
            }
            else if (t.Kind == 1) // filtered leaves, plus rare birdlike paired chirps
            {
                double rustle = (0.0020 * mid + 0.0010 * high) * broad;
                double chirp = Bird(sec, 5.1, 0.00018) + Bird(sec, 16.7, 0.00016) + Bird(sec, 27.4, 0.00018);
                double pan = 0.72 * Math.Sin(sec * 0.19);
                left = rustle + chirp * Math.Sqrt((1.0 - pan) * 0.5);
                right = rustle + chirp * Math.Sqrt((1.0 + pan) * 0.5);
            }
            else if (t.Kind == 2) // rolling water, soft rope and buoy resonance
            {
                double waves = 0.5 + 0.5 * Math.Sin(2 * Math.PI * 0.083 * sec + 0.2 * Math.Sin(sec * 0.17));
                double water = (0.0024 * low + 0.0016 * mid + 0.0006 * high) * (0.58 + 0.42 * waves);
                double rope = SoftEvent(sec, 8.3, 0.00034, 0.75, 71.0) + SoftEvent(sec, 22.1, 0.00028, 1.0, 63.0);
                double buoy = Bell(sec, 13.6, 0.00020, 0.95, 392.0) + Bell(sec, 29.1, 0.00016, 1.15, 349.2);
                left = water + rope * 0.85 + buoy * 0.92;
                right = water + rope * 1.08 + buoy * 1.08;
            }
            else // diffuse air, without pulse, ominous note or event
            {
                double air = 0.0013 * mid + 0.0011 * high + 0.00040 * low;
                double haze = 0.00010 * Math.Sin(2 * Math.PI * 523.25 * sec + 0.03 * Math.Sin(sec * 0.09))
                    + 0.00007 * Math.Sin(2 * Math.PI * 659.25 * sec + 0.02 * Math.Sin(sec * 0.07 + 2.0));
                double drift = 0.75 + 0.12 * Math.Sin(2 * Math.PI * 0.029 * sec + 0.8) + 0.09 * Math.Sin(2 * Math.PI * 0.047 * sec + 2.4);
                left = air * drift + haze;
                right = air * (drift + 0.025 * Math.Sin(sec * 0.21)) + haze;
            }
            l[i] = left; r[i] = right;
        }

        double peak = 0.0;
        for (int i = 0; i < Frames; i++)
        {
            double edge = Math.Min(1.0, Math.Min(i / (Rate * 0.04), (Frames - 1 - i) / (Rate * 0.04)));
            l[i] *= Math.Max(0.0, edge); r[i] *= Math.Max(0.0, edge);
            peak = Math.Max(peak, Math.Max(Math.Abs(l[i]), Math.Abs(r[i])));
        }
        double targetPeak = 0.070; // about -23 dBFS, restrained under music
        double gain = peak > 0.0 ? Math.Min(40.0, targetPeak / peak) : 1.0;
        WriteWave(path, l, r, gain);
        return Math.Min(peak * gain, 0.999);
    }

    private static double Bird(double sec, double start, double amp)
    {
        double t = sec - start;
        if (t < 0.0 || t > 0.62) return 0.0;
        double a = Chirp(t, 0.015, 0.17, 1850.0, 2480.0, amp);
        double b = Chirp(t, 0.27, 0.40, 2050.0, 2670.0, amp * 0.72);
        return a + b;
    }
    private static double Chirp(double t, double start, double end, double f0, double f1, double amp)
    {
        if (t < start || t > end) return 0.0;
        double x = t - start, d = end - start, p = Math.Max(0.0, Math.Min(1.0, x / d));
        double env = Math.Sin(Math.PI * p);
        double phase = 2.0 * Math.PI * (f0 * x + 0.5 * ((f1 - f0) / d) * x * x);
        return amp * env * Math.Sin(phase);
    }
    private static double SoftEvent(double sec, double start, double amp, double duration, double frequency)
    {
        double t = sec - start; if (t < 0.0 || t > duration) return 0.0;
        double env = Math.Pow(Math.Sin(Math.PI * t / duration), 1.4) * Math.Exp(-t * 1.2);
        return amp * env * (Math.Sin(2 * Math.PI * frequency * t) + 0.24 * Math.Sin(2 * Math.PI * frequency * 1.47 * t));
    }
    private static double Bell(double sec, double start, double amp, double duration, double f)
    {
        double t = sec - start; if (t < 0.0 || t > duration) return 0.0;
        double env = Math.Sin(Math.PI * Math.Min(1.0, t / 0.035)) * Math.Exp(-t * 3.8);
        if (t > duration - 0.08) env *= Math.Max(0.0, (duration - t) / 0.08);
        return amp * env * (Math.Sin(2 * Math.PI * f * t) + 0.19 * Math.Sin(2 * Math.PI * f * 2.76 * t + 0.3));
    }
    private static void WriteWave(string path, double[] l, double[] r, double gain)
    {
        const short bits = 16; int dataBytes = l.Length * Channels * 2;
        using (BinaryWriter w = new BinaryWriter(File.Create(path)))
        {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + dataBytes);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1);
            w.Write((short)Channels); w.Write(Rate); w.Write(Rate * Channels * 2);
            w.Write((short)(Channels * 2)); w.Write(bits); w.Write(Encoding.ASCII.GetBytes("data")); w.Write(dataBytes);
            for (int i = 0; i < l.Length; i++)
            {
                w.Write((short)Math.Round(Math.Max(-1.0, Math.Min(1.0, l[i] * gain)) * 32767.0));
                w.Write((short)Math.Round(Math.Max(-1.0, Math.Min(1.0, r[i] * gain)) * 32767.0));
            }
        }
    }
}
'@

$outputAbsolute = [System.IO.Path]::GetFullPath($OutputDirectory)
[MoonmartLocationAmbienceBuilder]::Build($outputAbsolute)
