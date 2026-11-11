from probes import *

def check():
    identity = '--as=system:serviceaccount:starfleet:scale-operator'
    allowed('-n','starfleet','scale','deployment','scout','--replicas=2','--dry-run=server',identity)
    denied('-n','starfleet','scale','deployment','probe','--replicas=2','--dry-run=server',identity)
    denied('-n','outpost','scale','deployment','drifter','--replicas=2','--dry-run=server',identity)
    denied('-n','starfleet','patch','deployment','scout','--type=merge',
           '-p','{"metadata":{"annotations":{"grader":"blocked"}}}','--dry-run=server',identity)
    denied('-n','starfleet','get','secrets',identity)
    for verb in ('create','delete','list'):
        result = command('auth','can-i',verb,'deployments.apps','-n','starfleet',identity)
        require(result.stdout.strip() == 'no', 'unexpected deployment permission: ' + verb)
    for name in ('scout','probe','shuttle'):
        value = get('deployment',name,'-n','starfleet')
        require(value['spec']['replicas'] >= 1, name + ' must keep running')

if __name__ == '__main__':
    main(check)
