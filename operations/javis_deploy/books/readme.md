# JAVIS Books Structure
First ci_phase reads the yaml's from `main/` to generate the phases.

Any `+extend: <path>` commands are processed relative to `books/`.

## main/
The root books.

## javis_*/
Contains specific details for each section.

## actions/
Contains implementations of specific actions (parameterized and typically called by javis_*/ commands.
