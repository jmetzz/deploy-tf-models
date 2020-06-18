import logging.config
import os

from flasgger import Swagger
from flask import Flask, render_template, request
from flask_bootstrap import Bootstrap

from .pets import inference

TF_SERVER_HOST = os.environ.get('TF_SERVER_HOST', '0.0.0.0')
TF_SERVER_PORT = os.environ.get('TF_SERVER_PORT', '8501')
TF_MODEL_NAME = os.environ.get('TF_MODEL_NAME', 'pets')

logger = logging.getLogger(__name__)


def initialize_app(flask_app):
    """Initialize Flask application
        :param flask_app: instance of Flask() class
    """

    swagger_config = {
        "headers": [
        ],
        "specs": [
            {
                "endpoint": 'apispec_1',
                "route": '/apispec_1.json',
                "rule_filter": lambda rule: True,
                "model_filter": lambda tag: True,
            }
        ],
        "static_url_path": "/flasgger_static",
        "swagger_ui": True,
        "specs_route": "/api/v1"
    }

    template = {
        "swagger": "2.0",
        "info": {
            "title": "My ML API",
            "description": "An API to offer the predict functionality of a ML model",
            "contact": {
                "responsibleOrganization": "MyOrganization",
                "responsibleDeveloper": "Me",
                "email": "me@me.com",
                "url": "www.me.com",
            },
            "termsOfService": "http://me.com/terms",
            "version": "0.0.1"
        }
    }

    swagger = Swagger(flask_app, template=template, config=swagger_config)

    @flask_app.route('/health', methods=['GET'])
    def health():
        return {'status': 'OK'}

    @flask_app.route('/api/v1/predict', methods=['POST'])
    def predict():
        """Endpoint used for serving the prediction function of the ML model

        Get a prediction

        ---
        responses:
          200:
            description: Prediction
            examples: {"prediction": true, "confidence": true}

        """
        uploaded_file = request.files['file']

        if uploaded_file.filename is '' or None:
            raise ValueError("Invalid argument")

        model_uri = f"http://{TF_SERVER_HOST}:{TF_SERVER_PORT}/v1/models/{TF_MODEL_NAME}:predict"
        image_path = os.path.join('webapp/static', uploaded_file.filename)
        uploaded_file.save(image_path)
        class_name, confidence = inference.get_pet_prediction(model_uri, image_path)
        return {'prediction': 'class_name', "confidence": confidence}

    @flask_app.route('/api/v1/ui/predict', methods=['GET', 'POST'])
    def index():
        """Endpoint used for serving the prediction function of the ML model from the web ui

        Get a prediction

        ---
        responses:
          200:
            description: Prediction
            examples: {"prediction": true, "confidence": true}

        """
        if request.method == 'GET':
            return render_template('index.html')

        uploaded_file = request.files['file']

        model_uri = f"http://{TF_SERVER_HOST}:{TF_SERVER_PORT}/v1/models/{TF_MODEL_NAME}:predict"
        if uploaded_file.filename is not '':
            image_path = os.path.join('webapp/static', uploaded_file.filename)
            uploaded_file.save(image_path)
            class_name, confidence = inference.get_pet_prediction(model_uri, image_path)

            result = {
                'class_name': class_name,
                'image_path': os.path.join('static', uploaded_file.filename),
                # 'image_path': image_path,
                'confidence': confidence
            }
        return render_template('show.html', result=result)


def init():
    flask_app = Flask(__name__)
    Bootstrap(flask_app)
    initialize_app(flask_app)
    return flask_app
