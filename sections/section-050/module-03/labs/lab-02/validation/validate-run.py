"""Check the executed PipelineRun and its live TaskRuns and Deployment."""
import sys
try:
    import json,pathlib,sys
    work,image,expected,baseline=sys.argv[1:]
    root=pathlib.Path(work)
    run=json.loads((root/'run.json').read_text())
    tasks=json.loads((root/'tasks.json').read_text())['items']
    deployment=json.loads((root/'deployment.json').read_text())
    assert run['status']['conditions'][0]['status']=='True', 'PipelineRun did not succeed: '+str(run['status']['conditions'])
    def task(name):
        matches=[item for item in tasks if item['metadata']['labels'].get('tekton.dev/pipelineTask')==name]
        assert len(matches)==1, f'Expected one TaskRun for {name}'
        assert matches[0]['status']['conditions'][0]['status']=='True', f'{name} Task must succeed, even for findings'
        return matches[0]
    check=task('check')
    results={item['name']:item['value'] for item in check['status'].get('results',[])}
    assert results.get('outcome')==expected, f'Expected outcome={expected}, got {results}'
    actual=deployment['spec']['template']['spec']['containers'][0]['image']
    if expected=='pass':
        task('deploy')
        assert actual==image, 'Deploy did not use the scanned image'
    else:
        assert not any(item['metadata']['labels'].get('tekton.dev/pipelineTask')=='deploy' for item in tasks), 'Deploy created a TaskRun for a vulnerable release'
        skipped=next((item for item in run['status'].get('skippedTasks',[]) if item['name']=='deploy'),None)
        assert skipped and skipped.get('whenExpressions'), 'Deploy must be skipped by a when expression'
        assert actual==baseline, 'Blocked release changed the Deployment'
    # Check the executed Pipeline snapshot, not a student-created run or stale TaskRun.
    pipeline=run['status']['pipelineSpec']
    check_spec=next(item for item in pipeline['tasks'] if item['name']=='check')
    assert check_spec['taskRef']['name']=='scan-release-image', 'check must call scan-release-image'
    assert deployment['spec']['replicas']==0, 'Keep the fixture Deployment at zero replicas'
    deploy=next(item for item in pipeline['tasks'] if item['name']=='deploy')
    assert any(item['input']=='$(tasks.check.results.outcome)' and item['operator']=='in' and item['values']==['pass'] for item in deploy.get('when',[])), 'Deploy must gate on the check outcome'
except AssertionError as error:
    sys.exit(f"FAIL: vulnerability-gate: {error}")
