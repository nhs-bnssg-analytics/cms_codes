Cambridge Multimorbidity Score codes
================

## Repository summary

This repository creates a spreadsheet containing the read codes and
medcodes, as well as the prodcodes and gemscript codes used to identify
conditions that count towards the Cambridge Multimorbidity Score (CMS)
for individuals.

The environment is controlled using the `renv` package, so if using this
repository begin by running `renv::restore()`.

The file `R/codelist.R` will download all of the code files for the 37
CMS conditions to a folder called “data”, and generate an xlsx file. The
file is saved in a folder called “outputs”. The file contains a cover
sheet, which explains the relationships between prescriptions and
diagnoses for each condition, and then a tab containing codes for the
diagnoses codes (medcodes) and prescription codes (prodcodes).
