param(
    [string]$OutputDirectory = "assets/audio/narrative"
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;

public static class MoonmartNarrativeOverlayBuilder
{
    private const int Rate = 44100;
    private const int Frames = Rate * 32;

    public static string Build(string directory)
    {
        Directory.CreateDirectory(directory);
        double[] left = new double[Frames];
        double[] right = new double[Frames];

        // Eight slow, four-second bars: an open C-major palette moves through
        // gentle extensions and returns home, like a remembered threshold becoming safe.
        int[][] harmony = new int[][] {
            new int[] {48,55,60,64,71}, new int[] {45,52,57,60,64},
            new int[] {41,48,53,57,60}, new int[] {43,50,55,59,62},
            new int[] {48,55,60,64,71}, new int[] {50,57,60,64,69},
            new int[] {43,50,55,60,64}, new int[] {48,55,60,64,72}
        };
        int[] motif = new int[] {76,79,83,81,79,76,74,76,79,83,84,83,79,76,74,72};
        for (int bar = 0; bar < 8; bar++)
        {
            double start = bar * 4.0;
            for (int n = 0; n < harmony[bar].Length; n++)
            {
                double pan = (n - 2) * 0.12;
                AddSwell(left, right, Freq(harmony[bar][n]), start, 4.35, 0.0026, pan, n + bar * 3);
            }

            // Two widely spaced, rounded glass notes leave room for the location score.
            AddNote(left, right, Freq(motif[bar * 2]), start + 0.72, 1.55, 0.0062, -0.18, 0);
            AddNote(left, right, Freq(motif[bar * 2 + 1]), start + 2.52, 1.30, 0.0050, 0.18, 1);
            // A very soft lower resonance marks the phrase without adding a beat.
            AddNote(left, right, Freq(harmony[bar][0] - 12), start + 0.18, 2.7, 0.0021, 0.0, 2);
        }

        double peak = 0.0;
        for (int i = 0; i < Frames; i++)
        {
            // A short symmetric edge fade makes the first and final stereo frames exactly silent.
            double edge = Math.Min(1.0, Math.Min(i / (Rate * 0.04), (Frames - 1 - i) / (Rate * 0.04)));
            left[i] *= Math.Max(0.0, edge);
            right[i] *= Math.Max(0.0, edge);
            peak = Math.Max(peak, Math.Max(Math.Abs(left[i]), Math.Abs(right[i])));
        }
        // Keep this overlay tucked under location music with ample headroom.
        double gain = peak > 0.0 ? Math.Min(12.0, 0.115 / peak) : 1.0;
        string path = Path.Combine(directory, "remembered_threshold.wav");
        WriteWave(path, left, right, gain);
        double peakDb = 20.0 * Math.Log10(Math.Max(peak * gain, 0.000001));
        string json = "{\n" +
            "  \"schema_version\": 1,\n" +
            "  \"id\": \"remembered_threshold\",\n" +
            "  \"title\": \"Remembered Threshold\",\n" +
            "  \"path\": \"remembered_threshold.wav\",\n" +
            "  \"purpose\": \"quiet, no-vocal narrative music overlay for location scores\",\n" +
            "  \"arrangement\": \"open C-major extensions, slow warm resonance, sparse rounded glass notes; recalls a doorway becoming safe\",\n" +
            "  \"sample_rate\": 44100,\n  \"channels\": 2,\n  \"bits_per_sample\": 16,\n" +
            "  \"duration_seconds\": 32,\n  \"peak_dbfs\": " + Math.Round(peakDb, 2).ToString(System.Globalization.CultureInfo.InvariantCulture) + ",\n" +
            "  \"bytes\": " + new FileInfo(path).Length + ",\n" +
            "  \"synthesis\": \"PowerShell/.NET deterministic additive synthesis; no samples\"\n" +
            "}\n";
        File.WriteAllText(Path.Combine(directory, "metadata.json"), json, new UTF8Encoding(false));
        return "Built Remembered Threshold, a 32-second quiet narrative overlay at 44.1 kHz stereo PCM.";
    }

    private static void AddSwell(double[] l, double[] r, double f, double start, double duration, double amp, double pan, int voice)
    {
        int first = (int)(start * Rate), last = Math.Min(Frames, (int)((start + duration) * Rate));
        double lg = Math.Sqrt((1.0 - pan) * 0.5), rg = Math.Sqrt((1.0 + pan) * 0.5);
        double phase = voice * 0.47;
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)Rate, remain = duration - t;
            double env = (1.0 - Math.Exp(-t / 1.6)) * Math.Min(1.0, Math.Max(0.0, remain / 0.7));
            double wave = Math.Sin(2.0 * Math.PI * f * t + phase) + 0.09 * Math.Sin(2.0 * Math.PI * f * 2.002 * t + phase * 1.3);
            double v = amp * env * wave;
            l[i] += v * lg; r[i] += v * rg;
        }
    }

    private static void AddNote(double[] l, double[] r, double f, double start, double duration, double amp, double pan, int color)
    {
        int first = (int)(start * Rate), last = Math.Min(Frames, (int)((start + duration) * Rate));
        double lg = Math.Sqrt((1.0 - pan) * 0.5), rg = Math.Sqrt((1.0 + pan) * 0.5);
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)Rate;
            double env = (1.0 - Math.Exp(-t * 5.0)) * Math.Exp(-t * 1.42) * Math.Min(1.0, (duration - t) / 0.16);
            double wave = Math.Sin(2.0 * Math.PI * f * t) + 0.16 * Math.Sin(2.0 * Math.PI * f * (color == 0 ? 2.01 : 2.76) * t + 0.4);
            double v = amp * env * wave;
            l[i] += v * lg; r[i] += v * rg;
        }
    }

    private static double Freq(int midi) { return 440.0 * Math.Pow(2.0, (midi - 69) / 12.0); }

    private static void WriteWave(string path, double[] l, double[] r, double gain)
    {
        const short channels = 2, bits = 16;
        int bytes = l.Length * channels * (bits / 8);
        using (BinaryWriter w = new BinaryWriter(File.Create(path)))
        {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + bytes);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1);
            w.Write(channels); w.Write(Rate); w.Write(Rate * channels * (bits / 8));
            w.Write((short)(channels * (bits / 8))); w.Write(bits);
            w.Write(Encoding.ASCII.GetBytes("data")); w.Write(bytes);
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
[MoonmartNarrativeOverlayBuilder]::Build($outputAbsolute)
