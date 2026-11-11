import json,subprocess,sys,time,uuid
from pathlib import Path

def get(*args):return json.loads(subprocess.check_output(['kubectl',*args,'-o','json'],text=True))
def check(ok,msg):
    if not ok:sys.exit('FAIL: '+msg)
constraints=get('get','k8sdisallowedtags')['items']
candidates=[c for c in constraints if c['spec'].get('enforcementAction')=='dryrun' and c['spec'].get('match',{}).get('namespaces')==['outpost'] and c['spec'].get('parameters',{}).get('tags')==['latest']]
check(len(candidates)==1,'create one dryrun latest-tag constraint for outpost')
constraint=candidates[0]['metadata']['name']
original=json.loads((Path(__file__).resolve().parents[1]/'original-pods.json').read_text())['items']
check(len(original)==1,'expected one original drifter Pod')
pod=original[0];name=pod['metadata']['name']
live=get('-n','outpost','get','pod',name)
check(live['metadata']['uid']==pod['metadata']['uid'] and live['spec']['containers']==pod['spec']['containers'],'keep the original noncompliant Pod running')
check(any(c.get('type')=='Ready' and c.get('status')=='True' for c in live['status'].get('conditions',[])),'drifter must stay Ready')
for namespace,image in [('outpost','curlimages/curl:latest'),('outpost','curlimages/curl:8.22.0'),('starfleet','curlimages/curl:latest')]:
    p=subprocess.run(['kubectl','-n',namespace,'run','audit-control-'+uuid.uuid4().hex[:8],'--image='+image,'--dry-run=server','-o','name'],text=True,capture_output=True)
    check(p.returncode==0,'audit must not reject admission: '+p.stderr)
for attempt in range(36):
    status=get('get','k8sdisallowedtags',constraint).get('status',{})
    if any(v.get('kind')=='Pod' and v.get('namespace')=='outpost' and v.get('name')==name for v in status.get('violations',[])):
        check(bool(status.get('auditTimestamp')),'audit must have run')
        print('PASS: audit reports the original running Pod without blocking admission')
        break
    time.sleep(5)
else:sys.exit('FAIL: audit did not report the original drifter Pod within three minutes')
