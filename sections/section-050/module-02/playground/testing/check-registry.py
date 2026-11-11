import json,subprocess,sys,uuid

def check(ok,msg):
    if not ok:sys.exit('FAIL: '+msg)
def get(kind,name):
    result=subprocess.run(['kubectl','get',kind,name,'--ignore-not-found','-o','json'],text=True,capture_output=True)
    if result.returncode:raise RuntimeError(result.stderr)
    return json.loads(result.stdout) if result.stdout.strip() else None
template=get('constrainttemplate','k8sallowedregistries')
check(template is not None and template.get('status',{}).get('created') is True,'create the working registry template')
c=get('k8sallowedregistries','ghcr-only')
check(c is not None,'create ghcr-only')
check(c['spec'].get('enforcementAction')=='deny','use deny enforcement')
check(c['spec'].get('parameters',{}).get('registries')==['ghcr.io/'],'include the slash after the registry host')
match=c['spec'].get('match',{})
check(set(match.get('namespaces',[]))=={'starfleet','starfleet-prod'},'scope the policy to the two application namespaces')

def probe(namespace,images,allowed):
    pod={'apiVersion':'v1','kind':'Pod','metadata':{'name':'registry-control-'+uuid.uuid4().hex[:8],'namespace':namespace},'spec':{'containers':[{'name':f'app-{i}','image':image} for i,image in enumerate(images)]}}
    result=subprocess.run(['kubectl','create','--dry-run=server','-f','-','-o','name'],input=json.dumps(pod),text=True,capture_output=True)
    if allowed:
        check(result.returncode==0,f'allowed images in {namespace} must be admitted: {result.stderr}')
    else:
        check(result.returncode!=0 and '[ghcr-only]' in result.stderr and 'denied the request' in result.stderr,f'ghcr-only must reject {images} in {namespace}: {result.stdout} {result.stderr}')
for namespace in ('starfleet','starfleet-prod'):
    probe(namespace,['ghcr.io/stefanprodan/podinfo:6.15.0'],True)
    probe(namespace,['docker.io/library/nginx:latest'],False)
    probe(namespace,['ghcr.io.example.com/team/app:v1'],False)
    probe(namespace,['ghcr.io/stefanprodan/podinfo:6.15.0','docker.io/library/nginx:latest'],False)
probe('outpost',['docker.io/library/nginx:latest'],True)
print('PASS: allowed registry, rejected registry, lookalike host, second container and namespace controls')
