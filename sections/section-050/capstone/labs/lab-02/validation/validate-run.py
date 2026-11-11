"""Check the executed PipelineRun and its live TaskRuns and Deployment."""
import sys
try:
    import json,pathlib,sys
    work,image,expected,baseline=sys.argv[1:]
    root=pathlib.Path(work)
    run=json.loads((root/'run.json').read_text())
    tasks=json.loads((root/'tasks.json').read_text())['items']
    deployment=json.loads((root/'deployment.json').read_text())
    assert run['status']['conditions'][0]['status']==('False' if expected=='error' else 'True'), 'Unexpected PipelineRun status: '+str(run['status']['conditions'])
    def task(name):
        matches=[item for item in tasks if item['metadata']['labels'].get('tekton.dev/pipelineTask')==name]
        assert len(matches)==1, f'Expected one TaskRun for {name}'
        assert matches[0]['status']['conditions'][0]['status']=='True', f'{name} Task must succeed, even for findings'
        return matches[0]
    report=task('report')
    report_params={item['name']:item['value'] for item in report['spec'].get('params',[])}
    actual=deployment['spec']['template']['spec']['containers'][0]['image']
    if expected=='error':
        check=next(item for item in tasks if item['metadata']['labels'].get('tekton.dev/pipelineTask')=='check')
        assert check['status']['conditions'][0]['status']=='False', 'Inventory error must fail check'
        assert not any(item['metadata']['labels'].get('tekton.dev/pipelineTask')=='deploy' for item in tasks), 'Inventory error must prevent deployment'
        assert actual==baseline, 'Inventory error changed the Deployment'
        assert report_params=={'pipeline-status':'Failed','check-status':'Failed'}, 'Finally must report failed execution'
        sys.exit(0)
    check=task('check')
    assert report_params.get('check-status')=='Succeeded', 'Report must receive the completed check status'
    assert report_params.get('pipeline-status')==('Succeeded' if expected=='pass' else 'Completed'), 'Report must receive the aggregate execution status'
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
    finally_report=next(item for item in pipeline.get('finally',[]) if item['name']=='report')
    assert finally_report['taskRef']['name']=='report-outcome', 'Use report-outcome in finally'
    assert not finally_report.get('when'), 'Report both clean and blocked releases'
    report_inputs={item['name']:item['value'] for item in finally_report.get('params',[])}
    assert report_inputs=={'pipeline-status':'$(tasks.status)','check-status':'$(tasks.check.status)'}, 'Pass execution status rather than scan verdict to finally'
    check_spec=next(item for item in pipeline['tasks'] if item['name']=='check')
    assert check_spec['taskRef']['name']=='scan-release-image', 'check must call scan-release-image'
    assert deployment['spec']['replicas']==0, 'Keep the fixture Deployment at zero replicas'
    deploy=next(item for item in pipeline['tasks'] if item['name']=='deploy')
    assert any(item['input']=='$(tasks.check.results.outcome)' and item['operator']=='in' and item['values']==['pass'] for item in deploy.get('when',[])), 'Deploy must gate on the check outcome'
except AssertionError as error:
    sys.exit(f"FAIL: vulnerability-gate: {error}")
