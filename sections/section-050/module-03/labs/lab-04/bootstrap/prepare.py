from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path('/tmp/ats021-sbom-scan')
ROOT.mkdir(exist_ok=True)

def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=600).stdout

run('kubectl', 'create', 'namespace', 'starfleet')
node = json.loads(run('kubectl','get','nodes','-o','json'))['items'][0]
platform = 'linux/' + node['metadata']['labels']['kubernetes.io/arch']
images = {'clean':'docker.io/library/hello-world@sha256:5e22040d441e5fb3aed38368acbe8486b575d7018df38dbdfbc7311fbb2ef3a9',
          'vulnerable':'docker.io/library/alpine@sha256:c19173c5ada610a5989151111163d28a67368362762534d8a8121ce95cf2bd5a'}
run('trivy','image','--cache-dir',str(ROOT/'cache'),'--download-db-only')
for name,image in images.items():
    run('trivy','image','--cache-dir',str(ROOT/'cache'),'--image-src','remote','--platform',platform,
        '--format','cyclonedx','--scanners','vuln','--skip-db-update','--output',str(ROOT/(name+'.cdx.json')),image)
    (ROOT/(name+'.scan.json')).unlink(missing_ok=True)
inputs = ['clean.cdx.json','vulnerable.cdx.json','cache/db/trivy.db','cache/db/metadata.json']
state = {'images':images, 'platform':platform,
         'hashes':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in inputs}}
(Path(__file__).resolve().parents[1]/'starting-state.json').write_text(json.dumps(state))
print('Prepared two inventories and one database snapshot at ' + str(ROOT))
