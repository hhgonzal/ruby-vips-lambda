FROM lambci/lambda:build-ruby2.7

WORKDIR /build

ARG VIPS_VERSION=8.12.2

ENV WORKDIR="/build"
ENV INSTALLDIR="/opt"
ENV VIPS_VERSION=$VIPS_VERSION

# Install deps for libvips. Details: https://libvips.github.io/libvips/install.html
#
RUN yum install -y \
  gtk-doc \
  gobject-introspection \
  gobject-introspection-devel \
  poppler-glib \
  poppler-glib-devel \
  libexif-devel \
  libjpeg-turbo \
  libjpeg-turbo-devel \
#  libwebp-devel \
  libtiff-devel

# Clone repo and checkout version tag.
#
RUN git clone https://github.com/libvips/libvips.git && \
  cd libvips && \
  git checkout "v${VIPS_VERSION}" -b "v${VIPS_VERSION}" && \
  pwd && \
  ls -al

# Compile from source.
#
RUN cd ./libvips && \
  CC=clang CXX=clang++ \
  ./autogen.sh \
  --prefix=${INSTALLDIR} \
  --with-poppler-includes=/usr/include \
  --with-poppler-libraries=/usr/lib64 \
#  --with-jpeg-includes=/usr/include \
#  --with-jpeg-libraries=/usr/lib64 \
  --disable-static && \
  make install && \
  echo /opt/lib > /etc/ld.so.conf.d/libvips.conf && \
  echo /usr/lib64 > /etc/ld.so.conf.d/libvips.conf && \
  ldconfig

# Copy only needed so files to new share/lib.
#
RUN mkdir -p share/lib && \
  cp -a $INSTALLDIR/lib/libvips.so* $WORKDIR/share/lib/ && \
#  cp -a /usr/lib64/*.so* $WORKDIR/share/lib/  
  cp -a /usr/lib64/libpoppler*.so* $WORKDIR/share/lib/ && \ 
  cp -a /usr/lib64/libjpeg*.so* $WORKDIR/share/lib/ && \
#  cp -a /usr/lib64/libwebp*.so* $WORKDIR/share/lib/ && \
  cp -a /usr/lib64/libexif*.so* $WORKDIR/share/lib/ && \  
  cp -a /usr/lib64/libopenjpeg*.so* $WORKDIR/share/lib/


# Create sym links for ruby-ffi gem's `glib_libname` and `gobject_libname` to work.
RUN cd ./share/lib/ && \
  ln -s /usr/lib64/libglib-2.0.so.0 libglib-2.0.so && \
  ln -s /usr/lib64/libgobject-2.0.so.0 libgobject-2.0.so

# Zip up contents so final `lib` can be placed in /opt layer.
#
RUN cd ./share && \
  zip --symlinks -r libvips.zip .
