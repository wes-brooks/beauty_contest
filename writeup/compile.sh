#! /bin/bash

lyx --export pdflatex Beauty_Contest.lyx
xelatex Beauty_Contest
bibtex Beauty_Contest
xelatex Beauty_Contest
