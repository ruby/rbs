#!/bin/sh

set -ex

if [ -z ${RUBY_COMMIT} ]; then
  RUBY_COMMIT=v`ruby -e 'puts RUBY_VERSION.gsub(".", "_")'`
fi

if [ -z ${RBS_RDOC_BASE_DIR} ]; then
  RBS_RDOC_BASE_DIR=/tmp/rbs-rdoc
fi

REPO_ROOT=$(cd $(dirname $(dirname $0)); pwd)

echo "RBS_RDOC_BASE_DIR = ${RBS_RDOC_BASE_DIR}"
echo "RUBY_COMMIT = ${RUBY_COMMIT}"

RUBY_SRC_DIR=${RBS_RDOC_BASE_DIR}/ruby-${RUBY_COMMIT}
RDOC_OUT_DIR=${RBS_RDOC_BASE_DIR}/rdoc-${RUBY_COMMIT}

rm -rf ${RUBY_SRC_DIR} ${RDOC_OUT_DIR}

(
  mkdir -p ${RUBY_SRC_DIR}
  cd ${RUBY_SRC_DIR}
  git init
  git remote add origin https://github.com/ruby/ruby.git
  git fetch --depth 1 origin ${RUBY_COMMIT}
  git checkout FETCH_HEAD
  bundle exec --gemfile=${REPO_ROOT}/Gemfile rdoc --output=${RDOC_OUT_DIR} --root="." --all --ri --page-dir="doc" "."
)

bundle exec rbs annotate --no-system --no-gems --no-site --no-home -d ${RDOC_OUT_DIR} core stdlib
