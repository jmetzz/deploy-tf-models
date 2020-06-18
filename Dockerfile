FROM gcr.io/google-appengine/python

LABEL maintainer="Jean Metz, jean.metz@gmail.com"
LABEL python_version=python3.7

RUN virtualenv --no-download /env -p python3.7

# Set virtualenv environment variables. This is equivalent to running
# source /env/bin/activate
ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

WORKDIR /app

EXPOSE 5000

RUN mkdir -p static
ADD webapp ./webapp

COPY wsgi.py .
COPY requirements.txt .

RUN pip install --upgrade pip
RUN pip install -U pip setuptools
RUN pip install -r requirements.txt

# check this out: https://hynek.me/articles/docker-signals/
#CMD exec python wsgi.py

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Run your program under Tini
CMD ["python", "-m", "wsgi"]


