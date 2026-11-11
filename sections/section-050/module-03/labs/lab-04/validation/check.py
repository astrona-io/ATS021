from pathlib import Path
import collections
import hashlib
import json
import os
import subprocess
import sys
import tempfile

ROOT = Path('/tmp/ats021-sbom-scan')

def require(condition, message):
    if not condition:
        raise AssertionError(message)


def findings(report):
    require(isinstance(report, dict), 'report must be a JSON object')
    require(isinstance(report.get('Results', []), list), 'Results must be a list')
    result = []
    for target in report.get('Results', []):
        require(isinstance(target, dict), 'each result must be an object')
        entries = target.get('Vulnerabilities') or []
        require(isinstance(entries, list), 'Vulnerabilities must be a list')
        for entry in entries:
            require(isinstance(entry, dict), 'each vulnerability must be an object')
            require(entry.get('Severity') in ('HIGH','CRITICAL'), 'report contains an unselected severity')
            result.append((target.get('Target'), entry['VulnerabilityID'], entry['PkgName'],
                           entry['InstalledVersion'], entry.get('FixedVersion',''), entry['Severity']))
    return collections.Counter(result)


def compare(submitted, expected, answers, name, status):
    require(isinstance(submitted, dict), 'report must be a JSON object')
    require(submitted.get('ArtifactName') == expected.get('ArtifactName') and
            submitted.get('ArtifactType') == expected.get('ArtifactType'), 'wrong inventory identity in '+name)
    actual_findings, expected_findings = findings(submitted), findings(expected)
    require(actual_findings == expected_findings, name+' findings differ from a fresh scan of the prepared inventory')
    count = sum(expected_findings.values())
    require(status == int(count > 0), 'scanner did not return the expected completed-scan status')
    require((count == 0) if name == 'clean' else (count > 0), 'prepared scanner control has an unexpected result')
    require(answers.get(name+'-exit-code') == str(status), name+' exit code is incorrect')
    require(answers.get(name+'-findings') == str(count), name+' findings count is incorrect')


def check():
    for name in ('clean','vulnerable'):
        require((ROOT/(name+'.scan.json')).is_file(), name + ' scan report is missing')
    state = json.loads((Path(__file__).resolve().parents[1]/'starting-state.json').read_text())
    for name, expected in state['hashes'].items():
        require(hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == expected,
                'prepared input was changed: ' + name)
    result = subprocess.run(['kubectl','--request-timeout=15s','-n','starfleet','get','configmap',
                             'scan-decisions','--ignore-not-found','-o','json'],capture_output=True,text=True,timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr)
    require(bool(result.stdout.strip()), 'scan-decisions ConfigMap is missing')
    answers = json.loads(result.stdout).get('data',{})
    with tempfile.TemporaryDirectory(prefix='ats021-scan-grader-') as work:
        for name in ('clean','vulnerable'):
            submitted = json.loads((ROOT/(name+'.scan.json')).read_text())
            reference = Path(work)/(name+'.json')
            env = {key:value for key,value in os.environ.items() if not key.startswith('TRIVY_')}
            result = subprocess.run(['trivy','sbom','--cache-dir',str(ROOT/'cache'),'--skip-db-update',
                                     '--severity','HIGH,CRITICAL','--ignorefile','/dev/null','--exit-code','1',
                                     '--format','json','--output',str(reference),str(ROOT/(name+'.cdx.json'))],
                                    cwd=work,env=env,capture_output=True,text=True,timeout=180)
            if result.returncode not in (0,1) or not reference.is_file():
                raise RuntimeError('independent scanner failed: '+result.stderr)
            expected = json.loads(reference.read_text())
            compare(submitted, expected, answers, name, result.returncode)


if __name__ == '__main__':
    try:
        check()
        print('PASS: both reports, exit codes and counts match independent scans')
    except (AssertionError, json.JSONDecodeError, KeyError, TypeError) as error:
        sys.exit('FAIL: '+str(error))
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        sys.exit('ERROR: '+str(error))
