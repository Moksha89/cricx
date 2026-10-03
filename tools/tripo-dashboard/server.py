"""Local Tripo workbench. Credentials stay server-side; uses verified SDK v2 endpoints."""
import argparse
import json
import os
import re
import threading
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).parent
API = 'https://api.tripo3d.ai/v2/openapi'
PRESETS = {'preset:idle', 'preset:walk', 'preset:run', 'preset:jump', 'preset:turn'}
VERSIONS = {'P1-20260311', 'v3.1-20260211', 'v2.5-20250123'}
TASK_ID = re.compile(r'[a-zA-Z0-9_-]{1,100}\Z')

class Failure(Exception):
    def __init__(self, status, message):
        self.status, self.message = status, message


def request_api(method, path, payload=None):
    key = os.environ.get('TRIPO_API_KEY')
    if not key:
        raise Failure(503, 'Tripo API key is not configured on the server.')
    body = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(API + path, data=body, method=method,
        headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            result = json.load(response)
    except urllib.error.HTTPError as exc:
        message = {401: 'Tripo rejected the API key.', 403: 'Tripo denied this request.',
                   429: 'Tripo rate limit reached. No automatic retry was made.'}.get(exc.code,
                   'Tripo returned an error. Check account access and available credits.')
        raise Failure(502, message) from None
    except (urllib.error.URLError, TimeoutError, ValueError):
        raise Failure(502, 'Tripo connection failed. A submitted task may still exist; do not blindly retry.') from None
    if result.get('code', 0) != 0:
        raise Failure(502, 'Tripo did not accept the request. Check API account credits and feature access.')
    return result.get('data', result)


def task_payload(data):
    mode = data.get('operation')
    if mode == 'generate':
        prompt = data.get('prompt', '')
        version = data.get('model_version', 'P1-20260311')
        if not isinstance(prompt, str) or not 1 <= len(prompt.strip()) <= 4000:
            raise Failure(400, 'Enter a prompt of 1–4000 characters.')
        if version not in VERSIONS:
            raise Failure(400, 'Unsupported model version.')
        return {'type': 'text_to_model', 'prompt': prompt.strip(), 'model_version': version,
                'texture': True, 'pbr': True, 'quad': True}
    source = data.get('source_task', '')
    if not isinstance(source, str) or not TASK_ID.fullmatch(source):
        raise Failure(400, 'Enter a valid source task identifier.')
    if mode == 'rig':
        return {'type': 'animate_rig', 'original_model_task_id': source,
                'model_version': 'v2.0-20250506', 'rig_type': 'biped',
                'spec': 'mixamo', 'out_format': 'fbx'}
    if mode == 'animate':
        preset = data.get('preset')
        if preset not in PRESETS:
            raise Failure(400, 'Select a supported animation preset.')
        return {'type': 'animate_retarget', 'original_model_task_id': source,
                'animation': preset, 'out_format': 'fbx', 'bake_animation': True,
                'export_with_geometry': True, 'animate_in_place': False}
    raise Failure(400, 'Select a supported operation.')


class Handler(BaseHTTPRequestHandler):
    submissions = {}
    submission_lock = threading.Lock()

    def log_message(self, *args):
        pass  # Do not log account replies, prompts or signed download links.

    def reply(self, status, body, kind='application/json'):
        raw = json.dumps(body).encode() if kind == 'application/json' else body
        self.send_response(status)
        self.send_header('Content-Type', kind)
        self.send_header('Content-Length', str(len(raw)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Content-Security-Policy', "default-src 'self'; style-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'")
        self.end_headers()
        self.wfile.write(raw)

    def check_host(self):
        host = self.headers.get('Host', '')
        if host not in {f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}'}:
            raise Failure(403, 'This dashboard accepts local requests only.')
        return host

    def do_GET(self):
        try:
            self.check_host()
            if self.path == '/api/status':
                self.reply(200, {'key_configured': bool(os.environ.get('TRIPO_API_KEY')),
                                 'custom_bowling_api_verified': False})
            elif self.path == '/api/balance':
                self.reply(200, request_api('GET', '/user/balance'))
            elif self.path.startswith('/api/task/'):
                task = self.path.removeprefix('/api/task/')
                if not TASK_ID.fullmatch(task):
                    raise Failure(400, 'Invalid task identifier.')
                self.reply(200, request_api('GET', '/task/' + task))
            elif self.path in {'/', '/app.js', '/style.css'}:
                name = {'/': 'index.html', '/app.js': 'app.js', '/style.css': 'style.css'}[self.path]
                kind = {'/': 'text/html; charset=utf-8', '/app.js': 'text/javascript', '/style.css': 'text/css'}[self.path]
                self.reply(200, (ROOT / name).read_bytes(), kind)
            else:
                raise Failure(404, 'Not found.')
        except Failure as exc:
            self.reply(exc.status, {'error': exc.message})

    def do_POST(self):
        try:
            host = self.check_host()
            if self.headers.get('Origin') != 'http://' + host:
                raise Failure(403, 'Request must originate from this dashboard.')
            if self.path != '/api/task':
                raise Failure(404, 'Not found.')
            if self.headers.get('Content-Type') != 'application/json':
                raise Failure(415, 'JSON is required.')
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size <= 24000:
                raise Failure(413, 'Request too large or empty.')
            data = json.loads(self.rfile.read(size))
            if not isinstance(data, dict):
                raise Failure(400, 'Invalid request.')
            payload = task_payload(data)
            token = data.get('submission_id', '')
            if not isinstance(token, str) or not TASK_ID.fullmatch(token):
                raise Failure(400, 'Missing submission identifier.')
            with self.submission_lock:
                if token in self.submissions:
                    raise Failure(409, 'This submission was already attempted. Inspect its status before retrying.')
                if not os.environ.get('TRIPO_API_KEY'):
                    raise Failure(503, 'Tripo API key is not configured on the server.')
                self.submissions[token] = True
            self.reply(200, request_api('POST', '/task', payload))
        except (ValueError, TypeError):
            self.reply(400, {'error': 'Invalid JSON request.'})
        except Failure as exc:
            self.reply(exc.status, {'error': exc.message})


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    server = ThreadingHTTPServer(('127.0.0.1', args.port), Handler)
    print('Cricx asset workbench started. API credentials remain server-side.', flush=True)
    server.serve_forever()
