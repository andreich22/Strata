# Community benchmark on AMD Radeon

Measured on 2026-10-14 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 24 GiB VRAM
- CPU: AMD Ryzen 9 7940HX with Radeon Graphics (16 cores, 32 threads); installed RAM: 60.5 GiB; storage: not measured
- OS: Linux 7.2.9-201.fc44.x86_64; GPU driver: not read; CUDA: not read
- Strata: project 0.1.44.1, commit 296b59d2; engine 0.1.44.1
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: ornith-1.5-35b-q5_k_m
- Context: 194560 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged (hip backend); thinking off for the suite; temperature 0

```text
strata --native Ornith-1.5-35B-Q5_K_M.gguf --max-context 194560 --prefill auto --mtp 2
```

## Method

Run by `python tools/strata_bench.py` against the HTTP API of a Strata server (already running); model loading is not timed. One warm-up chat and a 1K prompt are discarded first. Every prompt starts with a unique tag, so the conversation cache cannot help the fresh-prompt tests.

- short chat: the three questions of `tools/ab_engine.py`, up to 100 new tokens, 3 runs
- 4K / 16K prompts: generated word lists sized by a calibration request, 24 new tokens, 3 fresh prompts each
- agent session: system prompt and four tools, then 5 turns that each add about 1500 words of a project file and continue from the model's own earlier answers (the way agent clients resend a conversation), 64 new tokens per turn, 3 sessions; the cache numbers come from the answer's usage (`cached_tokens`) and timings (`prompt_n`)
- concurrency (when run): N requests sent at the same moment, total tokens over the wall time of the burst, latency over all requests

## Results

| Configuration | Actual prompt tokens | Reused tokens | Generated tokens | Runs | Prompt tok/s median and range | Decode tok/s median and range | TTFT seconds median and range |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 103.6 (72.0-112.1) | 0.20 (0.20-0.23) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2214.4 (2085.8-2227.3) | not measured | 1.82 (1.81-1.93) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 1838.5 (1829.6-1851.2) | not measured | 8.74 (8.69-8.79) |
| agent session, follow-up turns | 14596 (14580-14616) at the last turn | see below | up to 64 | 3 | see below | 73.8 (62.3-97.1) | 2.02 (0.89-2.23) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 68.8 % (68.7-68.8); earlier-turn tokens read again per session: 3 (2-3) (earlier turns that the cache did not hold; the 13729 (13729-13729) new tokens of the files are read once); first turn (nothing cached) first token: 0.89 s (0.89-0.90).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 688.4 | 0.889 | 53.2 |
| 1 | 3762 | 639 | 3123 | 1624.6 | 1.931 | 94.7 |
| 2 | 5295 | 3826 | 1469 | 1637.1 | 0.903 | 81.9 |
| 3 | 8737 | 5358 | 3379 | 1666.6 | 2.039 | 67.4 |
| 4 | 11654 | 8792 | 2862 | 1333.2 | 2.157 | 73.5 |
| 5 | 14596 | 11697 | 2899 | 1305.0 | 2.231 | 70.6 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 92 s.
