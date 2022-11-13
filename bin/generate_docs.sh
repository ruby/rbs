#!/bin/sh

set -ex

if [ -z ${RUBY_VERSION} ]; then
  RUBY_VERSION=`ruby -e 'puts RUBY_VERSION'`
fi

echo "RUBY_VERSION = ${RUBY_VERSION}"

REPO_ROOT=$(cd $(dirname $(dirname $0)); pwd)

rm -f /tmp/ruby.tar.gz
rm -rf /tmp/ruby-${RUBY_VERSION}

curl -L https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz | tar xzf - -C /tmp

rm -rf /tmp/rdoc-${RUBY_VERSION}

cd /tmp/ruby-${RUBY_VERSION}
bundle exec --gemfile=${REPO_ROOT}/Gemfile rdoc --output=/tmp/rdoc-${RUBY_VERSION} --root="." --all --ri --page-dir="doc" "."
cd ${REPO_ROOT}
bundle exec rbs annotate --no-system --no-gems --no-site --no-home -d /tmp/rdoc-${RUBY_VERSION} core stdlib
