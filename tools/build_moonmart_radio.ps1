param(
    [string]$OutputDirectory = "assets/audio/radio"
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;

public static class MoonmartRadioBuilder
{
    private const int SampleRate = 44100;
    private const int Channels = 2;
    private const int BitsPerSample = 16;
    private const double DurationSeconds = 32.0;
    private const int Bars = 8;
    private const double BarSeconds = 4.0;

    private sealed class Track
    {
        public string Id;
        public string Title;
        public string[] Instruments;
        public int[][] Chords;
        public int[] Melody;
        public bool MusicBox;
    }

    private static readonly Track[] Tracks = new Track[]
    {
        new Track {
            Id = "window_seat", Title = "Window Seat",
            Instruments = new string[] { "felt-piano-like synthesis", "soft music-box-like synthesis", "warm string-like pad" }, MusicBox = true,
            Chords = new int[][] {
                new int[] {55,59,62,66}, new int[] {54,57,62,66}, new int[] {52,55,59,62}, new int[] {48,52,55,59},
                new int[] {47,50,55,59}, new int[] {45,48,52,55}, new int[] {50,55,60,64}, new int[] {43,50,55,59}
            },
            Melody = new int[] {74,76,79,76,74,71,69,71,72,74,76,79,76,74,71,67}
        },
        new Track {
            Id = "bellwether_after_hours", Title = "Bellwether After Hours",
            Instruments = new string[] { "felt-piano-like synthesis", "soft plucked-string synthesis", "warm string-like pad", "faint synthetic brush texture" }, MusicBox = false,
            Chords = new int[][] {
                new int[] {50,54,57,61}, new int[] {47,50,54,57}, new int[] {43,47,50,54}, new int[] {45,49,52,59},
                new int[] {50,54,57,61}, new int[] {42,45,49,52}, new int[] {43,47,50,54}, new int[] {45,50,52,55}
            },
            Melody = new int[] {78,81,83,81,78,76,74,76,78,81,83,86,83,81,78,74}
        },
        new Track {
            Id = "harbour_hush", Title = "Harbour Hush",
            Instruments = new string[] { "felt-piano-like synthesis", "soft plucked-string synthesis", "airy string-like pad", "faint synthetic brush texture" }, MusicBox = true,
            Chords = new int[][] {
                new int[] {45,48,52,59}, new int[] {41,45,48,52}, new int[] {48,52,55,59}, new int[] {43,47,50,57},
                new int[] {50,53,57,60}, new int[] {43,48,53,57}, new int[] {48,52,55,59}, new int[] {40,47,50,57}
            },
            Melody = new int[] {76,79,81,84,81,79,76,74,72,76,79,81,79,76,74,72}
        }
    };

    public static string Build(string outputDirectory)
    {
        Directory.CreateDirectory(outputDirectory);
        StringBuilder metadata = new StringBuilder();
        metadata.AppendLine("{");
        metadata.AppendLine("  \"schema_version\": 1,");
        metadata.AppendLine("  \"sample_rate\": 44100,");
        metadata.AppendLine("  \"channels\": 2,");
        metadata.AppendLine("  \"bits_per_sample\": 16,");
        metadata.AppendLine("  \"loop_seconds\": 32,");
        metadata.AppendLine("  \"tracks\": [");

        for (int trackIndex = 0; trackIndex < Tracks.Length; trackIndex++)
        {
            Track track = Tracks[trackIndex];
            string path = Path.Combine(outputDirectory, track.Id + ".wav");
            double peak = Render(track, path);
            string instruments = string.Join("; ", track.Instruments);
            metadata.AppendLine("    {");
            metadata.AppendLine("      \"id\": \"" + track.Id + "\",");
            metadata.AppendLine("      \"title\": \"" + track.Title + "\",");
            metadata.AppendLine("      \"path\": \"" + track.Id + ".wav\",");
            metadata.AppendLine("      \"instruments\": \"" + instruments + "\",");
            metadata.AppendLine("      \"duration_seconds\": 32,");
            metadata.AppendLine("      \"peak_dbfs\": " + Math.Round(20.0 * Math.Log10(Math.Max(peak, 0.000001)), 2).ToString(System.Globalization.CultureInfo.InvariantCulture) + ",");
            metadata.AppendLine("      \"bytes\": " + new FileInfo(path).Length);
            metadata.Append("    }");
            metadata.AppendLine(trackIndex == Tracks.Length - 1 ? "" : ",");
        }

        metadata.AppendLine("  ]");
        metadata.AppendLine("}");
        File.WriteAllText(Path.Combine(outputDirectory, "radio_metadata.json"), metadata.ToString(), new UTF8Encoding(false));
        return "Built " + Tracks.Length + " original 32-second radio loops at 44.1 kHz stereo PCM.";
    }

    private static double Render(Track track, string path)
    {
        int frames = (int)(SampleRate * DurationSeconds);
        double[] left = new double[frames];
        double[] right = new double[frames];

        for (int bar = 0; bar < Bars; bar++)
        {
            double start = bar * BarSeconds;
            int[] chord = track.Chords[bar];
            for (int note = 0; note < chord.Length; note++)
            {
                double pan = -0.28 + note * 0.18;
                AddPad(left, right, MidiFrequency(chord[note]), start, BarSeconds, 0.019, pan, note);
            }

            int bass = chord[0] - 12;
            AddPluck(left, right, MidiFrequency(bass), start + 0.08, 1.2, 0.044, -0.12 + (bar % 2) * 0.24, false);
            AddPluck(left, right, MidiFrequency(track.Melody[bar * 2]), start + 0.65, 1.45, track.MusicBox ? 0.027 : 0.032, -0.34, track.MusicBox);
            AddPluck(left, right, MidiFrequency(track.Melody[bar * 2 + 1]), start + 2.55, 1.35, track.MusicBox ? 0.026 : 0.031, 0.32, track.MusicBox);

            if (!track.MusicBox)
            {
                AddBrush(left, right, start + 3.0, 0.0024, bar);
            }
        }

        ApplyCircularDelay(left, right, 0.145, 0.115);
        double peak = 0.0;
        for (int i = 0; i < frames; i++)
        {
            double edge = Math.Min(1.0, Math.Min(i / (SampleRate * 0.035), (frames - 1 - i) / (SampleRate * 0.035)));
            left[i] *= Math.Max(0.0, edge);
            right[i] *= Math.Max(0.0, edge);
            peak = Math.Max(peak, Math.Max(Math.Abs(left[i]), Math.Abs(right[i])));
        }
        double gain = peak > 0.0 ? Math.Min(12.0, 0.335 / peak) : 1.0;
        WriteWave(path, left, right, gain);
        return Math.Min(peak * gain, 0.999);
    }

    private static void AddPad(double[] left, double[] right, double frequency, double start, double duration, double amplitude, double pan, int voice)
    {
        int first = Math.Max(0, (int)(start * SampleRate));
        int last = Math.Min(left.Length, (int)((start + duration) * SampleRate));
        double phase = voice * 0.731;
        double leftGain = Math.Sqrt((1.0 - pan) * 0.5);
        double rightGain = Math.Sqrt((1.0 + pan) * 0.5);
        double attackSeconds = 1.15;
        double releaseSeconds = 1.05;
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            double remaining = duration - t;
            double attack = 1.0 - Math.Exp(-t / attackSeconds);
            double release = remaining >= releaseSeconds ? 1.0 : Math.Max(0.0, remaining / releaseSeconds);
            double lfo = 0.94 + 0.06 * Math.Sin(2.0 * Math.PI * 0.25 * (start + t));
            double wave = Math.Sin(2.0 * Math.PI * frequency * t + phase)
                + 0.17 * Math.Sin(2.0 * Math.PI * frequency * 2.002 * t + phase * 1.31)
                + 0.045 * Math.Sin(2.0 * Math.PI * frequency * 3.01 * t + phase * 0.63);
            double sample = amplitude * attack * release * lfo * wave;
            left[i] += sample * leftGain;
            right[i] += sample * rightGain;
        }
    }

    private static void AddPluck(double[] left, double[] right, double frequency, double start, double duration, double amplitude, double pan, bool bell)
    {
        int first = Math.Max(0, (int)(start * SampleRate));
        int last = Math.Min(left.Length, (int)((start + duration) * SampleRate));
        double leftGain = Math.Sqrt((1.0 - pan) * 0.5);
        double rightGain = Math.Sqrt((1.0 + pan) * 0.5);
        uint seed = (uint)(Math.Abs((int)(frequency * 31.0 + start * 100.0)) + 92821);
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            double decay = Math.Exp(-t * (bell ? 2.9 : 3.8));
            double attack = 1.0 - Math.Exp(-t * 110.0);
            double fundamental = Math.Sin(2.0 * Math.PI * frequency * t);
            double second = Math.Sin(2.0 * Math.PI * frequency * (bell ? 2.71 : 2.006) * t + 0.4);
            double third = Math.Sin(2.0 * Math.PI * frequency * (bell ? 5.13 : 3.99) * t + 0.7);
            double body = bell ? (fundamental + 0.28 * second + 0.11 * third) : (fundamental + 0.31 * second + 0.09 * third);
            seed = 1664525u * seed + 1013904223u;
            double transientNoise = ((seed / 4294967295.0) * 2.0 - 1.0) * Math.Exp(-t * 58.0) * 0.018;
            double sample = amplitude * decay * attack * (body + transientNoise);
            left[i] += sample * leftGain;
            right[i] += sample * rightGain;
        }
    }

    private static void AddBrush(double[] left, double[] right, double start, double amplitude, int seedOffset)
    {
        int first = (int)(start * SampleRate);
        int last = Math.Min(left.Length, first + (int)(0.25 * SampleRate));
        uint seed = (uint)(seedOffset + 7717);
        double filtered = 0.0;
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            seed = 1664525u * seed + 1013904223u;
            double noise = (seed / 4294967295.0) * 2.0 - 1.0;
            filtered = filtered * 0.82 + noise * 0.18;
            double envelope = Math.Exp(-t * 19.0) * Math.Sin(Math.PI * Math.Min(1.0, t / 0.25));
            double sample = amplitude * filtered * envelope;
            left[i] += sample * 0.88;
            right[i] += sample * 0.88;
        }
    }

    private static void ApplyCircularDelay(double[] left, double[] right, double delaySeconds, double amount)
    {
        int delay = (int)(delaySeconds * SampleRate);
        double[] sourceLeft = (double[])left.Clone();
        double[] sourceRight = (double[])right.Clone();
        for (int i = 0; i < left.Length; i++)
        {
            int delayed = (i - delay + left.Length) % left.Length;
            left[i] += sourceRight[delayed] * amount;
            right[i] += sourceLeft[delayed] * amount;
        }
    }

    private static double MidiFrequency(int midi)
    {
        return 440.0 * Math.Pow(2.0, (midi - 69) / 12.0);
    }

    private static void WriteWave(string path, double[] left, double[] right, double gain)
    {
        int dataBytes = left.Length * Channels * (BitsPerSample / 8);
        using (BinaryWriter writer = new BinaryWriter(File.Create(path)))
        {
            writer.Write(Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + dataBytes);
            writer.Write(Encoding.ASCII.GetBytes("WAVE"));
            writer.Write(Encoding.ASCII.GetBytes("fmt "));
            writer.Write(16);
            writer.Write((short)1);
            writer.Write((short)Channels);
            writer.Write(SampleRate);
            writer.Write(SampleRate * Channels * (BitsPerSample / 8));
            writer.Write((short)(Channels * (BitsPerSample / 8)));
            writer.Write((short)BitsPerSample);
            writer.Write(Encoding.ASCII.GetBytes("data"));
            writer.Write(dataBytes);
            for (int i = 0; i < left.Length; i++)
            {
                writer.Write((short)Math.Round(Math.Max(-1.0, Math.Min(1.0, left[i] * gain)) * 32767.0));
                writer.Write((short)Math.Round(Math.Max(-1.0, Math.Min(1.0, right[i] * gain)) * 32767.0));
            }
        }
    }
}
'@

$outputAbsolute = [System.IO.Path]::GetFullPath($OutputDirectory)
[MoonmartRadioBuilder]::Build($outputAbsolute)
