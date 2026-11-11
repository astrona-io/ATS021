"""Probe the API without treating connection failures as policy denials."""
import json
import subprocess
import sys
import time
import uuid


def command(*args, obj=None):
    return subprocess.run(['kubectl', '--request-timeout=15s', *args],
                          input=json.dumps(obj) if obj is not None else None,
                          capture_output=True, text=True, timeout=30)


def get(*args):
    result = command('get', *args, '-o', 'json')
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return json.loads(result.stdout)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def allowed(*args, obj=None):
    result = command(*args, obj=obj)
    if result.returncode and any(error in result.stderr.lower() for error in
            ('connection refused', 'unable to connect', 'timeout', 'tls handshake', 'internalerror')):
        raise RuntimeError('API request failed: ' + result.stderr.strip())
    require(result.returncode == 0, 'allowed control failed: ' + result.stderr.strip())
    return result


def denied(*args, obj=None, reason='Forbidden'):
    result = command(*args, obj=obj)
    if result.returncode == 0:
        raise AssertionError('forbidden operation was accepted')
    if reason not in result.stderr or any(error in result.stderr.lower() for error in
            ('connection refused', 'unable to connect', 'timeout', 'tls handshake', 'internalerror')):
        raise RuntimeError('request failed without the expected denial: ' + result.stderr.strip())
    return result


def main(check):
    try:
        allowed('get', '--raw=/readyz')
        check()
        print('PASS: allowed controls, denied requests and task constraints hold')
    except AssertionError as error:
        print('FAIL: ' + str(error))
        sys.exit(1)
    except (RuntimeError, subprocess.SubprocessError, OSError, ValueError, KeyError) as error:
        print('ERROR: ' + str(error))
        sys.exit(2)
