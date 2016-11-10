FROM logstash:2.4
COPY logstash-input-cloudhub-0.1.0.gem /logstash-input-cloudhub.gem
RUN  logstash-plugin install /logstash-input-cloudhub.gem
