FROM gentoo/stage3-amd64

MAINTAINER uuLaoba

RUN touch /etc/init.d/functions.sh && \
  echo 'PYTHON_TARGETS="${PYTHON_TARGETS} python2_7"' >> /etc/portage/make.conf && \
  echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf && \
  echo 'EMERGE_DEFAULT_OPTS="--ask=n --jobs=4"' >> /etc/portage/make.conf && \
  echo 'GENTOO_MIRRORS="http://mirrors.163.com/gentoo http://mirrors.xmu.edu.cn/gentoo"' >> /etc/portage/make.conf

RUN mkdir -p /etc/portage/repos.conf && \
  ( \ echo '[gentoo]'  && \
  echo 'location = /usr/portage' && \
  echo 'sync-type = rsync' && \
  echo 'sync-uri = rsync://rsync.cn.gentoo.org/gentoo-portage' && \
  echo 'auto-sync = yes' \ 
  )> /etc/portage/repos.conf/gentoo.conf

# Setup the rc_sys
RUN sed -e 's/#rc_sys=""/rc_sys="lxc"/g' -i /etc/rc.conf

# By default, UTC system 
RUN echo 'UTC' > /etc/timezone

# Setup the portage directory and permissions 
RUN mkdir -p /usr/portage/{distfiles,metadata,packages}
RUN chown -R portage:portage /usr/portage
RUN echo "masters = gentoo" > /usr/portage/metadata/layout.conf
# Sync portage 
RUN emerge-webrsync -q
# Display some news items 
RUN eselect news read new
# Finalization 
RUN env-update

RUN emerge crossdev

RUN mkdir -p /usr/local/portage-crossdev/{profiles,metadata} && \
  echo 'crossdev' > /usr/local/portage-crossdev/profiles/repo_name && \
  echo 'masters = gentoo' > /usr/local/portage-crossdev/metadata/layout.conf && \
  chown -R portage:portage /usr/local/portage-crossdev

RUN ( \
    echo "[crossdev]" && \
    echo "location = /usr/local/portage-crossdev" && \
    echo "priority = 10" && \
    echo "masters = gentoo" && \
    echo "auto-sync = no" \
  ) > /etc/portage/repos.conf/crossdev.conf

RUN crossdev -S -v -t aarch64-unknown-linux-gnu --genv 'USE="cxx multilib fortran -mudflap nls openmp -sanitize"'

RUN emerge distcc

RUN ( \
    echo "#!/bin/sh" && \
    echo "eval \"\`gcc-config -E\`\"" && \
    echo "exec distccd \"\$@\"" \
  ) > /usr/local/sbin/distccd-launcher && \
  chmod +x /usr/local/sbin/distccd-launcher
CMD ["/usr/local/sbin/distccd-launcher", "--allow", "0.0.0.0/0", "--user", "distcc", "--log-level", "notice", "--log-stderr", "--no-detach"]
EXPOSE 3632
