#!/usr/bin/env python3
"""Direct API caller for Codex Developer."""
import os
import json
import sys
import time
import urllib.request
import urllib.error

# ctx: codexhaven

def call_api(prompt, system_prompt=None, temperature=0.2, max_tokens=4000):
    api_key = os.environ.get("OPENROUTER_KEY")
    if not api_key:
        print("ERROR: OPENROUTER_KEY not set", file=sys.stderr)
        return None

    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/codexhaven/codex-developer",
        "X-Title": "Codex Developer Factory"
    }

    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    # Try multiple free models — some are rate-limited, fall back to next
    models = [
        "qwen/qwen3-next-80b-a3b-instruct:free",
        "openai/gpt-oss-120b:free",
        "google/gemma-4-31b-it:free",
        "nvidia/nemotron-3-super-120b-a12b:free",
        "nvidia/nemotron-nano-9b-v2:free",
    ]

    for model in models:
        data = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }

        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers=headers
        )

        # Retry each model up to 2 times with backoff
        for attempt in range(2):
            try:
                with urllib.request.urlopen(req, timeout=120) as response:
                    res_data = json.loads(response.read().decode("utf-8"))
                    content = res_data["choices"][0]["message"]["content"]
                    if content and len(content.strip()) > 0:
                        print(f"[API] Used model: {model}", file=sys.stderr)
                        return content
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    print(f"[API] {model}: Rate limited (429), attempt {attempt+1}/2", file=sys.stderr)
                    if attempt == 0:
                        time.sleep(5)  # Wait 5s before retry
                    continue
                elif e.code == 400:
                    body = e.read().decode("utf-8", errors="replace")
                    print(f"[API] {model}: Bad request (400): {body[:200]}", file=sys.stderr)
                    break  # Don't retry 400s, try next model
                else:
                    print(f"[API] {model}: HTTP {e.code}", file=sys.stderr)
                    break
            except urllib.error.URLError as e:
                print(f"[API] {model}: URL Error: {e}", file=sys.stderr)
                break
            except (KeyError, IndexError) as e:
                print(f"[API] {model}: Parse Error: {e}", file=sys.stderr)
                break

    print("[API] All models failed", file=sys.stderr)
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: direct-api.py 'prompt' ['system_prompt']")
        sys.exit(1)

    prompt = sys.argv[1]
    system_prompt = sys.argv[2] if len(sys.argv) > 2 else None

    result = call_api(prompt, system_prompt)
    if result:
        print(result)
    else:
        sys.exit(1)
