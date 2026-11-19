param(
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot "assets\audio\ambience"
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class MoonmartRainGenerator {
    const int Rate = 44100;
    const int Frames = 32 * Rate;
    static uint state = 0x6D6F6F6u;
    static double NextNoise() {
        state ^= state << 13; state ^= state >> 17; state ^= state << 5;
        return ((state & 0x00ffffff) / 8388607.5) - 1.0;
    }
    static void Write16(BinaryWriter w, short v) { w.Write(v); }
    static void WriteWav(string path, short[] samples) {
        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        using (var w = new BinaryWriter(fs)) {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + samples.Length * 2);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1);
            w.Write((short)2); w.Write(Rate); w.Write(Rate * 4); w.Write((short)4); w.Write((short)16);
            w.Write(Encoding.ASCII.GetBytes("data")); w.Write(samples.Length * 2);
            foreach (short sample in samples) Write16(w, sample);
        }
    }
    public static string Generate(string outputPath) {
        double[] left = new double[Frames], right = new double[Frames];
        // Independent, gently varying low-pass noise beds create a soft sheet of rain.
        double lowL=0, lowR=0, midL=0, midR=0, slow=0;
        double lpLow = 1.0 - Math.Exp(-2.0 * Math.PI * 720.0 / Rate);
        double lpMid = 1.0 - Math.Exp(-2.0 * Math.PI * 2850.0 / Rate);
        double lpSlow = 1.0 - Math.Exp(-2.0 * Math.PI * 0.17 / Rate);
        for (int i=0; i<Frames; i++) {
            double nL=NextNoise(), nR=NextNoise();
            lowL += lpLow * (nL-lowL); lowR += lpLow * (nR-lowR);
            midL += lpMid * (nL-midL); midR += lpMid * (nR-midR);
            slow += lpSlow * (NextNoise()-slow);
            double swell = 0.78 + 0.15 * slow;
            left[i] = swell * (0.57*lowL + 0.20*(midL-lowL*0.42) + 0.035*nL);
            right[i] = swell * (0.57*lowR + 0.20*(midR-lowR*0.42) + 0.035*nR);
        }
        // Sparse, small glassy droplets: soft attack, short filtered resonant tails.
        int drops = 62;
        for (int d=0; d<drops; d++) {
            int start = 12000 + (int)(NextNoise()*0.5*(Frames-24000)) + (int)((d+0.5)*((Frames-24000.0)/drops));
            if (start < 8000) start = 8000;
            if (start > Frames-10000) start = Frames-10000;
            double freq = 1150.0 + 2050.0 * (0.5 + 0.5*NextNoise());
            double amp = 0.014 + 0.018 * (0.5 + 0.5*NextNoise());
            double phase = 2.0*Math.PI*NextNoise();
            int length = (int)(Rate*(0.035 + 0.045*(0.5+0.5*NextNoise())));
            double pan = 0.15 + 0.7*(0.5+0.5*NextNoise());
            for (int j=0; j<length && start+j<Frames; j++) {
                double t=j/(double)Rate;
                double attack=1.0-Math.Exp(-t*190.0);
                double env=attack*Math.Exp(-t/(length/(double)Rate*0.34));
                double shimmer = Math.Sin(2*Math.PI*freq*t+phase) + 0.17*Math.Sin(2*Math.PI*(freq*1.61)*t+phase*0.7);
                left[start+j] += amp*env*shimmer*Math.Sqrt(1.0-pan);
                right[start+j] += amp*env*shimmer*Math.Sqrt(pan);
            }
        }
        // Crossfade ends to silence, making the loop boundary click-free and exact-zero.
        int fade=5292; // 120 ms
        for (int i=0; i<Frames; i++) {
            double gain=1.0;
            if (i<fade) gain*=0.5-0.5*Math.Cos(Math.PI*i/fade);
            int remain=Frames-1-i;
            if (remain<fade) gain*=0.5-0.5*Math.Cos(Math.PI*remain/fade);
            left[i]*=gain; right[i]*=gain;
        }
        double peak=0.0;
        for (int i=0;i<Frames;i++) peak=Math.Max(peak, Math.Max(Math.Abs(left[i]),Math.Abs(right[i])));
        double target=Math.Pow(10.0,-20.0/20.0), scale=target/peak;
        short[] pcm=new short[Frames*2];
        int pcmPeak=0;
        for (int i=0;i<Frames;i++) {
            pcm[2*i]=(short)Math.Round(Math.Max(-1.0,Math.Min(1.0,left[i]*scale))*32767.0);
            pcm[2*i+1]=(short)Math.Round(Math.Max(-1.0,Math.Min(1.0,right[i]*scale))*32767.0);
            pcmPeak=Math.Max(pcmPeak,Math.Max(Math.Abs((int)pcm[2*i]),Math.Abs((int)pcm[2*i+1])));
        }
        pcm[0]=0; pcm[1]=0; pcm[pcm.Length-2]=0; pcm[pcm.Length-1]=0;
        WriteWav(outputPath,pcm);
        double actualDb=20.0*Math.Log10(pcmPeak/32768.0);
        return "frames="+Frames+"; peak_dbfs="+actualDb.ToString("F3",System.Globalization.CultureInfo.InvariantCulture)+"; edge_samples=0,0,0,0";
    }
}
'@

$wavPath = Join-Path $OutputDirectory "moonmart_rain_window.wav"
$result = [MoonmartRainGenerator]::Generate($wavPath)
$hash = (Get-FileHash -LiteralPath $wavPath -Algorithm SHA256).Hash.ToLowerInvariant()
$peakMatch = [regex]::Match($result, "peak_dbfs=([-0-9.]+)")
$peakDbfs = [double]::Parse($peakMatch.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
$metadata = @{
    title = "Moonmart Rain on Window"
    file = "moonmart_rain_window.wav"
    duration_seconds = 32
    sample_rate_hz = 44100
    channels = 2
    bit_depth = 16
    encoding = "PCM"
    frames = 1411200
    peak_dbfs = $peakDbfs
    first_frame_stereo_pcm = @(0, 0)
    last_frame_stereo_pcm = @(0, 0)
    seam = "First and final stereo frames are exact digital silence; 120 ms cosine edge fades."
    synthesis = "Deterministic original filtered-noise rain bed with sparse synthesized droplets; no third-party recordings."
    generator = "tools/build_moonmart_rain_ambience.ps1"
    sha256 = $hash
}
$metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDirectory "moonmart_rain_window.json") -Encoding utf8
Write-Output "Created $wavPath ($result, sha256=$hash)"
