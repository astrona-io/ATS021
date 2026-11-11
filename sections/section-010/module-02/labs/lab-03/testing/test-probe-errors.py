"""Do not confuse API failures with intended policy decisions."""
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'validation'))
import probes


class ProbeTests(unittest.TestCase):
    def result(self, code, error):
        return patch.object(probes, 'command', return_value=subprocess.CompletedProcess([], code, '', error))

    def test_connection_failure_is_not_a_denial(self):
        with self.result(1, 'Unable to connect to the server: connection refused'):
            with self.assertRaises(RuntimeError): probes.denied('create')
            with self.assertRaises(RuntimeError): probes.allowed('create')

    def test_timeout_is_not_a_denial(self):
        with self.result(1, 'Error from server (InternalError): webhook timeout'):
            with self.assertRaises(RuntimeError): probes.denied('create')

    def test_unexpected_rejection_fails_allowed_control(self):
        with self.result(1, 'Error from server (Forbidden): violates PodSecurity'):
            with self.assertRaises(AssertionError): probes.allowed('create')

    def test_accepted_negative_control_fails(self):
        with self.result(0, ''):
            with self.assertRaises(AssertionError): probes.denied('create')

    def test_expected_policy_denial(self):
        with self.result(1, 'Error from server (Forbidden): violates PodSecurity'):
            probes.denied('create', reason='violates PodSecurity')


if __name__ == '__main__': unittest.main()
