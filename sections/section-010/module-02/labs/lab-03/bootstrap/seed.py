from pathlib import Path
import json
import secrets
import subprocess

NAMESPACES = ('navigation', 'telemetry', 'research')

def kubectl(*args, obj=None):
    result = subprocess.run(['kubectl', '--request-timeout=180s', *args],
                            input=json.dumps(obj) if obj is not None else None,
                            capture_output=True, text=True, check=True, timeout=200)
    return result.stdout

bad = secrets.choice(NAMESPACES)
snapshot = {}
for namespace in NAMESPACES:
    kubectl('create', 'namespace', namespace)
    pod = {'apiVersion':'v1', 'kind':'Pod', 'metadata':{'name':'scout', 'namespace':namespace},
           'spec':{'containers':[{'name':'app', 'image':'curlimages/curl:8.22.0',
                                  'command':['sleep', 'infinity'],
                                  'securityContext':{'privileged':namespace == bad}}]}}
    kubectl('create', '-f', '-', obj=pod)
for namespace in NAMESPACES:
    kubectl('-n', namespace, 'wait', '--for=condition=Ready', 'pod/scout', '--timeout=180s')
    pod = json.loads(kubectl('-n', namespace, 'get', 'pod', 'scout', '-o', 'json'))
    ns = json.loads(kubectl('get', 'namespace', namespace, '-o', 'json'))
    snapshot[namespace] = {'namespace_uid':ns['metadata']['uid'],
                           'pod_uid':pod['metadata']['uid'], 'spec':pod['spec']}
# Record API-defaulted specs and UIDs so deleting and recreating a Pod cannot pass.
(Path(__file__).resolve().parents[1] / 'starting-state.json').write_text(json.dumps(snapshot))
print('Three application namespaces are ready; inspect the running Pods to find the violation.')
