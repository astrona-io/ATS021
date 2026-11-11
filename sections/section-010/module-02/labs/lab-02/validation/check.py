from probes import *

def check():
    labels = get('namespace','starfleet')['metadata']['labels']
    for mode,level in [('enforce','baseline'),('warn','restricted'),('audit','restricted')]:
        require(labels.get('pod-security.kubernetes.io/'+mode)==level, mode+' must use '+level)
        require(labels.get('pod-security.kubernetes.io/'+mode+'-version')=='v1.35', mode+' must pin v1.35')
    regular = allowed('create','--dry-run=server','-f','-',obj=pod('starfleet'))
    require('would violate PodSecurity' in regular.stderr and 'restricted:v1.35' in regular.stderr,
            'a baseline-only Pod must be admitted with a restricted warning')
    compliant = allowed('create','--dry-run=server','-f','-',obj=pod('starfleet',True))
    require('would violate PodSecurity' not in compliant.stderr, 'a restricted Pod must have no policy warning')
    unsafe = pod('starfleet')
    unsafe['spec']['containers'][0]['securityContext']={'privileged':True}
    denied('create','--dry-run=server','-f','-',obj=unsafe,reason='violates PodSecurity')
    outside = pod('outpost')
    outside['spec']['containers'][0]['securityContext']={'privileged':True}
    allowed('create','--dry-run=server','-f','-',obj=outside)
    for name in ('scout','probe','shuttle'):
        item = get('deployment',name,'-n','starfleet')
        require(item['spec']['replicas'] >= 1 and item.get('status',{}).get('availableReplicas',0) >= item['spec']['replicas'],
                name+' must retain available replicas')

if __name__ == '__main__':
    main(check)
