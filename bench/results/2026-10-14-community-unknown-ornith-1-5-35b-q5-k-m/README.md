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
- Context: 65536 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged (hip backend); thinking off for the suite; temperature 0

```text
strata --native Ornith-1.5-35B-Q5_K_M.gguf --max-context 65536 --prefill auto --mtp 2
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 161.0 (132.3-175.4) | 0.14 (0.14-0.17) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2215.7 (2132.3-2224.5) | not measured | 1.82 (1.81-1.89) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 1825.4 (1814.2-1842.0) | not measured | 8.81 (8.73-8.86) |
| agent session, follow-up turns | 14613 (14564-14614) at the last turn | see below | up to 64 | 3 | see below | 105.0 (85.5-139.5) | 1.93 (0.83-2.06) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 68.8 % (68.7-68.8); earlier-turn tokens read again per session: 3 (3-3) (earlier turns that the cache did not hold; the 13729 (13728-13730) new tokens of the files are read once); first turn (nothing cached) first token: 0.51 s (0.51-0.54).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 1137.5 | 0.539 | 113.9 |
| 1 | 3760 | 638 | 3122 | 1862.4 | 1.685 | 127.6 |
| 2 | 5293 | 3823 | 1470 | 1757.1 | 0.842 | 120.4 |
| 3 | 8737 | 5356 | 3381 | 1711.6 | 1.983 | 103.8 |
| 4 | 11658 | 8796 | 2862 | 1491.1 | 1.928 | 105.0 |
| 5 | 14613 | 11715 | 2898 | 1427.1 | 2.04 | 94.1 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 79 s.
