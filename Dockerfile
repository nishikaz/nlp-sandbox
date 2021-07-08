FROM python:3.8.9

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
ENV PYTHONIOENCODING "utf-8"
ENV PYTHONUNBUFFERED 1

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  cmake \
  make \
  curl \
  git \
  libffi-dev \
  cron \
  vim \
  wget \
  tree \
  fonts-takao-gothic

# Node.js v16
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install -y nodejs

# MeCab
WORKDIR /opt
RUN git clone https://github.com/taku910/mecab.git
WORKDIR /opt/mecab/mecab
RUN ./configure  --enable-utf8-only \
  && make \
  && make check \
  && make install \
  && ldconfig
WORKDIR /opt/mecab/mecab-ipadic
RUN ./configure --with-charset=utf8 \
  && make \
  && make install

# neolog-ipadic
WORKDIR /opt
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git
WORKDIR /opt/mecab-ipadic-neologd
RUN ./bin/install-mecab-ipadic-neologd -n -y

# CRF++
RUN wget -O /tmp/CRF++-0.58.tar.gz 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ' \
  && cd /tmp/ \
  && tar zxf CRF++-0.58.tar.gz \
  && cd CRF++-0.58 \
  && ./configure \
  && make \
  && make install

# CaboCha
RUN cd /tmp \
  && curl -c cabocha-0.69.tar.bz2 -s -L "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7SDd1Q1dUQkZQaUU" \
  | grep confirm | sed -e "s/^.*confirm=\(.*\)&amp;id=.*$/\1/" \
  | xargs -I{} curl -b  cabocha-0.69.tar.bz2 -L -o cabocha-0.69.tar.bz2 \
  "https://drive.google.com/uc?confirm={}&export=download&id=0B4y35FiV1wh7SDd1Q1dUQkZQaUU" \
  && tar jxf cabocha-0.69.tar.bz2 \
  && cd cabocha-0.69 \
  && export CPPFLAGS=-I/usr/local/include \
  && ./configure --with-mecab-config=`which mecab-config` --with-charset=utf8 \
  && make \
  && make install \
  && cd python \
  && python3 setup.py build \
  && python3 setup.py install \
  && cd / \
  && rm /tmp/cabocha-0.69.tar.bz2 \
  && rm -rf /tmp/cabocha-0.69 \
  && ldconfig

# Juman++
RUN wget -O /tmp/jumanpp-2.0.0-rc3.tar.xz 'https://github.com/ku-nlp/jumanpp/releases/download/v2.0.0-rc3/jumanpp-2.0.0-rc3.tar.xz' \
  && cd /tmp/ \
  && tar xf jumanpp-2.0.0-rc3.tar.xz \
  && cd jumanpp-2.0.0-rc3 \
  && mkdir build \
  && cd build \
  && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX='/usr/local' \
  && make install -j

# KNP
RUN wget -O /tmp/knp-4.20.tar.bz2 'https://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=https://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/knp-4.20.tar.bz2&name=knp-4.20.tar.bz2' \
  && cd /tmp/ \
  && tar jxvf knp-4.20.tar.bz2 \
  && cd knp-4.20 \
  && ./configure \
  && make \
  && make installl

# pip
COPY requirements.txt /home
WORKDIR /home
RUN python3 -m pip install pip --upgrade \
  && python3 -m pip install -r requirements.txt

# SpaCy
RUN python3 -m spacy download en_core_web_sm

# jupyterlab extension
RUN jupyter contrib nbextension install --user \
  && jupyter nbextensions_configurator enable --user \
  && jupyter labextension install @jupyterlab/toc @ryantam626/jupyterlab_code_formatter \
  && jupyter serverextension enable --py jupyterlab_code_formatter

# poetry
RUN curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python