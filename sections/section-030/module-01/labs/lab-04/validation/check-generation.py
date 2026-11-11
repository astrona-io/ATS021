from probes import *


def wait_for_policy(namespace, previous_uid=None):
    deadline = time.monotonic() + 60
    while True:
        result = command('-n', namespace, 'get', 'networkpolicy', 'default-deny',
                         '--ignore-not-found', '-o', 'json')
        if result.returncode:
            raise RuntimeError(result.stderr)
        if result.stdout.strip():
            value = json.loads(result.stdout)
            if value['metadata']['uid'] != previous_uid:
                return value
        if time.monotonic() >= deadline:
            raise AssertionError('Kyverno did not generate default-deny within 60 seconds')
        time.sleep(2)


def check_policy(value):
    spec = value['spec']
    require(spec.get('podSelector') == {}, 'default-deny must select every Pod')
    require(set(spec.get('policyTypes', [])) == {'Ingress', 'Egress'}, 'both policy types are required')
    require(not spec.get('ingress') and not spec.get('egress'), 'default-deny must have no allow rules')
    require(value['metadata'].get('labels', {}).get('app.kubernetes.io/managed-by') == 'kyverno',
            'Kyverno must generate the NetworkPolicy')


def check():
    namespace = 'grader-generate-' + uuid.uuid4().hex[:8]
    allowed('create', 'namespace', namespace)
    try:
        first = wait_for_policy(namespace)
        check_policy(first)
        allowed('-n', namespace, 'delete', 'networkpolicy', 'default-deny')
        check_policy(wait_for_policy(namespace, first['metadata']['uid']))
        for excluded in ('kube-system', 'kube-public', 'kube-node-lease', 'kyverno', 'local-path-storage'):
            policies = get('networkpolicies', '-n', excluded)['items']
            require(not any(p['metadata']['name'] == 'default-deny' for p in policies),
                    'default-deny must not be generated in ' + excluded)
    finally:
        allowed('delete', 'namespace', namespace, '--wait=false')


if __name__ == '__main__':
    main(check)
