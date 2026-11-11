from pathlib import Path
from probes import *

NAMESPACES = ('navigation', 'telemetry', 'research')

def warnings():
    for namespace in NAMESPACES:
        labels = get('namespace', namespace)['metadata']['labels']
        require(labels.get('pod-security.kubernetes.io/warn') == 'baseline',
                namespace + ' must use warn=baseline')
        require('pod-security.kubernetes.io/enforce' not in labels,
                namespace + ' must remain without an enforce label')
        unsafe = pod(namespace)
        unsafe['spec']['containers'][0]['securityContext'] = {'privileged':True}
        result = allowed('create', '--dry-run=server', '-f', '-', obj=unsafe)
        require('would violate PodSecurity "baseline:' in result.stderr and 'privileged' in result.stderr,
                namespace + ' must warn about privileged Pods without rejecting them')
        result = allowed('create', '--dry-run=server', '-f', '-', obj=pod(namespace))
        require('would violate PodSecurity' not in result.stderr,
                namespace + ' must accept a baseline-compliant Pod without warning')

def finding():
    offenders = []
    flagged = []
    for namespace in NAMESPACES:
        result = allowed('label', '--dry-run=server', '--overwrite', 'namespace', namespace,
                         'pod-security.kubernetes.io/enforce=baseline',
                         'pod-security.kubernetes.io/enforce-version=v1.35')
        if 'violate the new PodSecurity enforce level' in result.stderr:
            offenders.append(namespace)
        labels = get('namespace', namespace)['metadata']['labels']
        if 'security-review' in labels:
            require(labels['security-review'] == 'required', 'use security-review=required for the finding')
            flagged.append(namespace)
    require(len(offenders) == 1, 'exactly one original namespace must contain a baseline violation')
    require(flagged == offenders, 'label only the namespace whose running Pod violates baseline')

def workloads():
    state = json.loads((Path(__file__).resolve().parents[1] / 'starting-state.json').read_text())
    for namespace in NAMESPACES:
        ns = get('namespace', namespace)
        require(ns['metadata']['uid'] == state[namespace]['namespace_uid'], 'do not recreate namespaces')
        items = get('pods', '-n', namespace)['items']
        require(len(items) == 1, namespace + ' must keep its single original Pod')
        item = items[0]
        require(item['metadata']['uid'] == state[namespace]['pod_uid'], 'do not replace Pods')
        require(item['spec'] == state[namespace]['spec'], 'do not change Pod specifications')
        require(item['status']['phase'] == 'Running' and any(
            c['type'] == 'Ready' and c['status'] == 'True' for c in item['status'].get('conditions', [])),
            namespace + '/scout must remain running and ready')

if __name__ == '__main__':
    main({'warnings':warnings, 'finding':finding, 'workloads':workloads}[sys.argv[1]])
