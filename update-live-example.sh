#!/bin/bash

git fetch
git checkout gh-pages
git pull

git merge main -m "Merge main into gh-pages"

rm -rf .dart_tool
rm -rf www

dart pub get
dart pub global run webdev build -o web:www -r

git add www/*
git commit -m "Update live web example"
git push
rm -rf .dart_tool
rm -rf www
rm -rf doc
git checkout main
dart pub get