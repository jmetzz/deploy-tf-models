# deploy-tf-models
Show how to deploy tensorflow models using docker containers

The easiest and most straight-forward way of using TensorFlow Serving is with
Docker images.

Follow these steps:
- Export your custom Tensorflow model ([SavedModel](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/python/saved_model/README.md)).
Please refer to [Tensorflow documentation](https://www.tensorflow.org/guide/saved_model#save_and_restore_models) for detailed instructions on how to export SavedModels.
- Spin the Tensorflow Server docker container giving you model as parameter
- Make request to the serve endpoint
  - Alternatively, you can implement a web app to load user input, transform the input
  into the correct format, and send the request to the server.
 

## End-to-end execution

To start all the bits on end-to-end mode, just run:

```bash
docker-compose up
```

This command will spin up 2 docker containers:
- The Tensorflow server container
- The web application container

The access the web application via http://localhost:5001

You can also try things up via swagger web UI: http://localhost:5001/api/v1


## Developing

### Preparing the environment


- install local dependencies
    ```bash
    python3.7 -m pip install virtualenv
    python3.7 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    ```

- run app

    with default flask dev server
    ```bash
    source .venv/bin/activate
    python wsgi.py
    ```

- Testing via swagger api:

    http://0.0.0.0:5000/api/v1
    
- Testing via webapp

    http://0.0.0.0:5000/api/v1/pet/predict

### On docker

- build the docker image

    docker build --rm -t tf-client .

- run in a docker container

    docker run -p 5000:5000  tf-client


### The web application 


You don't need to run the web application inside a docker container while you are
developing/modifying it. For this scenario you can run the app in your local machine
as a normal python module.

```bash
python -m wsgi
```

Or from your preferred IDE, if you prefer to debug the code in a nicer interface.

After stated, the application can be tested via curl:

```bash
curl -X GET "http://0.0.0.0:5000/health"
```

To test the model, however, you need the Tensorflow server up and running, and serving you model.
Assuming it is running, you can test the prediction of the model by sending a request to your application endpoint,
giving the correct arguments. You can see the API specification in http://0.0.0.0:5000/api/v1 

The predict endpoint must transform the given input into the correct format to be used by your model. Therefore,
make sure you apply all the pre-processing steps used by your model before sending the request.


### The docker containers

### Tensorflow serving docker

TL;DR:

Assuming your are currently in the repo root directory:

Serving the demo models:

    docker run -t --rm -p 8501:8501 \
        -v "$(pwd)/resources/models/saved_model_half_plus_two_cpu:/models/half_plus_two" \
        -e MODEL_NAME=half_plus_two tensorflow/serving

Testing the model:
    
    curl -d '{"instances": [1.0, 2.0, 5.0]}' -X POST http://localhost:8501/v1/models/half_plus_two:predict

Or using the `pets` model:

    docker run -t --rm -p 8501:8501 \
        -v "$(pwd)/resources/models/pets/:/models/pets/1" \ 
        -e MODEL_NAME=pets tensorflow/serving





To serve a model you *must* point the source directory correctly. if your model is called `pets` and you have exported
the files into `$(pwd)/resources/models/pets/`, this directory should contain at least one sub-directory which represents
the version of the model you want to serve. For example:

````bash
└── resources
    └── models
        ├── pets
        │   └── 1
        │       ├── assets
        │       ├── saved_model.pb
        │       └── variables
        └── saved_model_half_plus_two_cpu
            └── 00000123
                ├── assets
                ├── saved_model.pb
                └── variables
````

Otherwise, you must map the `pets` directory contents into a version directory inside the docker container 
via `-v` option. For example, here I map the model files to a sub-directory version `1` which is created by the docker:

    -v "$(pwd)/resources/models/pets/:/models/pets/1"
    
        
        


> TODO: the content below this point is not ready yet.

    docker pull tensorflow/tensorflow                     # latest stable release
    docker pull tensorflow/tensorflow:devel-gpu           # nightly dev release w/ GPU support
    docker pull tensorflow/tensorflow:latest-gpu-jupyter  # latest release w/ GPU support and Jupyter


    docker run [-it] [--rm] [-p hostPort:containerPort] tensorflow/tensorflow[:tag] [command]

Examples using CPU-only images:

    docker run -it --rm tensorflow/tensorflow \
        python -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"
   
   
Start a Jupyter Notebook server using TensorFlow's nightly build with Python 3 support:

    docker run -it -p 8888:8888 tensorflow/tensorflow:nightly-py3-jupyter
            