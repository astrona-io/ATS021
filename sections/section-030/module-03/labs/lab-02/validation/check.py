from probes import *

def check():
    policy = get('validatingadmissionpolicy','workload-check')
    require(policy['spec'].get('failurePolicy')=='Fail','keep failurePolicy Fail')
    binding = get('validatingadmissionpolicybinding','workload-check')
    require(binding['spec']['policyName']=='workload-check' and binding['spec']['validationActions']==['Deny'],
            'keep the binding connected and enforcing')
    # Wait for policy compilation and the API server's admission cache.
    deadline = time.monotonic()+45
    while True:
        result = command('create','--dry-run=server','-f','-',obj=deployment('starfleet',5))
        if result.returncode==0:
            break
        if time.monotonic()>=deadline:
            raise AssertionError('a compliant Deployment was rejected: '+result.stderr)
        time.sleep(2)
    for replicas,team,message in [(6,'blue','replicas must not exceed five'),(1,None,'team must be nonempty'),(1,'','team must be nonempty')]:
        result = denied('create','--dry-run=server','-f','-',obj=deployment('starfleet',replicas,team),reason='workload-check')
        require(message in result.stderr and 'resulted in error' not in result.stderr,
                'use the intended validation message, not a CEL evaluation error')
    allowed('create','--dry-run=server','-f','-',obj=deployment('outpost',6,None))
    # Exercise UPDATE independently of CREATE without changing learner workloads.
    candidate = deployment('starfleet',1)
    allowed('create','-f','-',obj=candidate)
    try:
        name = candidate['metadata']['name']
        denied('-n','starfleet','patch','deployment',name,'--type=merge',
               '-p','{"spec":{"replicas":6}}','--dry-run=server',reason='workload-check')
        allowed('-n','starfleet','patch','deployment',name,'--type=merge',
                '-p','{"spec":{"replicas":2}}','--dry-run=server')
    finally:
        allowed('-n','starfleet','delete','deployment',candidate['metadata']['name'],'--wait=false')

if __name__ == '__main__':
    main(check)
