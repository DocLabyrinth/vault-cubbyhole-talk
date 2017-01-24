#!/bin/bash -ex

# yes, really. ruby-install + others kept segfaulting for some reason (possibly low memory)
apt-get install -y ruby
gem install bundler

cd /home/ubuntu
su -c 'bundle install --path vendor/bundle' ubuntu
su -c 'nohup bundle exec ruby app.rb &' ubuntu
