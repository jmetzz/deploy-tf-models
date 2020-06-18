import logging
import os

from webapp.app import init

SERVER_HOST = os.environ.get('FLASK_SERVER_HOST', '0.0.0.0')
SERVER_PORT = os.environ.get('FLASK_SERVER_PORT', '5000')
FLASK_DEBUG = os.environ.get('FLASK_DEBUG', False)

application = init()
logger = logging.getLogger(__name__)

if __name__ == '__main__':
    logger.info(f"serving at {SERVER_HOST}:{SERVER_PORT}")
    application.run(
        host=SERVER_HOST,
        port=int(SERVER_PORT),
        debug=FLASK_DEBUG,
        use_reloader=False,
        threaded=True
    )
