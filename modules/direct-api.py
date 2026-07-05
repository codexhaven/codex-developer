#!/usr/bin/env python3
"""Direct API caller for Codex Developer."""
import os
import json
import sys
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

    data = {
        "model": "google/gemini-2.0-flash-lite-preview-02-05:free",
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens
    }

    req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            return res_data["choices"][0]["message"]["content"]
    except urllib.error.URLError as e:
        print(f"API Error: {e}", file=sys.stderr)
        return None
    except (KeyError, IndexError) as e:
        print(f"Response Parsing Error: {e}", file=sys.stderr)
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
