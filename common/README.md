# Common

This directory contains files and utilities that are reusable in multiple images.

## sshd_entrypoint.sh

This entrypoint script starts an SSH daemon server. Moreover, it grants passwordless SSH permission for
the specified user through a supplied RSA public key. It also automatically sets the user and group ID of the
ssh login user to match the host user on Linux systems. 

To use the entrypoint script in your own image (based on Ubuntu 18.04 or 20.04),
you must first install some minimal SSH dependencies and create a new sshd configuration file as follows:

```dockerfile
RUN apt-get install -y \
    libssl-dev \        # required
    ssh \               # required
    iputils-ping \      # recommended
    rsync               # recommended

RUN ( \
echo 'LogLevel DEBUG2'; \
echo 'PubkeyAuthentication yes'; \
echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
) > /etc/ssh/sshd_config_development \
&& mkdir /run/sshd
```

Then, simply copy the script to the root folder `/sshd_entrypoint.sh` and give it executable permissions.
```dockerfile
WORKDIR /tmp
RUN git clone https://github.com/aica-technology/docker-images.git \
    && cp docker-images/common/sshd_entrypoint.sh /sshd_entrypoint.sh
RUN chmod 744 /sshd_entrypoint.sh
RUN sudo rm -rf /tmp/*
```

If your desired login user does not yet exist, you can create one with the desired permissions.
In the following example, a user `remote` is created with an empty password. In this way, login is only
possible using the RSA authentication.
```dockerfile
ENV NEW_USER=remote
RUN useradd -m ${NEW_USER} && yes | passwd ${NEW_USER} && usermod -s /bin/bash ${NEW_USER}
```

Provided that these lines have been added to your Dockerfile, the resulting image can be run as a server using
the `aica-docker server` tool, which invokes the entrypoint at the path `/sshd_entrypoint.sh` automatically.
Following the example, for an image tagged as `example-ssh-image` with the user `remote`,
the necessary command would be:
```shell
aica-docker server example-ssh-image --user remote
```

You can also invoke the server script and pass arguments without the `aica-docker` utility by setting
it as the CMD or ENTRYPOINT, either in the Dockerfile or in the run command.

```shell
docker run example-ssh-image /sshd_entrypoint.sh --k $PUBLIC_KEY --user $LOGIN_USER --uid $LOGIN_UID --gid $LOGIN_GID
```

The official recommendation is to use the `aica-docker server` method.
