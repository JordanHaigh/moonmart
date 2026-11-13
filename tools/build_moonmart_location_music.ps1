param(
    [string]$OutputDirectory = "assets/audio/locations"
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;

public static class MoonmartLocationMusicBuilder
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
        public string Arrangement;
        public int[][] Chords;
        public int[] Melody;
        public int Theme;
        public double PadLevel;
        public double PluckLevel;
        public bool Brush;
    }

    private static readonly Track[] Tracks = new Track[]
    {
        new Track {
            Id = "old_bellwether", Title = "Old Bellwether", Theme = 0, PadLevel = 0.020, PluckLevel = 0.036, Brush = true,
            Arrangement = "warm felt-piano-like chords, measured acoustic-like plucks, faint brushed texture",
            Chords = new int[][] {
                new int[] {50,54,57,62}, new int[] {47,50,54,59}, new int[] {43,47,50,55}, new int[] {45,49,52,57},
                new int[] {50,54,57,62}, new int[] {52,55,59,62}, new int[] {48,52,55,60}, new int[] {45,50,54,57}
            },
            Melody = new int[] {74,76,78,81,79,78,74,71,73,76,79,78,76,73,71,69}
        },
        new Track {
            Id = "whisperwood", Title = "Whisperwood", Theme = 1, PadLevel = 0.023, PluckLevel = 0.025, Brush = false,
            Arrangement = "open airy sustained chords, sparse high music-box-like droplets, slow root plucks",
            Chords = new int[][] {
                new int[] {53,57,60,64}, new int[] {50,53,57,60}, new int[] {48,53,57,62}, new int[] {45,48,52,57},
                new int[] {53,57,60,64}, new int[] {55,58,62,65}, new int[] {50,53,57,62}, new int[] {48,53,57,60}
            },
            Melody = new int[] {81,84,86,84,79,81,84,81,77,81,84,86,84,81,79,77}
        },
        new Track {
            Id = "harbour_lighthouse", Title = "Harbour and Lighthouse", Theme = 2, PadLevel = 0.018, PluckLevel = 0.040, Brush = true,
            Arrangement = "wide coastal sustained tones, rounded plucked-string notes, very soft brushed pulse",
            Chords = new int[][] {
                new int[] {45,48,52,57}, new int[] {41,45,48,53}, new int[] {43,47,50,55}, new int[] {40,43,47,52},
                new int[] {45,48,52,57}, new int[] {48,52,55,60}, new int[] {43,47,50,55}, new int[] {41,45,48,53}
            },
            Melody = new int[] {72,76,79,76,74,77,81,77,76,79,83,79,77,81,84,81}
        },
        new Track {
            Id = "midnight_between", Title = "The Midnight Between", Theme = 3, PadLevel = 0.024, PluckLevel = 0.021, Brush = false,
            Arrangement = "slow suspended piano-like harmony, distant glassy music-box tones, no percussion",
            Chords = new int[][] {
                new int[] {48,53,55,62}, new int[] {46,50,53,60}, new int[] {43,48,50,57}, new int[] {45,50,52,59},
                new int[] {48,53,55,62}, new int[] {41,46,48,55}, new int[] {43,48,50,57}, new int[] {46,50,53,60}
            },
            Melody = new int[] {86,84,81,79,82,79,77,74,79,81,84,81,77,79,82,79}
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
        StringBuilder weatherMetadata = new StringBuilder();
        weatherMetadata.AppendLine("{");
        weatherMetadata.AppendLine("  \"schema_version\": 1,");
        weatherMetadata.AppendLine("  \"sample_rate\": 44100,");
        weatherMetadata.AppendLine("  \"channels\": 2,");
        weatherMetadata.AppendLine("  \"bits_per_sample\": 16,");
        weatherMetadata.AppendLine("  \"loop_seconds\": 32,");
        weatherMetadata.AppendLine("  \"variants\": [");
        string[] weatherIds = new string[] { "rain", "fog", "wind", "snow" };
        bool firstVariant = true;

        for (int i = 0; i < Tracks.Length; i++)
        {
            Track track = Tracks[i];
            string path = Path.Combine(outputDirectory, track.Id + ".wav");
            double peak = Render(track, path);
            metadata.AppendLine("    {");
            metadata.AppendLine("      \"id\": \"" + track.Id + "\",");
            metadata.AppendLine("      \"title\": \"" + track.Title + "\",");
            metadata.AppendLine("      \"path\": \"" + track.Id + ".wav\",");
            metadata.AppendLine("      \"arrangement\": \"" + track.Arrangement + "\",");
            metadata.AppendLine("      \"duration_seconds\": 32,");
            metadata.AppendLine("      \"peak_dbfs\": " + Math.Round(20.0 * Math.Log10(Math.Max(peak, 0.000001)), 2).ToString(System.Globalization.CultureInfo.InvariantCulture) + ",");
            metadata.AppendLine("      \"bytes\": " + new FileInfo(path).Length);
            metadata.Append("    }");
            metadata.AppendLine(i == Tracks.Length - 1 ? "" : ",");

            foreach (string weather in weatherIds)
            {
                Track variant = MakeWeatherVariant(track, weather);
                string variantFile = variant.Id + ".wav";
                string variantPath = Path.Combine(outputDirectory, variantFile);
                double variantPeak = Render(variant, variantPath);
                if (!firstVariant) weatherMetadata.AppendLine(",");
                weatherMetadata.AppendLine("    {");
                weatherMetadata.AppendLine("      \"location_track\": \"" + track.Id + "\",");
                weatherMetadata.AppendLine("      \"weather\": \"" + weather + "\",");
                weatherMetadata.AppendLine("      \"path\": \"" + variantFile + "\",");
                weatherMetadata.AppendLine("      \"arrangement\": \"" + variant.Arrangement + "\",");
                weatherMetadata.AppendLine("      \"duration_seconds\": 32,");
                weatherMetadata.AppendLine("      \"peak_dbfs\": " + Math.Round(20.0 * Math.Log10(Math.Max(variantPeak, 0.000001)), 2).ToString(System.Globalization.CultureInfo.InvariantCulture) + ",");
                weatherMetadata.Append("      \"bytes\": " + new FileInfo(variantPath).Length + "\n    }");
                firstVariant = false;
            }
        }

        metadata.AppendLine("  ]");
        metadata.AppendLine("}");
        File.WriteAllText(Path.Combine(outputDirectory, "location_metadata.json"), metadata.ToString(), new UTF8Encoding(false));
        weatherMetadata.AppendLine();
        weatherMetadata.AppendLine("  ]");
        weatherMetadata.AppendLine("}");
        File.WriteAllText(Path.Combine(outputDirectory, "weather_variants.json"), weatherMetadata.ToString(), new UTF8Encoding(false));
        return "Built " + Tracks.Length + " original 32-second location scores and " + (Tracks.Length * weatherIds.Length) + " weather-specific score variants at 44.1 kHz stereo PCM.";
    }

    private static Track MakeWeatherVariant(Track source, string weather)
    {
        Track variant = new Track {
            Id = source.Id + "_" + weather,
            Title = source.Title + " " + weather,
            Theme = source.Theme,
            PadLevel = source.PadLevel,
            PluckLevel = source.PluckLevel,
            Brush = source.Brush,
            Chords = source.Chords,
            Melody = source.Melody,
            Arrangement = source.Arrangement
        };

        switch (weather)
        {
            case "rain":
                variant.PadLevel *= 1.08;
                variant.PluckLevel *= 0.62;
                variant.Brush = true;
                variant.Arrangement += "; softened plucks and a closer brushed wash for rain";
                break;
            case "fog":
                variant.PadLevel *= 1.12;
                variant.PluckLevel *= 0.48;
                variant.Theme = 3;
                variant.Brush = false;
                variant.Arrangement += "; slower suspended voicing and reduced high notes for fog";
                break;
            case "wind":
                variant.PadLevel *= 0.84;
                variant.PluckLevel *= 0.72;
                variant.Brush = true;
                variant.Arrangement += "; more space between notes with a soft brushed pulse for wind";
                break;
            case "snow":
                variant.PadLevel *= 0.86;
                variant.PluckLevel *= 0.92;
                variant.Theme = 1;
                variant.Brush = false;
                variant.Arrangement += "; sparse glass-like upper notes and no brush for snow";
                break;
        }
        return variant;
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
                double pan = -0.32 + note * 0.20;
                AddPad(left, right, MidiFrequency(chord[note]), start, BarSeconds, track.PadLevel, pan, note + bar);
            }

            double rootOffset = track.Theme == 2 ? 0.22 : 0.12;
            double rootLength = track.Theme == 3 ? 2.1 : 1.5;
            AddPluck(left, right, MidiFrequency(chord[0] - 12), start + rootOffset, rootLength, track.PluckLevel, -0.18 + (bar % 2) * 0.36, false);

            double firstBeat = track.Theme == 1 ? 1.0 : (track.Theme == 3 ? 1.15 : 0.62);
            double secondBeat = track.Theme == 1 ? 3.15 : (track.Theme == 3 ? 3.2 : 2.62);
            bool glassTone = track.Theme == 1 || track.Theme == 3;
            double noteLevel = track.Theme == 3 ? track.PluckLevel * 0.68 : track.PluckLevel * 0.78;
            AddPluck(left, right, MidiFrequency(track.Melody[bar * 2]), start + firstBeat, glassTone ? 1.05 : 1.45, noteLevel, -0.30, glassTone);
            AddPluck(left, right, MidiFrequency(track.Melody[bar * 2 + 1]), start + secondBeat, 1.20, noteLevel * 0.86, 0.30, glassTone);

            if (track.Brush)
                AddBrush(left, right, start + (track.Theme == 2 ? 2.95 : 3.25), track.Theme == 2 ? 0.0018 : 0.0013, bar + track.Theme * 100);
        }

        ApplyCircularDelay(left, right, 0.173, 0.085);
        double peak = 0.0;
        for (int i = 0; i < frames; i++)
        {
            double edge = Math.Min(1.0, Math.Min(i / (SampleRate * 0.04), (frames - 1 - i) / (SampleRate * 0.04)));
            left[i] *= Math.Max(0.0, edge);
            right[i] *= Math.Max(0.0, edge);
            peak = Math.Max(peak, Math.Max(Math.Abs(left[i]), Math.Abs(right[i])));
        }

        double gain = peak > 0.0 ? Math.Min(12.0, 0.32 / peak) : 1.0;
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
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            double remaining = duration - t;
            double attack = 1.0 - Math.Exp(-t / 1.25);
            double release = remaining >= 1.0 ? 1.0 : Math.Max(0.0, remaining);
            double breathe = 0.95 + 0.05 * Math.Sin(2.0 * Math.PI * 0.18 * (start + t));
            double wave = Math.Sin(2.0 * Math.PI * frequency * t + phase)
                + 0.14 * Math.Sin(2.0 * Math.PI * frequency * 2.003 * t + phase * 1.31)
                + 0.035 * Math.Sin(2.0 * Math.PI * frequency * 3.01 * t + phase * 0.63);
            double sample = amplitude * attack * release * breathe * wave;
            left[i] += sample * leftGain;
            right[i] += sample * rightGain;
        }
    }

    private static void AddPluck(double[] left, double[] right, double frequency, double start, double duration, double amplitude, double pan, bool glass)
    {
        int first = Math.Max(0, (int)(start * SampleRate));
        int last = Math.Min(left.Length, (int)((start + duration) * SampleRate));
        double leftGain = Math.Sqrt((1.0 - pan) * 0.5);
        double rightGain = Math.Sqrt((1.0 + pan) * 0.5);
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            double decay = Math.Exp(-t * (glass ? 2.55 : 3.55));
            double attack = 1.0 - Math.Exp(-t * 92.0);
            double fundamental = Math.Sin(2.0 * Math.PI * frequency * t);
            double second = Math.Sin(2.0 * Math.PI * frequency * (glass ? 2.73 : 2.004) * t + 0.37);
            double third = Math.Sin(2.0 * Math.PI * frequency * (glass ? 5.08 : 3.97) * t + 0.69);
            double body = fundamental + (glass ? 0.20 : 0.25) * second + 0.07 * third;
            double sample = amplitude * decay * attack * body;
            left[i] += sample * leftGain;
            right[i] += sample * rightGain;
        }
    }

    private static void AddBrush(double[] left, double[] right, double start, double amplitude, int seedOffset)
    {
        int first = (int)(start * SampleRate);
        int last = Math.Min(left.Length, first + (int)(0.32 * SampleRate));
        uint seed = (uint)(seedOffset + 7717);
        double filtered = 0.0;
        for (int i = first; i < last; i++)
        {
            double t = (i - first) / (double)SampleRate;
            seed = 1664525u * seed + 1013904223u;
            double noise = (seed / 4294967295.0) * 2.0 - 1.0;
            filtered = filtered * 0.84 + noise * 0.16;
            double envelope = Math.Exp(-t * 15.0) * Math.Sin(Math.PI * Math.Min(1.0, t / 0.32));
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

    private static double MidiFrequency(int midi) { return 440.0 * Math.Pow(2.0, (midi - 69) / 12.0); }

    private static void WriteWave(string path, double[] left, double[] right, double gain)
    {
        int dataBytes = left.Length * Channels * (BitsPerSample / 8);
        using (BinaryWriter writer = new BinaryWriter(File.Create(path)))
        {
            writer.Write(Encoding.ASCII.GetBytes("RIFF")); writer.Write(36 + dataBytes);
            writer.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); writer.Write(16); writer.Write((short)1);
            writer.Write((short)Channels); writer.Write(SampleRate); writer.Write(SampleRate * Channels * (BitsPerSample / 8));
            writer.Write((short)(Channels * (BitsPerSample / 8))); writer.Write((short)BitsPerSample);
            writer.Write(Encoding.ASCII.GetBytes("data")); writer.Write(dataBytes);
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
[MoonmartLocationMusicBuilder]::Build($outputAbsolute)
