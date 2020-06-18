import json
from typing import Tuple

import requests
import tensorflow as tf
import numpy as np


SIZE = 128
CLASSES = ['Cat', 'Dog']


def get_pet_prediction(model_uri: str, image_path: str) -> Tuple[str, float]:
    image = tf.keras.preprocessing.image.load_img(
        image_path,
        target_size=(SIZE, SIZE)
    )
    image = image_to_features(image)
    data = json.dumps({'instances': image.tolist()})
    response = requests.post(model_uri, data=data.encode('utf-8'))
    result = json.loads(response.text)
    prediction = float(np.squeeze(result['predictions']))
    class_name = CLASSES[int(prediction > 0.5)]
    return class_name, prediction


def image_to_features(image):
    """Converts an PIL image a numpy array
    :return:
        a numpy array representing the image
    """
    image = tf.keras.preprocessing.image.img_to_array(image)
    image = tf.keras.applications.mobilenet_v2.preprocess_input(image)
    image = np.expand_dims(image, axis=0)
    return image
