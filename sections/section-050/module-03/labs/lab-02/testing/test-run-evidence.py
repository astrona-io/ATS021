"""Regressions for missing work, wrong evidence and malformed grader input."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

VALIDATOR = Path(__file__).resolve().parents[1] / 'validation/validate-run.py'


def fixture():
    gate = {'input': '$(tasks.check.results.outcome)', 'operator': 'in', 'values': ['pass']}
    report_params = [{'name': 'pipeline-status', 'value': 'Succeeded'},
                     {'name': 'check-status', 'value': 'Succeeded'}]
    tasks = []
    for name in ['check', 'deploy', 'report']:
        tasks.append({'metadata': {'labels': {'tekton.dev/pipelineTask': name}},
                      'spec': {'params': report_params if name == 'report' else []},
                      'status': {'conditions': [{'status': 'True'}],
                                 'results': [{'name': 'outcome', 'value': 'pass'}]}})
    pipeline = {'tasks': [{'name': 'check', 'taskRef': {'name': 'scan-release-image'}},
                          {'name': 'deploy', 'when': [gate]}],
                'finally': [{'name': 'report', 'taskRef': {'name': 'report-outcome'},
                             'params': [{'name': 'pipeline-status', 'value': '$(tasks.status)'},
                                        {'name': 'check-status', 'value': '$(tasks.check.status)'}]}]}
    return {'run': {'status': {'conditions': [{'status': 'True'}], 'pipelineSpec': pipeline}},
            'tasks': {'items': tasks},
            'deployment': {'spec': {'replicas': 0, 'template': {'spec': {'containers': [{'image': 'candidate'}]}}}}}


class EvidenceTests(unittest.TestCase):
    def run_validator(self, data, malformed=False):
        with tempfile.TemporaryDirectory() as directory:
            for name, value in data.items():
                Path(directory, name + '.json').write_text(json.dumps(value))
            if malformed:
                Path(directory, 'tasks.json').write_text('{')
            return subprocess.run([sys.executable, str(VALIDATOR), directory, 'candidate', 'pass', 'baseline'],
                                  text=True, capture_output=True, timeout=10)

    def test_completed_release(self):
        result = self.run_validator(fixture())
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_or_wrong_evidence_is_a_rejection(self):
        original = fixture()
        missing = copy.deepcopy(original)
        missing['tasks']['items'] = []
        wrong_image = copy.deepcopy(original)
        wrong_image['deployment']['spec']['template']['spec']['containers'][0]['image'] = 'unscanned'
        wrong_outcome = copy.deepcopy(original)
        wrong_outcome['tasks']['items'][0]['status']['results'][0]['value'] = 'fail'
        bypass = copy.deepcopy(original)
        bypass['run']['status']['pipelineSpec']['tasks'][1]['when'] = []
        for name, data in [('missing task', missing), ('unscanned image', wrong_image),
                           ('wrong outcome', wrong_outcome), ('missing gate', bypass)]:
            with self.subTest(name=name):
                result = self.run_validator(data)
                self.assertEqual(result.returncode, 1)
                self.assertIn('FAIL: vulnerability-gate:', result.stderr)
                self.assertNotIn('Traceback', result.stderr)

    def test_malformed_input_remains_an_execution_error(self):
        result = self.run_validator(fixture(), malformed=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('JSONDecodeError', result.stderr)
        self.assertNotIn('FAIL:', result.stderr)


if __name__ == '__main__':
    unittest.main()
