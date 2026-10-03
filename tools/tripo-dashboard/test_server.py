import http.client
import json
import os
import threading
import unittest
from unittest.mock import patch
import server

class DashboardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.http = server.ThreadingHTTPServer(('127.0.0.1',0),server.Handler)
        cls.thread = threading.Thread(target=cls.http.serve_forever,daemon=True)
        cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.http.shutdown();cls.http.server_close();cls.thread.join()
    def setUp(self):
        server.Handler.submissions.clear()
    def request(self,path,body=None,origin=True):
        c=http.client.HTTPConnection('127.0.0.1',self.http.server_port)
        headers={}
        if body is not None:
            headers['Content-Type']='application/json'
            if origin:headers['Origin']=f'http://127.0.0.1:{self.http.server_port}'
        c.request('POST' if body is not None else 'GET',path,json.dumps(body) if body is not None else None,headers)
        r=c.getresponse();raw=r.read();c.close()
        return r.status,json.loads(raw) if r.headers['Content-Type']=='application/json' else raw
    def task(self,**values):
        return dict(operation='generate',prompt='Bowler',model_version='P1-20260311',submission_id='one',**values)
    def test_missing_key_status_and_balance(self):
        with patch.dict(os.environ,{},clear=True):
            code,data=self.request('/api/status');self.assertEqual(code,200);self.assertFalse(data['key_configured'])
            code,data=self.request('/api/balance');self.assertEqual(code,503)
    def test_missing_key_does_not_submit(self):
        with patch.dict(os.environ,{},clear=True),patch('server.request_api') as upstream:
            self.assertEqual(self.request('/api/task',self.task())[0],503);upstream.assert_not_called()
    def test_foreign_origin_cannot_spend_credits(self):
        with patch('server.request_api') as upstream:
            self.assertEqual(self.request('/api/task',self.task(),origin=False)[0],403);upstream.assert_not_called()
    def test_duplicate_submission_calls_upstream_once(self):
        with patch.dict(os.environ,{'TRIPO_API_KEY':'test-only'}),patch('server.request_api',return_value={'task_id':'generated'}) as upstream:
            self.assertEqual(self.request('/api/task',self.task())[0],200)
            self.assertEqual(self.request('/api/task',self.task())[0],409)
            upstream.assert_called_once()
            self.assertEqual(upstream.call_args.args[2]['type'],'text_to_model')
    def test_failed_submission_not_automatically_repeated(self):
        with patch.dict(os.environ,{'TRIPO_API_KEY':'test-only'}),patch('server.request_api',side_effect=server.Failure(502,'Connection failed')) as upstream:
            self.assertEqual(self.request('/api/task',self.task())[0],502)
            self.assertEqual(self.request('/api/task',self.task())[0],409);upstream.assert_called_once()
    def test_rig_and_motion_payloads(self):
        rig=server.task_payload({'operation':'rig','source_task':'original'})
        self.assertEqual(rig['type'],'animate_rig');self.assertEqual(rig['out_format'],'fbx')
        animation=server.task_payload({'operation':'animate','source_task':'rig','preset':'preset:run'})
        self.assertEqual(animation['type'],'animate_retarget');self.assertTrue(animation['export_with_geometry'])
        with self.assertRaises(server.Failure):server.task_payload({'operation':'animate','source_task':'rig','preset':'bowling'})
    def test_task_lookup_reads_only(self):
        with patch('server.request_api',return_value={'status':'success','output':{}}) as upstream:
            self.assertEqual(self.request('/api/task/known-task')[0],200)
            upstream.assert_called_once_with('GET','/task/known-task')
    def test_static_ui_available(self):
        for path in ['/','/app.js','/style.css']:
            code,raw=self.request(path);self.assertEqual(code,200);self.assertTrue(raw)
    def test_key_not_in_browser_response(self):
        with patch.dict(os.environ,{'TRIPO_API_KEY':'private-test-key'}):
            _,data=self.request('/api/status');self.assertNotIn('private-test-key',json.dumps(data))

if __name__=='__main__':unittest.main()
