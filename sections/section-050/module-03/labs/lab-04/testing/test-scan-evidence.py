"""Exercise omissions, wrong identities and incorrect evidence counts."""
from pathlib import Path
import copy
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'validation'))
from check import compare


def report():
    first = {'VulnerabilityID':'CVE-test-1','PkgName':'package-a','InstalledVersion':'1.0',
             'FixedVersion':'1.1','Severity':'HIGH'}
    second = dict(first, PkgName='package-b', FixedVersion='')
    return {'ArtifactName':'vulnerable.cdx.json','ArtifactType':'cyclonedx',
            'Results':[{'Target':'Alpine','Vulnerabilities':[first,second]}]}


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.reference = report()
        self.answers = {'vulnerable-exit-code':'1','vulnerable-findings':'2'}

    def check(self, submitted, answers=None, status=1):
        compare(submitted,self.reference,answers or self.answers,'vulnerable',status)

    def test_complete_report(self):
        self.check(copy.deepcopy(self.reference))

    def test_removed_unfixed_finding(self):
        value=report()
        value['Results'][0]['Vulnerabilities'].pop()
        with self.assertRaises(AssertionError): self.check(value)

    def test_changed_package_version(self):
        value=report()
        value['Results'][0]['Vulnerabilities'][0]['InstalledVersion']='9.0'
        with self.assertRaises(AssertionError): self.check(value)

    def test_wrong_inventory(self):
        value=report()
        value['ArtifactName']='clean.cdx.json'
        with self.assertRaises(AssertionError): self.check(value)

    def test_duplicate_identifier_is_not_one_finding(self):
        with self.assertRaises(AssertionError):
            self.check(report(),dict(self.answers, **{'vulnerable-findings':'1'}))

    def test_forged_status_or_noninteger_count(self):
        for key,value in [('vulnerable-exit-code','0'),('vulnerable-findings','NaN'),('vulnerable-findings','2.0')]:
            with self.subTest(key=key,value=value), self.assertRaises(AssertionError):
                self.check(report(),dict(self.answers, **{key:value}))

    def test_reordered_findings(self):
        value=report()
        value['Results'][0]['Vulnerabilities'].reverse()
        self.check(value)

    def test_duplicate_findings(self):
        value=report()
        value['Results'][0]['Vulnerabilities'].append(copy.deepcopy(value['Results'][0]['Vulnerabilities'][0]))
        with self.assertRaises(AssertionError): self.check(value)

    def test_malformed_report(self):
        for value in [[], {'Results':{}}, {'Results':[None]}]:
            with self.subTest(value=value), self.assertRaises(AssertionError): self.check(value)

    def test_clean_control(self):
        clean={'ArtifactName':'clean.cdx.json','ArtifactType':'cyclonedx','Results':[]}
        compare(clean,clean,{'clean-exit-code':'0','clean-findings':'0'},'clean',0)


if __name__ == '__main__': unittest.main()
