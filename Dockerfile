FROM ubuntu:18.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
RUN \
  apt install -y \
    curl \
    openssh-client \
    python3 \
    python3-pip \
    git \
    ansible && \
  pip3 install --upgrade pip && \
  pip3 install echome-cli 

RUN mkdir /ansible
RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN mkdir -p /ansible/playbooks
WORKDIR /ansible/playbooks
RUN git clone https://github.com/kubernetes-sigs/kubespray.git

COPY init.sh /ansible/playbooks/init.sh
COPY inventory.ini /ansible/playbooks/inventory.ini
COPY k8s-cluster.yml /ansible/playbooks/k8s-cluster.yml
RUN chmod +x /ansible/playbooks/init.sh

WORKDIR /ansible/playbooks/kubespray
RUN pip install -r requirements.txt

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib


#ENTRYPOINT ["ansible-playbook"]
CMD "/ansible/playbooks/init.sh"