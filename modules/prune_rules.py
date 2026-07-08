import json
import os

# ctx: codexhaven

def prune_rules(file_path):
    if not os.path.exists(file_path):
        return

    seen_rules = {}
    unique_rules = []

    with open(file_path, 'r') as f:
        for line in f:
            try:
                data = json.loads(line)
                rule_text = data.get('rule', '').strip()
                if not rule_text:
                    continue

                # Check for near duplicates (case-insensitive, basic normalization)
                norm_rule = rule_text.lower().replace('"', "'")
                if norm_rule not in seen_rules:
                    seen_rules[norm_rule] = data
                    unique_rules.append(data)
                else:
                    # Keep the one with higher priority or more domains
                    existing = seen_rules[norm_rule]
                    if data.get('priority', 0) > existing.get('priority', 0):
                        seen_rules[norm_rule] = data
            except:
                continue

    with open(file_path, 'w') as f:
        for rule in unique_rules:
            f.write(json.dumps(rule) + '\n')

    print(f"Pruned rules: {len(seen_rules)} unique rules remaining (from {len(unique_rules)} total).")

if __name__ == "__main__":
    prune_rules('global-knowledge.jsonl')
