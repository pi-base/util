# Build Process

We're working towards managing this through `ansible`. You should be able to

    ansible-playbook install.yml

## Error Logs

The `.service` file defines log routing. Assuming they are going to syslog -

    tail -f /var/log/syslog | grep pibase

## Deploying the Server

Builds are automatically uploaded to S3 as part of the CI process

Deploy

    ansible-playbook server.yml

## Deploying the Viewer

Build

    yarn deploy

Deploy

    ansible-playbook viewer.yml

## Other useful commands

Service commands

    sudo systemctl (start|stop|restart|status) (pibase|nginx)

Reset bare repo branch

    git update-ref refs/heads/users/jamesdabbs d71e74370ea1d293197fdffd5f89c357ed45a273