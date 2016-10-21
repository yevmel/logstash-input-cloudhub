# logstash-input-cloudhub
plugin for logstash, which pulls logs from a application deployed to [Cloudhub](anypoint.mulesoft.com/cloudhub).

# try it out
`Dockerfile` and `docker-compose.yml` contains everything you need to try it out, assumed you already have docker-compose installed and a Docker instance running.

## build the plugin from source.
```
# gem can be used instead of jgem
jgem build logstash-input-cloudhub.gemspec
```

## setup a container with logstash 2.4 and install the plugin
```
docker-compose build
```

## run the container with logstash and the plugin.
```
export CLOUDHUB_DOMAIN=<application>
export CLOUDHUB_USERNAME=<username>
export CLOUDHUB_PASSWORD=<password> 
docker-compose up
```

# further information
[Cloudhub Enhanced Logging API 1.0.0](https://anypoint.mulesoft.com/apiplatform/anypoint-platform/#/portals/organizations/68ef9520-24e9-4cf2-b2f5-620025690913/apis/34348/versions/35742/pages/49591)