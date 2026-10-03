#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
unity_data="${CRICX_UNITY_EDITOR_DATA:-/workspace/tooling/unity/Editor/Data}"
mkdir -p build
python3 - "$unity_data" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
refs=[root/'Managed/UnityEngine'/('UnityEngine.'+n+'Module.dll') for n in ['Core','Physics','Animation','IMGUI']]
refs.append(root/'MonoBleedingEdge/lib/mono/4.5/Facades/netstandard.dll')
for p in refs: assert p.is_file(),str(p)+' missing'
lines=['-nologo','-target:library','-out:build/Cricx.Runtime.dll']+['-r:"'+str(p)+'"' for p in refs]+['"'+str(p)+'"' for p in Path('unity/Assets/Cricx/Scripts').glob('*.cs')]
Path('build/unity-runtime.rsp').write_text('\n'.join(lines))
PY
"$unity_data/MonoBleedingEdge/bin/mono" "$unity_data/MonoBleedingEdge/lib/mono/4.5/csc.exe" @build/unity-runtime.rsp
printf 'Runtime scripts compiled. Unity Editor import and runtime are separate, required checks.\n'
