
## Opportunity Analysis at 2026-05-12T03:21:03.041542+00:00

### [opp-prop-1] Auto-generate tsconfig.json for Next.js projects
- **Type:** auto-generate
- **Reason:** 2 Next.js projects missing tsconfig.json
- **Proposed Rule:** For Next.js projects, always create tsconfig.json with @/* path alias to ./*
- **Risk:** low
- **Auto-fix:** `python3 -c "import json,datetime; entry={'type':'rule','rule':'TSCONFIG AUTO-GENERATION: For Next.js projects, always create tsconfig.json with paths: {@/*: [./*]}.','source':'opportunity-analyzer','timestamp':datetime.datetime.now(datetime.UTC).isoformat()}; f=open('$HOME/.hermes/skills/codex-developer/global-knowledge.jsonl','a'); f.write(json.dumps(entry)+'\n')"`
- **Found in:** fluxus-lang
- **Found in:** street-food-app
- **Status:** APPROVED

