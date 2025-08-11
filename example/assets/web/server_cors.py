from http.server import HTTPServer, SimpleHTTPRequestHandler
import mimetypes
import os

# GLB MIME 타입 등록
mimetypes.add_type('model/gltf-binary', '.glb')

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def guess_type(self, path):
        # 확장자 기반 MIME 타입 강제
        base, ext = os.path.splitext(path)
        if ext == '.glb':
            return 'model/gltf-binary'
        return super().guess_type(path)

if __name__ == '__main__':
    print("Serving on port 8000...")
    HTTPServer(('', 8000), CORSRequestHandler).serve_forever()
