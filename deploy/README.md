# Build Process

We're working towards managing this through `ansible`. You should be able to

    ansible-playbook deploy/install.yml
    ansible-playbook deploy/server.yml --extra-vars '{ "server_version": ... }'

assuming your `~/.ansible.cnf` / `/etc/ansible/hosts` are configured with the pibase host and secret key. Refer to those playbooks for details.

## Error Logs

The `.service` file defines log routing. Assuming they are going to syslog - 

    tail -f /var/log/syslog | grep pi-base

## Deploying the Viewer

Build

    yarn build

Deploy

    cd build && scp -r . pibase:/app/viewer/

## Other useful commands

Service commands

    sudo systemctl (start|stop|restart|status) (pibase|nginx)

Reset bare repo branch

    git update-ref refs/heads/users/jamesdabbs d71e74370ea1d293197fdffd5f89c357ed45a273 

